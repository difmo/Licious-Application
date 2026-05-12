# PRI-19: Outreach Tracking Schema + Operator Runbook (Gmail Workflow)

Last updated: 2026-05-12
Owner: CTO 2
Related: PRI-16, PRI-17

## Scope
Define a production-ready outreach tracking schema and an operator runbook for Gmail workflow execution, incident handling, and reporting.

## Tracking Schema (PostgreSQL)

### 1) Core event log (append-only)
```sql
CREATE TABLE IF NOT EXISTS outreach_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id TEXT NOT NULL,
  campaign_id TEXT NOT NULL,
  email TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('sent', 'replied', 'bounced', 'opt_out', 'validation_error', 'send_error')),
  mode TEXT NOT NULL CHECK (mode IN ('live', 'dry_run')),
  provider TEXT NOT NULL DEFAULT 'gmail',
  provider_message_id TEXT,
  error_code TEXT,
  error_message TEXT,
  attempt_number INTEGER NOT NULL DEFAULT 1,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 2) Suppression state (current truth)
```sql
CREATE TABLE IF NOT EXISTS outreach_suppressions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id TEXT NOT NULL,
  email TEXT NOT NULL,
  reason TEXT NOT NULL CHECK (reason IN ('opt_out', 'bounce', 'manual_do_not_contact')),
  source_event_id UUID REFERENCES outreach_events(id),
  suppressed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);
```

### 3) Lead outreach rollup (fast eligibility checks)
```sql
CREATE TABLE IF NOT EXISTS lead_outreach_state (
  lead_id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  last_outreach_at TIMESTAMPTZ,
  last_status TEXT,
  outreach_count INTEGER NOT NULL DEFAULT 0,
  last_campaign_id TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 4) Indexes
```sql
CREATE INDEX IF NOT EXISTS idx_outreach_events_campaign_created
  ON outreach_events (campaign_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_outreach_events_lead_created
  ON outreach_events (lead_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_outreach_events_provider_msg
  ON outreach_events (provider, provider_message_id)
  WHERE provider_message_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_outreach_suppressions_active_unique
  ON outreach_suppressions (lead_id, email, reason)
  WHERE expires_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_outreach_suppressions_email
  ON outreach_suppressions (email, suppressed_at DESC);
```

### 5) Canonical write rules
- Every attempted send writes one `outreach_events` row.
- `dry_run` writes synthetic `sent` rows with `mode='dry_run'` and `provider_message_id=NULL`.
- Permanent send failures write `send_error` with `error_code` and `error_message`.
- Template/input validation failures write `validation_error`.
- Bounce/opt-out signals create both:
  - event row (`bounced` or `opt_out`)
  - suppression row in `outreach_suppressions`.
- `lead_outreach_state` is upserted from events as a denormalized read model.

### 6) Optional compatibility view (for existing analytics)
```sql
CREATE OR REPLACE VIEW outreach_events_analytics AS
SELECT
  campaign_id,
  status,
  mode,
  provider,
  COUNT(*) AS event_count,
  DATE_TRUNC('day', created_at) AS event_day
FROM outreach_events
GROUP BY 1,2,3,4,6;
```

## Operator Runbook (Gmail)

### Preconditions
- Gmail API credentials configured:
  - `GOOGLE_CLIENT_ID`
  - `GOOGLE_CLIENT_SECRET`
  - `GOOGLE_REFRESH_TOKEN`
  - `GOOGLE_SENDER_EMAIL`
- Guardrails set:
  - `OUTREACH_DAILY_SEND_CAP`
  - `OUTREACH_BATCH_SIZE`
  - `OUTREACH_RETRY_MAX_ATTEMPTS`
  - `OUTREACH_RETRY_BACKOFF_SEC`
  - `OUTREACH_COOLDOWN_DAYS`
- Segment freeze complete (single ICP slice per run).

### Standard Operator Flow
1. Run dry-run against candidate batch.
2. Validate no `validation_error` spike before live send.
3. Run live send.
4. Confirm event persistence and provider ids.
5. Process bounce/opt-out updates before next batch.

### Commands
```bash
# Dry run
python -m outreach.send_workflow \
  --campaign-id <campaign_id> \
  --template-id <template_id> \
  --batch-size ${OUTREACH_BATCH_SIZE:-20} \
  --dry-run

# Live run
python -m outreach.send_workflow \
  --campaign-id <campaign_id> \
  --template-id <template_id> \
  --batch-size ${OUTREACH_BATCH_SIZE:-20}
```

### SQL Verification Queries
```sql
-- 1) Latest event counts by status/mode
SELECT status, mode, COUNT(*)
FROM outreach_events
WHERE campaign_id = $1
GROUP BY status, mode
ORDER BY status, mode;

-- 2) Check live sends have provider message IDs
SELECT COUNT(*) AS missing_provider_ids
FROM outreach_events
WHERE campaign_id = $1
  AND status = 'sent'
  AND mode = 'live'
  AND provider_message_id IS NULL;

-- 3) Validate suppressions were applied for bounces/opt-outs
SELECT reason, COUNT(*)
FROM outreach_suppressions
WHERE suppressed_at >= NOW() - INTERVAL '7 days'
GROUP BY reason
ORDER BY reason;
```

### Stop Conditions
- Pause immediately if either condition is true:
  - Gmail warning/limit/security banner appears.
  - bounce rate > 5% in current batch.
- Record incident and switch to fallback in PRI-17.

### Incident Path
1. Halt sending.
2. Capture exact Gmail/provider error and sample event rows.
3. Mark affected leads with `send_error` or suppression as appropriate.
4. Resume only after cooldown/reset window and reduced batch size.

### Daily Closeout Artifact
- Persist summary per campaign:
  - sent count (live only)
  - reply count
  - bounce count
  - opt-out count
  - validation/send error count
- Recommend one next-day change (segment/copy/cadence/CTA).

## Smallest Verification Plan
1. Execute dry-run for 3 leads with one bad merge field record.
2. Confirm two `sent` (`dry_run`) + one `validation_error` rows.
3. Execute one live send in sandbox campaign.
4. Confirm `provider_message_id` persisted for the live send.
5. Insert a simulated `opt_out` event and verify suppression row exists.

## Handoff Notes
- Engineer implementation should include migration files for all objects above.
- Analytics consumers must filter `mode='live'` for outbound-volume reporting.

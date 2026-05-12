# PRI-16: Gmail Outreach Sending Workflow (Tracking + Dry Run)

## Scope
Build a reproducible Gmail-based outreach workflow for qualified leads with:
- controlled batch sending
- merge-field personalization and pre-send validation
- tracking writes for `sent`, `replied`, `bounced`, `opt_out`
- dry-run mode that performs full validation and logging without sending
- operator-facing runbook and config requirements

## Architecture

### Pipeline
1. Select eligible leads from source table (`qualified=true`, `opt_out=false`, `email_valid=true`).
2. Suppress leads already contacted inside cooldown window (`last_outreach_at`).
3. Resolve template + merge fields per lead.
4. Run pre-send validation:
   - required merge keys present
   - non-empty recipient and subject
   - send-cap allowance remaining
5. Execute in one of two modes:
   - `dry-run`: no Gmail call, but writes tracking rows as `sent` with `mode=dry_run` and `provider_message_id=NULL`
   - `live`: send via Gmail API and persist returned message id + timestamp
6. Persist event records to tracking table for each attempted lead.
7. Retry transient failures with bounded policy.

### Components
- `outreach/send_workflow.py`: orchestrator CLI entrypoint
- `outreach/gmail_client.py`: provider integration
- `outreach/template_engine.py`: merge-field rendering + validation
- `outreach/tracking_store.py`: status event writes/read helpers
- `outreach/eligibility.py`: suppression, cooldown, and batch filtering

## Data Model

### Table: `outreach_events`
- `id` UUID PK
- `lead_id` string/UUID
- `campaign_id` string
- `email` string
- `status` enum: `sent | replied | bounced | opt_out`
- `mode` enum: `live | dry_run`
- `provider` string (`gmail`)
- `provider_message_id` nullable string
- `error_code` nullable string
- `error_message` nullable text
- `attempt_number` int
- `created_at` timestamp
- `metadata` jsonb (merge field snapshot, template id, cap counters)

### Guardrail Config
- `OUTREACH_DAILY_SEND_CAP` (default 50)
- `OUTREACH_BATCH_SIZE` (default 20)
- `OUTREACH_RETRY_MAX_ATTEMPTS` (default 3)
- `OUTREACH_RETRY_BACKOFF_SEC` (default 30)
- `OUTREACH_COOLDOWN_DAYS` (default 14)

## Guardrails and Policies
- Daily cap: hard stop before provider call when cap reached.
- Retry policy:
  - retry only transient transport/provider failures (5xx, timeouts).
  - no retry for permanent failures (invalid recipient, policy errors).
- Bounce handling:
  - on bounce signal, write `bounced` and mark lead suppressed for future sends.
- Opt-out suppression:
  - pre-filter opt-out leads.
  - write `opt_out` event when suppression occurs due to explicit unsubscribe.

## CLI and Operator Path

### Command
```bash
python -m outreach.send_workflow \
  --campaign-id <campaign_id> \
  --template-id <template_id> \
  --batch-size ${OUTREACH_BATCH_SIZE:-20} \
  --dry-run
```

Live send:
```bash
python -m outreach.send_workflow \
  --campaign-id <campaign_id> \
  --template-id <template_id> \
  --batch-size ${OUTREACH_BATCH_SIZE:-20}
```

### Required Env
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_REFRESH_TOKEN`
- `GOOGLE_SENDER_EMAIL`
- tracking DB connection vars used by application

## Acceptance Criteria Mapping
- Reproducible workflow + docs: this spec + README/operator doc update.
- Dry-run validation + tracking: dry-run path writes tracking rows and enforces merge validation.
- Guardrails: cap/retry/bounce/opt-out rules enforced in eligibility + send pipeline.

## Verification (smallest meaningful)
1. Run dry-run for a seed batch of 3 leads with one malformed template row.
2. Confirm:
   - malformed lead is rejected with validation error record
   - valid leads create `sent` + `mode=dry_run` records
   - no Gmail provider call occurs in dry-run mode
3. Run one live send in sandbox campaign and verify `provider_message_id` persisted.

### Minimal Verification Command Sequence (PRI-18/PRI-22 acceptance)
```bash
# 1) Dry-run seed batch (must not call provider)
python -m outreach.send_workflow \
  --campaign-id seed-campaign \
  --limit 3 \
  --mode dry_run

# 2) Guardrail-focused tests
pytest -q tests/test_send_guardrails.py

# 3) Single live sandbox send
python -m outreach.send_workflow \
  --campaign-id sandbox-campaign \
  --limit 1 \
  --mode live
```

## Tradeoffs
- Gmail API direct integration chosen over SMTP for better message-id tracing and provider error semantics.
- Event-log model is append-only for auditability; it increases write volume but simplifies recovery and compliance review.
- Dry-run writes synthetic `sent` records with `mode=dry_run` to keep downstream analytics path consistent; dashboards must filter by mode.

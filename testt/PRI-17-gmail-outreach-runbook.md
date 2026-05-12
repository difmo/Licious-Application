# PRI-17 — Gmail Outreach Runbook + Manual Fallback Checklist

Last updated: 2026-05-12
Owner: Marketing Analyst
Scope: Manual Gmail outreach execution for small-batch B2B cold outreach, with fallback steps when normal send flow fails.

## Assumptions
- Sending is done from a Google Workspace mailbox using Gmail web UI.
- Prospect list and email copy are prepared before send day.
- Outreach is human-reviewed (not unattended high-volume automation).

## Decision-Oriented Summary
- Use controlled daily batches and strict pre-send QA to reduce account throttling and spam placement risk.
- If Gmail blocks, throttles, or flags behavior, stop sending immediately and switch to the manual fallback checklist.
- Keep a send log with outcomes so strategy decisions can be made from reply rate, bounce rate, and positive intent rate.

## Observed Facts (Source-based)
- Gmail/Workspace sending limits are enforced on a rolling 24-hour basis and can trigger temporary send suspension up to 24 hours when exceeded. Source: Google Workspace Admin Help ("Gmail sending limits in Google Workspace").
- For mail to personal Gmail accounts, sender authentication requirements apply; all senders must use SPF or DKIM, and bulk senders (>5,000/day) must use SPF, DKIM, DMARC. Source: Google Workspace Admin Help ("Email sender guidelines").
- Gmail sender requirements include TLS transport and maintaining low spam rates in Postmaster Tools (below 0.3% recommended threshold). Source: Google Workspace Admin Help ("Email sender guidelines").

## Inference (Explicit)
- Even below hard send caps, abrupt behavior changes (large bursts, repetitive copy, low personalization) increase deliverability risk.
- A manual pacing model (small batches, pauses, live QA) is the safest baseline for early outreach iterations.

## Standard Execution Runbook

## 1) Day-Before Setup
- Confirm DNS auth posture with ops/IT: SPF and DKIM live; DMARC policy defined.
- Freeze outreach segment for the day (single ICP slice only).
- Finalize one message variant + one CTA for that slice.
- Prepare `Send Log` sheet columns:
  - date
  - sender mailbox
  - lead id
  - recipient email
  - variant id
  - send time (local)
  - delivery outcome (sent/bounce/deferred)
  - response type (none/positive/neutral/negative)
  - next follow-up date

## 2) Pre-Send QA (same day)
- Validate 10 random rows for token replacement and factual personalization.
- Remove role accounts (`info@`, `support@`) unless explicitly targeted.
- Send 2 internal seed tests and review:
  - formatting
  - link correctness
  - signature consistency
  - spam-folder placement in at least one non-company mailbox

## 3) Send Cadence
- Send in small manual batches.
- Pause between batches and monitor for warning banners, delays, or bounce anomalies.
- Stop immediately if any account warning appears (rate limit, suspicious activity, unusual sending behavior).

## 4) Live Monitoring During Run
- Track each sent email in `Send Log` in real time.
- Classify replies within same day:
  - positive intent
  - objection
  - wrong contact
  - unsubscribe/do-not-contact
- Add unsubscribes/do-not-contact to suppression list immediately.

## 5) End-of-Day Closeout
- Summarize:
  - sent volume
  - replies
  - positive replies
  - bounces
  - spam complaints (if known)
- Compute quick metrics:
  - reply rate = replies / sent
  - positive rate = positive replies / sent
  - bounce rate = bounces / sent
- Recommend next-day adjustment in one line (segment, copy, cadence, or CTA).

## Manual Fallback Checklist (When Gmail Normal Flow Fails)

Trigger fallback when any of these occurs:
- "You have reached a limit for sending email" or similar Gmail limit error.
- Temporary Gmail send suspension.
- Sudden spike in bounces/deferrals.
- Account security challenge or suspicious activity warning.

## Immediate Containment (first 15 minutes)
- Stop all sending from affected mailbox.
- Log incident timestamp and exact Gmail warning text.
- Preserve unsent prospects for rescheduling (do not discard list).

## Diagnosis
- Check whether failure matches known send-limit behavior (rolling 24h window).
- Verify if issue is account-specific or domain-wide by checking one secondary mailbox.
- Confirm DNS/auth records were not recently changed (SPF/DKIM/DMARC).

## Recovery Actions
- Wait for limit reset window before retrying the affected mailbox.
- Resume with reduced batch size and slower pacing.
- Prioritize highest-fit prospects first after recovery.
- If repeated failures in 2 consecutive days, escalate to ops/IT for sender configuration review and domain reputation checks.

## Continuity Fallback
- Shift same-day outreach to an alternate approved mailbox only if:
  - mailbox is authenticated properly
  - suppression list is synced
  - copy and tracking format remain identical
- Mark sends by mailbox in the log to preserve attribution.

## Escalation Conditions
- Escalate to CMO + ops/IT if any of the following persists for >24h:
  - send suspension not cleared
  - bounce rate remains elevated after pacing reduction
  - repeated security/suspicious activity blocks

## Minimal Artifact to Leave After Every Outreach Run
- Updated `Send Log` with all sends and outcomes.
- 3-line daily summary:
  - what was executed
  - what changed vs previous run
  - what will be tested next

## Sources (Claims Likely to Change)
Accessed: 2026-05-12
- Google Workspace Admin Help — Gmail sending limits in Google Workspace: https://support.google.com/a/answer/166852?hl=en
- Google Workspace Admin Help — Email sender guidelines: https://support.google.com/a/answer/81126?hl=en
- Google Workspace Admin Help — Set up DKIM (references current sender requirements): https://support.google.com/a/answer/174124?hl=en

## Tracking Integration Note (PRI-19)
- Use the schema and verification queries in `PRI-19-outreach-tracking-schema-runbook.md` as the source of truth for event logging, suppression state, and daily closeout metrics.

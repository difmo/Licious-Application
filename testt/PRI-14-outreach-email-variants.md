# PRI-14 — Outreach Email Variants for Website-Development Leads

## Personalization Placeholder Map (CSV -> token)
- `first_name` -> `{{first_name}}`
- `company_name` -> `{{company_name}}`
- `industry` -> `{{industry}}`
- `role` -> `{{role}}`
- `website_url` -> `{{website_url}}`
- `observed_issue` -> `{{observed_issue}}` (e.g., slow mobile load, unclear CTA, outdated layout)
- `city` -> `{{city}}`
- `sender_name` -> `{{sender_name}}`
- `sender_company` -> `{{sender_company}}`
- `booking_link` -> `{{booking_link}}`
- `portfolio_link` -> `{{portfolio_link}}`

Use at least 3 personalized fields in each send: `{{first_name}}`, `{{company_name}}`, and one context field (`{{observed_issue}}` or `{{industry}}`).

## Variant 1: Short (Low-friction intro)
### Subject options
- Quick idea for {{company_name}}'s website
- {{first_name}}, small website improvement suggestion
- Noticed one conversion gap on {{website_url}}

### Body
Hi {{first_name}},

I was reviewing {{company_name}}'s site and noticed {{observed_issue}}. Small UX/content changes here usually improve inquiry rates without a full redesign.

If helpful, I can share a focused 3-point improvement plan for {{company_name}} based on your current site.

Best,  
{{sender_name}}  
{{sender_company}}

### CTA options
- Reply "audit" and I’ll send the 3-point plan.
- Open to a 15-minute review this week? {{booking_link}}
- I can send 2 before/after examples relevant to {{industry}}.

## Variant 2: Consultative (Insight-first)
### Subject options
- {{first_name}}, a UX observation for {{company_name}}
- Website UX note for your {{industry}} funnel
- Idea to improve qualified leads from {{website_url}}

### Body
Hi {{first_name}},

I work with teams in {{industry}} to improve website clarity and conversion paths. While checking {{website_url}}, I noticed {{observed_issue}}, which may be creating drop-off before contact.

A practical starting point is:
1. Tighten above-the-fold value messaging.
2. Simplify the primary CTA path.
3. Improve mobile scanability on key service pages.

If useful, I can map these directly to {{company_name}}'s current pages and send a concise recommendation note.

Regards,  
{{sender_name}}  
{{sender_company}} | {{portfolio_link}}

### CTA options
- Want me to send a page-by-page recommendation note?
- Should I draft a quick UX teardown for your top landing page?
- If easier, we can walk through it in 15 minutes: {{booking_link}}

## Variant 3: Offer-led (Concrete deliverable)
### Subject options
- Free homepage teardown for {{company_name}}
- {{first_name}}, can I send a conversion mockup idea?
- Offer: 1-page UX improvement brief for {{website_url}}

### Body
Hi {{first_name}},

I help businesses improve website performance through clearer UX and conversion-focused page structure.

For {{company_name}}, I can prepare a free 1-page homepage UX brief that includes:
- The top 3 friction points I see (including {{observed_issue}})
- Recommended copy/layout changes
- A prioritized action list your team can execute immediately

No obligation. If it’s not useful, no follow-up needed.

Best,  
{{sender_name}}  
{{sender_company}}

### CTA options
- Reply "brief" and I’ll send it this week.
- Share the best page to review first, and I’ll start there.
- Prefer to align live? Here’s my calendar: {{booking_link}}

## Segment-to-Variant Recommendation
- **Segment A: Founder/Owner at small local businesses (time-constrained, high skepticism)**
  - Recommended: **Variant 1 (Short)**
  - Why: minimal reading load, low-commitment CTA, faster reply probability.

- **Segment B: Marketing managers / growth roles at established SMBs**
  - Recommended: **Variant 2 (Consultative)**
  - Why: demonstrates strategic thinking and specific UX logic before asking for time.

- **Segment C: Leads that engaged previously or have obvious high-impact website issues**
  - Recommended: **Variant 3 (Offer-led)**
  - Why: clear tangible value and reduced perceived risk.

## UX Guardrails (Anti-spam + trust)
- Keep under ~130 words for short variant and ~170 words for others.
- Use one primary CTA per send; avoid multiple asks in final send version.
- Avoid hype words ("guaranteed", "best", "#1", "instant results").
- Keep personalization factual and observable; no invasive phrasing.
- Prefer plain text formatting for cold outreach deliverability.

## Suggested sequencing
1. Send Variant 1 to coldest leads.
2. Send Variant 2 to non-responders after 4-6 days with a new subject line.
3. Use Variant 3 for warmed leads or high-fit accounts.

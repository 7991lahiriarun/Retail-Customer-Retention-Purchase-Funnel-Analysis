# Retail-Customer-Retention-Purchase-Funnel-Analysis
A complete SQL portfolio project using fictional online retail activity. All data is synthetic, reproducible with seed 42, and unrelated to any employer or client.

# Project Link:

https://retention-funnel-lab-arunabha.finespark32.chatgpt.site

## Business problem
An online retailer wants to understand two questions:
1. After their first completed purchase, do customers return to buy in later months?
2. Where do browsing sessions drop out before a completed purchase?

Customer attributes: acquisition_channel. Session attributes: started_at, device. Events: product_view, add_to_cart, checkout, purchase with timestamps. Orders: timestamp, integer amount_cents and completed/cancelled status. Integer monetary units avoid floating-point storage errors; divide by 100 for INR.

Observation window: 2026-01-01 inclusive to 2026-07-01 exclusive. All timestamps use one consistent fictional business timezone. Production pipelines should normalize timestamps before month bucketing.

## Analysis 1 — Monthly purchase cohorts
**Cohort:** calendar month of a customer's first completed order in the available dataset. Assume January is the fictional business launch, so there is no earlier purchase history. With real truncated history, call this first observed purchase or load older orders.

**Retention at month N:** distinct cohort customers with a completed order in month N / original cohort customers × 100.

For Example: if a cohort contains 100 customers and 25 buy in the following calendar month, M1 retention is 25%. Two orders by the same customer still count as one active customer.

SQL walkthrough:
1. `purchases` excludes cancelled orders and assigns each order a calendar month.
2. `first_purchase` finds the earliest purchase month for each customer.
3. `sizes` counts the original cohort customers.
4. `activity` calculates calendar-month differences and counts distinct returning customers.
5. `offsets` creates month numbers 0–5. Crossing this with cohort sizes creates missing observed cells, which become 0%.
6. The final date filter excludes months that have not been fully observed. Those cells are unavailable, not zero.

M0 is always 100% by construction. Compare cohorts at equal age (for example M1 across January–May), not January M5 against June M0. Non-purchasing customers do not belong to a purchase cohort. A customer can skip M1 and return at M2.

Optional retention matrix: import `02_cohort.csv` into Excel or Power BI; rows = cohort_month, columns = month_number, values = retention_pct. Do not sum percentages across cohorts; use active customer totals / eligible cohort size totals for weighted aggregates.

## Analysis 2 — Ordered session funnel
Session → Product view → Add to cart → Checkout → Completed purchase.

- Unit of analysis is sessions, not unique customers. A customer may have multiple sessions.
- Each stage must occur after the preceding stage within the same session and before the observation cutoff.
- Each session counts at most once per stage, even when events repeat.
- Purchase requires a matching completed order at the event timestamp. Cancelled orders stop at checkout.
- Overall conversion = stage sessions / all entry sessions × 100.
- Step conversion = stage sessions / previous-stage sessions × 100.
- Drop-off = previous-stage sessions − current-stage sessions.
- First-stage step conversion/drop-off are undefined and returned as NULL.

The chained CTEs select the earliest qualifying event after each preceding step. Choosing the earliest valid prefix leaves the most opportunity for later steps, so repeated events do not prevent a valid sequence from being found.

This is a strict timestamp-ordered, session-bounded funnel without a separate 24-hour limit. Sessions are provided by the source, rather than inferred from inactivity. Equal timestamps are excluded: real event streams should use a sequence key for ties. Session device is fixed. Anonymous traffic, cross-device identity stitching, refunds, partial cancellations and multiple orders per session are outside this simplified model.

## Analysis 3 — Segment performance
Group by acquisition channel and device. Calculate purchasing sessions, purchase conversion, revenue and average order value for completed orders. These are commercial session metrics: they can differ from strict funnel completion when tracking is incomplete or out of order. Here the synthetic generator uses ordered paths.

Channel is a customer acquisition attribute; it is not session campaign attribution. Revenue is gross recorded order value, not profit, net revenue or lifetime value.

## Validation and limitations
The runner tests referential integrity, database integrity, cohort bounds, observable cohort count, funnel monotonicity and independent Python checks of the SQL outputs. Duplicate view events are deliberately included; cancelled purchase events also occur. These validate deduplication and order-status handling.

The simulated mobile purchase probability is deliberately lower than desktop. 


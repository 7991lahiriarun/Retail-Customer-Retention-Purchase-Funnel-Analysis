-- Strictly ordered steps within the SAME session; repeat events do not inflate counts.
-- Equal timestamps are excluded; production logs should add event sequence for ties.
WITH base AS (
 SELECT * FROM sessions WHERE started_at>='2026-01-01' AND started_at<'2026-07-01'
), views AS (
 SELECT b.*,MIN(e.event_at) AS view_at FROM base b
 LEFT JOIN events e ON e.session_id=b.session_id AND e.event_type='product_view'
 AND e.event_at<'2026-07-01' GROUP BY b.session_id
), carts AS (
 SELECT v.*,MIN(e.event_at) AS cart_at FROM views v
 LEFT JOIN events e ON e.session_id=v.session_id AND e.event_type='add_to_cart'
 AND e.event_at>v.view_at AND e.event_at<'2026-07-01' GROUP BY v.session_id
), checkouts AS (
 SELECT c.*,MIN(e.event_at) AS checkout_at FROM carts c
 LEFT JOIN events e ON e.session_id=c.session_id AND e.event_type='checkout'
 AND e.event_at>c.cart_at AND e.event_at<'2026-07-01' GROUP BY c.session_id
), purchases AS (
 SELECT c.*,MIN(e.event_at) AS purchase_at FROM checkouts c
 LEFT JOIN events e ON e.session_id=c.session_id AND e.event_type='purchase'
 AND e.event_at>c.checkout_at AND e.event_at<'2026-07-01'
 AND EXISTS(SELECT 1 FROM orders o WHERE o.session_id=c.session_id
 AND o.status='completed' AND o.ordered_at=e.event_at)
 GROUP BY c.session_id
), counts AS (
 SELECT 1 AS step,'Session' AS stage,COUNT(*) AS sessions FROM purchases
 UNION ALL SELECT 2,'Product view',COUNT(view_at) FROM purchases
 UNION ALL SELECT 3,'Add to cart',COUNT(cart_at) FROM purchases
 UNION ALL SELECT 4,'Checkout',COUNT(checkout_at) FROM purchases
 UNION ALL SELECT 5,'Completed purchase',COUNT(purchase_at) FROM purchases
), rates AS (
 SELECT *,LAG(sessions) OVER(ORDER BY step) AS previous_sessions,
 FIRST_VALUE(sessions) OVER(ORDER BY step) AS entry_sessions FROM counts
)
SELECT stage,sessions,ROUND(100.0*sessions/NULLIF(entry_sessions,0),2) AS overall_conversion_pct,
 ROUND(100.0*sessions/NULLIF(previous_sessions,0),2) AS step_conversion_pct,
 previous_sessions-sessions AS drop_off_sessions,
 ROUND(100.0*(previous_sessions-sessions)/NULLIF(previous_sessions,0),2) AS drop_off_pct
FROM rates ORDER BY step;

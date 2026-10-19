-- Purchase cohorts: completed orders only; observation ends July 1, 2026 exclusive.
-- Month 0 is the acquisition month, not a repeat-purchase retention metric.
WITH RECURSIVE offsets(n) AS (
 SELECT 0 UNION ALL SELECT n+1 FROM offsets WHERE n<5
), purchases AS (
 SELECT s.customer_id, date(o.ordered_at,'start of month') AS purchase_month
 FROM orders o JOIN sessions s USING(session_id)
 WHERE o.status='completed' AND o.ordered_at<'2026-07-01'
), first_purchase AS (
 SELECT customer_id, MIN(purchase_month) AS cohort_month FROM purchases GROUP BY customer_id
), sizes AS (
 SELECT cohort_month,COUNT(*) AS cohort_size FROM first_purchase GROUP BY cohort_month
), activity AS (
 SELECT f.cohort_month,
  (CAST(strftime('%Y',p.purchase_month) AS INTEGER)-CAST(strftime('%Y',f.cohort_month) AS INTEGER))*12
  +CAST(strftime('%m',p.purchase_month) AS INTEGER)-CAST(strftime('%m',f.cohort_month) AS INTEGER) AS month_number,
  COUNT(DISTINCT p.customer_id) AS active_customers
 FROM purchases p JOIN first_purchase f USING(customer_id) GROUP BY 1,2
)
SELECT z.cohort_month,x.n AS month_number,z.cohort_size,
 COALESCE(a.active_customers,0) AS active_customers,
 ROUND(100.0*COALESCE(a.active_customers,0)/z.cohort_size,2) AS retention_pct
FROM sizes z CROSS JOIN offsets x
LEFT JOIN activity a ON a.cohort_month=z.cohort_month AND a.month_number=x.n
-- Only fully observed calendar months. Future cells are absent, not zero.
WHERE date(z.cohort_month,'+'||x.n||' months')<'2026-07-01'
ORDER BY 1,2;

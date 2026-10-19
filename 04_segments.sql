-- Commercial session conversion, by device and acquisition channel.
-- Unlike strict funnel completion, this includes any completed order in the session.
SELECT c.acquisition_channel,s.device,COUNT(*) AS sessions,
 COUNT(o.order_id) AS purchasing_sessions,
 ROUND(100.0*COUNT(o.order_id)/COUNT(*),2) AS purchase_conversion_pct,
 ROUND(COALESCE(SUM(o.amount_cents),0)/100.0,2) AS revenue_inr,
 ROUND(AVG(o.amount_cents)/100.0,2) AS average_order_value_inr
FROM sessions s JOIN customers c USING(customer_id)
LEFT JOIN orders o ON o.session_id=s.session_id AND o.status='completed'
 AND o.ordered_at<'2026-07-01'
WHERE s.started_at>='2026-01-01' AND s.started_at<'2026-07-01'
GROUP BY 1,2 ORDER BY purchase_conversion_pct DESC;

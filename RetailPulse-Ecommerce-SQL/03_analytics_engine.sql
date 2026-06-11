-- ============================================================================
-- RetailPulse — Customer Revenue & Cohort Analytics Engine
-- 03_analytics_engine.sql | Business-Ready Analytics Layer
-- ============================================================================
--
-- STRUCTURE:
--   Part 1  →  Revenue Intelligence          (aggregation, date functions)
--   Part 2  →  Customer Segmentation         (CASE, CTEs, subqueries)
--   Part 3  →  Cohort & Retention Analysis   (window functions, self-joins)
--   Part 4  →  Product & Margin Analytics    (multi-table joins, ratios)
--   Part 5  →  Advanced Business Metrics     (running totals, percentiles, flags)
--   Part 6  →  Operational Views             (CREATE VIEW for reporting layer)
--
-- Each query includes:
--   • Business question it answers
--   • SQL skills it demonstrates
--   • Commentary on performance considerations
-- ============================================================================


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  PART 1: REVENUE INTELLIGENCE                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────────────────────────────────────────
-- Q1. Monthly Revenue Trend with MoM Growth Rate
-- Business Q: How is top-line revenue trending, and which months accelerated?
-- Skills:     DATE_TRUNC, aggregate + window function combo, LAG, ROUND
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    DATE_TRUNC('month', o.order_date)::DATE          AS revenue_month,
    COUNT(DISTINCT o.order_id)                        AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2)
                                                      AS gross_revenue,
    ROUND(
        (SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
         - LAG(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)))
               OVER (ORDER BY DATE_TRUNC('month', o.order_date))
        )
        / NULLIF(
            LAG(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)))
                OVER (ORDER BY DATE_TRUNC('month', o.order_date)),
            0
          ) * 100
    , 1)                                              AS mom_growth_pct
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY revenue_month;


-- ──────────────────────────────────────────────────────────────────────────
-- Q2. Year-over-Year Revenue Comparison by Quarter
-- Business Q: Are we growing YoY, and which quarters drive the most revenue?
-- Skills:     EXTRACT, conditional aggregation (FILTER), pivoting with CASE
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    EXTRACT(QUARTER FROM o.order_date)::INT AS quarter,

    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
          FILTER (WHERE EXTRACT(YEAR FROM o.order_date) = 2022), 2)  AS rev_2022,

    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
          FILTER (WHERE EXTRACT(YEAR FROM o.order_date) = 2023), 2)  AS rev_2023,

    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
          FILTER (WHERE EXTRACT(YEAR FROM o.order_date) = 2024), 2)  AS rev_2024,

    -- YoY growth 2023→2024
    ROUND(
        (SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
             FILTER (WHERE EXTRACT(YEAR FROM o.order_date) = 2024)
         - SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
               FILTER (WHERE EXTRACT(YEAR FROM o.order_date) = 2023)
        )
        / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
                     FILTER (WHERE EXTRACT(YEAR FROM o.order_date) = 2023), 0)
        * 100
    , 1) AS yoy_growth_pct
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY EXTRACT(QUARTER FROM o.order_date)
ORDER BY quarter;


-- ──────────────────────────────────────────────────────────────────────────
-- Q3. 3-Month Rolling Average Revenue
-- Business Q: What's the smoothed revenue trend removing seasonal noise?
-- Skills:     Window frame (ROWS BETWEEN), named CTE for readability
-- ──────────────────────────────────────────────────────────────────────────
WITH monthly_rev AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::DATE AS revenue_month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS gross_revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    revenue_month,
    ROUND(gross_revenue, 2)                                     AS monthly_revenue,
    ROUND(
        AVG(gross_revenue) OVER (
            ORDER BY revenue_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    )                                                           AS rolling_3mo_avg
FROM monthly_rev
ORDER BY revenue_month;


-- ──────────────────────────────────────────────────────────────────────────
-- Q4. Revenue by Acquisition Channel
-- Business Q: Which channels bring the highest-value customers?
-- Skills:     Multi-table JOIN, GROUP BY with business dimension
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id)   AS total_customers,
    COUNT(DISTINCT o.order_id)      AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2)
                                    AS total_revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
        / NULLIF(COUNT(DISTINCT c.customer_id), 0)
    , 2)                            AS revenue_per_customer
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.order_status = 'completed'
GROUP BY c.acquisition_channel
ORDER BY revenue_per_customer DESC;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  PART 2: CUSTOMER SEGMENTATION                                         ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────────────────────────────────────────
-- Q5. RFM Segmentation (Recency, Frequency, Monetary)
-- Business Q: Who are our best, at-risk, and dormant customers?
-- Skills:     Multiple CTEs chained, NTILE, CASE-based bucketing, CONCAT
-- Performance: Uses NTILE for quartile assignment — scales well on indexed data
-- ──────────────────────────────────────────────────────────────────────────
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        MAX(o.order_date)                   AS last_order_date,
        COUNT(DISTINCT o.order_id)          AS order_count,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS total_spend
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id   = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY c.customer_id, c.first_name, c.last_name
),
rfm_scores AS (
    SELECT
        customer_id,
        customer_name,
        last_order_date,
        order_count,
        ROUND(total_spend, 2)                   AS total_spend,
        ('2024-12-31'::DATE - last_order_date)  AS recency_days,
        NTILE(4) OVER (ORDER BY last_order_date DESC)  AS r_score,  -- 1 = most recent
        NTILE(4) OVER (ORDER BY order_count ASC)        AS f_score,  -- 4 = most frequent
        NTILE(4) OVER (ORDER BY total_spend ASC)        AS m_score   -- 4 = highest spend
    FROM customer_metrics
)
SELECT
    customer_id,
    customer_name,
    recency_days,
    order_count,
    total_spend,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 2                   THEN 'Loyal'
        WHEN r_score >= 3 AND f_score = 1                    THEN 'New Customer'
        WHEN r_score = 2  AND f_score >= 2                   THEN 'At Risk'
        WHEN r_score = 1  AND f_score >= 3                   THEN 'Cant Lose Them'
        WHEN r_score = 1  AND f_score <= 2                   THEN 'Hibernating'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM rfm_scores
ORDER BY rfm_total DESC;


-- ──────────────────────────────────────────────────────────────────────────
-- Q6. Customer Lifetime Value (CLV) — Simplified Historical
-- Business Q: What is each customer worth and what's the distribution?
-- Skills:     DATE_PART, GREATEST to avoid division by zero, percentile
-- ──────────────────────────────────────────────────────────────────────────
WITH clv_base AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name        AS customer_name,
        c.signup_date,
        COUNT(DISTINCT o.order_id)                  AS lifetime_orders,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS lifetime_revenue,
        GREATEST(
            DATE_PART('month', AGE('2024-12-31'::DATE, c.signup_date)), 1
        )                                           AS tenure_months
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id   = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.signup_date
)
SELECT
    customer_id,
    customer_name,
    lifetime_orders,
    ROUND(lifetime_revenue, 2)                              AS lifetime_revenue,
    tenure_months,
    ROUND(lifetime_revenue / tenure_months, 2)              AS monthly_clv,
    ROUND(lifetime_revenue / lifetime_orders, 2)            AS avg_order_value,
    PERCENT_RANK() OVER (ORDER BY lifetime_revenue) * 100   AS revenue_percentile
FROM clv_base
ORDER BY lifetime_revenue DESC
LIMIT 50;


-- ──────────────────────────────────────────────────────────────────────────
-- Q7. Churn Identification — Customers Inactive 90+ Days
-- Business Q: Who has stopped buying and when did we lose them?
-- Skills:     NOT EXISTS, date arithmetic, segmented counting
-- ──────────────────────────────────────────────────────────────────────────
WITH customer_last_order AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.acquisition_channel,
        MAX(o.order_date) AS last_order_date,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
                       AND o.order_status = 'completed'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.acquisition_channel
)
SELECT
    customer_id,
    customer_name,
    acquisition_channel,
    last_order_date,
    total_orders,
    ('2024-12-31'::DATE - last_order_date) AS days_since_last_order,
    CASE
        WHEN last_order_date IS NULL                           THEN 'Never Purchased'
        WHEN '2024-12-31'::DATE - last_order_date > 365       THEN 'Churned (1yr+)'
        WHEN '2024-12-31'::DATE - last_order_date > 180       THEN 'Churned (6mo+)'
        WHEN '2024-12-31'::DATE - last_order_date > 90        THEN 'At Risk (90d+)'
        ELSE 'Active'
    END AS churn_status
FROM customer_last_order
ORDER BY days_since_last_order DESC NULLS FIRST;


-- ──────────────────────────────────────────────────────────────────────────
-- Q8. Churn Summary by Acquisition Channel
-- Business Q: Which channels have the worst retention?
-- Skills:     CTE reuse, conditional COUNT, percentage calculation
-- ──────────────────────────────────────────────────────────────────────────
WITH customer_status AS (
    SELECT
        c.customer_id,
        c.acquisition_channel,
        CASE
            WHEN MAX(o.order_date) IS NULL                             THEN 'Never Purchased'
            WHEN '2024-12-31'::DATE - MAX(o.order_date) > 180         THEN 'Churned'
            WHEN '2024-12-31'::DATE - MAX(o.order_date) > 90          THEN 'At Risk'
            ELSE 'Active'
        END AS status
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
                       AND o.order_status = 'completed'
    GROUP BY c.customer_id, c.acquisition_channel
)
SELECT
    acquisition_channel,
    COUNT(*)                                                    AS total_customers,
    COUNT(*) FILTER (WHERE status = 'Active')                   AS active,
    COUNT(*) FILTER (WHERE status = 'At Risk')                  AS at_risk,
    COUNT(*) FILTER (WHERE status = 'Churned')                  AS churned,
    COUNT(*) FILTER (WHERE status = 'Never Purchased')          AS never_purchased,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'Churned')::NUMERIC
        / NULLIF(COUNT(*), 0) * 100
    , 1)                                                        AS churn_rate_pct
FROM customer_status
GROUP BY acquisition_channel
ORDER BY churn_rate_pct DESC;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  PART 3: COHORT & RETENTION ANALYSIS                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────────────────────────────────────────
-- Q9. Monthly Signup Cohort Retention Matrix
-- Business Q: What % of each signup cohort is still buying N months later?
-- Skills:     Self-join via CTE, DATE_TRUNC, pivot with conditional agg,
--             cohort math — this is the #1 most asked analytics interview query
-- ──────────────────────────────────────────────────────────────────────────
WITH cohort_base AS (
    SELECT
        c.customer_id,
        DATE_TRUNC('month', c.signup_date)::DATE          AS cohort_month,
        DATE_TRUNC('month', o.order_date)::DATE           AS order_month
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status = 'completed'
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_customers
    FROM cohort_base
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT
        cohort_month,
        (DATE_PART('year',  order_month) - DATE_PART('year',  cohort_month)) * 12
        + (DATE_PART('month', order_month) - DATE_PART('month', cohort_month))
        AS months_since_signup,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_base
    GROUP BY cohort_month, months_since_signup
)
SELECT
    ca.cohort_month,
    cs.cohort_customers,
    ca.months_since_signup,
    ca.active_customers,
    ROUND(
        ca.active_customers::NUMERIC / cs.cohort_customers * 100, 1
    ) AS retention_pct
FROM cohort_activity ca
JOIN cohort_size cs ON cs.cohort_month = ca.cohort_month
WHERE ca.months_since_signup BETWEEN 0 AND 12
ORDER BY ca.cohort_month, ca.months_since_signup;


-- ──────────────────────────────────────────────────────────────────────────
-- Q10. Quarterly Cohort Revenue Over Time
-- Business Q: Which signup cohorts generate the most revenue long-term?
-- Skills:     Revenue-based cohort, multiple aggregation layers
-- ──────────────────────────────────────────────────────────────────────────
WITH cohort_rev AS (
    SELECT
        DATE_TRUNC('quarter', c.signup_date)::DATE AS signup_quarter,
        DATE_TRUNC('quarter', o.order_date)::DATE  AS order_quarter,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS revenue
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id   = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY DATE_TRUNC('quarter', c.signup_date), DATE_TRUNC('quarter', o.order_date)
)
SELECT
    signup_quarter,
    order_quarter,
    ROUND(revenue, 2) AS cohort_revenue,
    ROUND(
        SUM(revenue) OVER (
            PARTITION BY signup_quarter ORDER BY order_quarter
        ), 2
    ) AS cumulative_cohort_revenue
FROM cohort_rev
ORDER BY signup_quarter, order_quarter;


-- ──────────────────────────────────────────────────────────────────────────
-- Q11. Repeat Purchase Rate — First vs Repeat Orders
-- Business Q: What % of customers come back after their first order?
-- Skills:     ROW_NUMBER to tag first order, conditional aggregation
-- ──────────────────────────────────────────────────────────────────────────
WITH numbered_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_seq
    FROM orders
    WHERE order_status = 'completed'
)
SELECT
    DATE_TRUNC('quarter', n1.order_date)::DATE AS first_order_quarter,
    COUNT(DISTINCT n1.customer_id)              AS new_customers,
    COUNT(DISTINCT n2.customer_id)              AS returned_customers,
    ROUND(
        COUNT(DISTINCT n2.customer_id)::NUMERIC
        / NULLIF(COUNT(DISTINCT n1.customer_id), 0) * 100
    , 1) AS repeat_purchase_rate_pct
FROM numbered_orders n1
LEFT JOIN numbered_orders n2
    ON  n2.customer_id = n1.customer_id
    AND n2.order_seq   = 2
WHERE n1.order_seq = 1
GROUP BY DATE_TRUNC('quarter', n1.order_date)
ORDER BY first_order_quarter;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  PART 4: PRODUCT & MARGIN ANALYTICS                                    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────────────────────────────────────────
-- Q12. Product Profitability Ranking
-- Business Q: Which products contribute most to gross profit?
-- Skills:     Multi-table JOIN (4 tables), calculated margin, RANK
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    p.product_name,
    cat.category_name,
    SUM(oi.quantity)                                                 AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2)
                                                                     AS gross_revenue,
    ROUND(SUM(oi.quantity * p.unit_cost), 2)                         AS total_cogs,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
        - SUM(oi.quantity * p.unit_cost)
    , 2)                                                             AS gross_profit,
    ROUND(
        (SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
         - SUM(oi.quantity * p.unit_cost))
        / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 0)
        * 100
    , 1)                                                             AS margin_pct,
    RANK() OVER (
        ORDER BY SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
                 - SUM(oi.quantity * p.unit_cost) DESC
    )                                                                AS profit_rank
FROM order_items oi
JOIN products p    ON p.product_id   = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
JOIN orders o      ON o.order_id     = oi.order_id
WHERE o.order_status = 'completed'
GROUP BY p.product_name, cat.category_name
ORDER BY gross_profit DESC;


-- ──────────────────────────────────────────────────────────────────────────
-- Q13. Category Margin vs Target (actual vs plan)
-- Business Q: Which categories are hitting their margin target?
-- Skills:     Comparison to benchmark, CASE flagging
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    cat.category_name,
    cat.margin_target * 100                                        AS target_margin_pct,
    ROUND(
        (SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
         - SUM(oi.quantity * p.unit_cost))
        / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 0)
        * 100
    , 1)                                                           AS actual_margin_pct,
    CASE
        WHEN (SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
              - SUM(oi.quantity * p.unit_cost))
             / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 0)
             >= cat.margin_target
        THEN 'On Target'
        ELSE 'Below Target'
    END AS margin_status
FROM order_items oi
JOIN products p     ON p.product_id    = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
JOIN orders o       ON o.order_id      = oi.order_id
WHERE o.order_status = 'completed'
GROUP BY cat.category_name, cat.margin_target
ORDER BY actual_margin_pct DESC;


-- ──────────────────────────────────────────────────────────────────────────
-- Q14. Product Return Rate with Revenue Impact
-- Business Q: Which products are returned most and how much does it cost us?
-- Skills:     LEFT JOIN to include non-returned items, ratio calculation
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    p.product_name,
    cat.category_name,
    COUNT(DISTINCT oi.order_item_id)                                AS items_sold,
    COUNT(DISTINCT r.return_id)                                     AS items_returned,
    ROUND(
        COUNT(DISTINCT r.return_id)::NUMERIC
        / NULLIF(COUNT(DISTINCT oi.order_item_id), 0) * 100
    , 1)                                                            AS return_rate_pct,
    COALESCE(ROUND(SUM(r.refund_amount), 2), 0)                    AS total_refunds,
    ROUND(AVG(pr.rating), 2)                                       AS avg_rating
FROM order_items oi
JOIN products p     ON p.product_id    = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
JOIN orders o       ON o.order_id      = oi.order_id
LEFT JOIN returns r ON r.order_item_id = oi.order_item_id
LEFT JOIN product_reviews pr ON pr.product_id = p.product_id
WHERE o.order_status = 'completed'
GROUP BY p.product_name, cat.category_name
HAVING COUNT(DISTINCT oi.order_item_id) >= 50   -- meaningful sample only
ORDER BY return_rate_pct DESC;


-- ──────────────────────────────────────────────────────────────────────────
-- Q15. Top Product Pairs (Market Basket Analysis — Simplified)
-- Business Q: Which products are most frequently bought together?
-- Skills:     Self-join on order_items, deduplication, frequency counting
-- Performance note: Self-join can be expensive — WHERE clause limits scope
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(*)        AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 ON oi2.order_id   = oi1.order_id
                     AND oi2.product_id > oi1.product_id   -- deduplicate pairs
JOIN products p1     ON p1.product_id  = oi1.product_id
JOIN products p2     ON p2.product_id  = oi2.product_id
JOIN orders o        ON o.order_id     = oi1.order_id
WHERE o.order_status = 'completed'
GROUP BY p1.product_name, p2.product_name
HAVING COUNT(*) >= 10
ORDER BY times_bought_together DESC
LIMIT 25;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  PART 5: ADVANCED BUSINESS METRICS                                     ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ──────────────────────────────────────────────────────────────────────────
-- Q16. Running Total Revenue + Cumulative Customer Count
-- Business Q: How do revenue and customer base accumulate over time?
-- Skills:     Window SUM with ORDER BY (running total), COUNT DISTINCT trick
-- ──────────────────────────────────────────────────────────────────────────
WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::DATE AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS monthly_revenue,
        COUNT(DISTINCT o.customer_id) AS monthly_active_customers
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month,
    ROUND(monthly_revenue, 2)       AS monthly_revenue,
    monthly_active_customers,
    ROUND(
        SUM(monthly_revenue) OVER (ORDER BY month), 2
    )                               AS cumulative_revenue,
    SUM(monthly_active_customers) OVER (ORDER BY month) AS cumulative_active_customers
FROM monthly_metrics
ORDER BY month;


-- ──────────────────────────────────────────────────────────────────────────
-- Q17. Average Order Value Percentiles & Distribution
-- Business Q: What does our AOV distribution look like? Where are outliers?
-- Skills:     PERCENTILE_CONT (ordered-set aggregate), bucketing
-- ──────────────────────────────────────────────────────────────────────────
WITH order_totals AS (
    SELECT
        o.order_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS order_total
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
    GROUP BY o.order_id
)
SELECT
    COUNT(*)                                                        AS total_orders,
    ROUND(AVG(order_total), 2)                                      AS avg_order_value,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY order_total), 2) AS p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY order_total), 2) AS median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY order_total), 2) AS p75,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY order_total), 2) AS p90,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY order_total), 2) AS p99,
    ROUND(MIN(order_total), 2)                                      AS min_order,
    ROUND(MAX(order_total), 2)                                      AS max_order
FROM order_totals;


-- ──────────────────────────────────────────────────────────────────────────
-- Q18. Days Between Orders — Purchase Frequency Analysis
-- Business Q: How often do repeat customers come back?
-- Skills:     LAG for inter-event timing, EXTRACT, distribution analysis
-- ──────────────────────────────────────────────────────────────────────────
WITH order_gaps AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
            AS prev_order_date,
        order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
            AS days_between_orders
    FROM orders
    WHERE order_status = 'completed'
)
SELECT
    CASE
        WHEN days_between_orders <= 7   THEN '0-7 days'
        WHEN days_between_orders <= 30  THEN '8-30 days'
        WHEN days_between_orders <= 60  THEN '31-60 days'
        WHEN days_between_orders <= 90  THEN '61-90 days'
        WHEN days_between_orders <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END AS gap_bucket,
    COUNT(*) AS order_count,
    ROUND(AVG(days_between_orders), 1) AS avg_gap_days
FROM order_gaps
WHERE days_between_orders IS NOT NULL
GROUP BY
    CASE
        WHEN days_between_orders <= 7   THEN '0-7 days'
        WHEN days_between_orders <= 30  THEN '8-30 days'
        WHEN days_between_orders <= 60  THEN '31-60 days'
        WHEN days_between_orders <= 90  THEN '61-90 days'
        WHEN days_between_orders <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END
ORDER BY MIN(days_between_orders);


-- ──────────────────────────────────────────────────────────────────────────
-- Q19. Shipping Performance Scorecard by Carrier
-- Business Q: Which carriers deliver fastest and at what cost?
-- Skills:     Date subtraction, conditional flagging, multiple metrics
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    s.carrier,
    COUNT(*)                                                      AS shipments,
    ROUND(AVG(s.delivered_date - s.shipped_date), 1)              AS avg_delivery_days,
    ROUND(AVG(s.shipping_cost), 2)                                AS avg_shipping_cost,
    ROUND(
        COUNT(*) FILTER (WHERE s.delivered_date - s.shipped_date <= 3)::NUMERIC
        / COUNT(*) * 100
    , 1)                                                          AS pct_delivered_within_3d,
    ROUND(
        COUNT(*) FILTER (WHERE s.delivered_date - s.shipped_date > 7)::NUMERIC
        / COUNT(*) * 100
    , 1)                                                          AS pct_late_over_7d
FROM shipping s
GROUP BY s.carrier
ORDER BY avg_delivery_days;


-- ──────────────────────────────────────────────────────────────────────────
-- Q20. Payment Method Revenue Share — Trending Over Time
-- Business Q: How is our payment mix shifting? Is Apple Pay growing?
-- Skills:     Pivot-style conditional aggregation, trend analysis
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    DATE_TRUNC('quarter', p.payment_date)::DATE AS quarter,
    ROUND(SUM(amount) FILTER (WHERE payment_method = 'credit_card'), 2)  AS credit_card,
    ROUND(SUM(amount) FILTER (WHERE payment_method = 'debit_card'), 2)   AS debit_card,
    ROUND(SUM(amount) FILTER (WHERE payment_method = 'paypal'), 2)       AS paypal,
    ROUND(SUM(amount) FILTER (WHERE payment_method = 'apple_pay'), 2)    AS apple_pay,
    ROUND(SUM(amount) FILTER (WHERE payment_method = 'gift_card'), 2)    AS gift_card,
    ROUND(SUM(amount), 2) AS total
FROM payments p
GROUP BY DATE_TRUNC('quarter', p.payment_date)
ORDER BY quarter;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  PART 6: REPORTING VIEWS (Production-Ready Analytics Layer)            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- These views simulate what you'd build for a BI tool like Tableau/Looker.
-- Hiring managers love seeing that you think about the consumption layer.

-- ──────────────────────────────────────────────────────────────────────────
-- V1. Executive Revenue Dashboard View
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_executive_dashboard AS
SELECT
    DATE_TRUNC('month', o.order_date)::DATE     AS month,
    COUNT(DISTINCT o.order_id)                   AS orders,
    COUNT(DISTINCT o.customer_id)                AS active_customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2)
                                                 AS gross_revenue,
    ROUND(AVG(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2)
                                                 AS avg_item_value,
    ROUND(SUM(COALESCE(r.refund_amount, 0)), 2)  AS total_refunds,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct))
        - SUM(COALESCE(r.refund_amount, 0))
    , 2)                                         AS net_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN returns r ON r.order_item_id = oi.order_item_id
WHERE o.order_status = 'completed'
GROUP BY DATE_TRUNC('month', o.order_date);


-- ──────────────────────────────────────────────────────────────────────────
-- V2. Customer 360 View — single row per customer with all key metrics
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_customer_360 AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name          AS customer_name,
    c.email,
    c.signup_date,
    c.city,
    c.state,
    c.acquisition_channel,
    COUNT(DISTINCT o.order_id)                    AS lifetime_orders,
    ROUND(COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 0), 2)
                                                  AS lifetime_revenue,
    MAX(o.order_date)                             AS last_order_date,
    ('2024-12-31'::DATE - MAX(o.order_date))      AS days_since_last_order,
    ROUND(COALESCE(AVG(pr.rating), 0), 2)         AS avg_review_rating,
    COUNT(DISTINCT r.return_id)                   AS total_returns
FROM customers c
LEFT JOIN orders o         ON o.customer_id    = c.customer_id
                           AND o.order_status   = 'completed'
LEFT JOIN order_items oi   ON oi.order_id      = o.order_id
LEFT JOIN product_reviews pr ON pr.customer_id = c.customer_id
LEFT JOIN returns r        ON r.order_item_id  = oi.order_item_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email,
         c.signup_date, c.city, c.state, c.acquisition_channel;


-- ──────────────────────────────────────────────────────────────────────────
-- V3. Product Performance View — for category managers / merchandising
-- ──────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_product_performance AS
SELECT
    p.product_id,
    p.product_name,
    cat.category_name,
    p.unit_cost,
    p.unit_price,
    p.is_active,
    SUM(oi.quantity)                                                  AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 2) AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price * (1 - oi.discount_pct) - p.unit_cost)), 2)
                                                                      AS gross_profit,
    ROUND(AVG(pr.rating), 2)                                          AS avg_rating,
    COUNT(DISTINCT pr.review_id)                                      AS review_count,
    COUNT(DISTINCT r.return_id)                                       AS return_count
FROM products p
JOIN categories cat    ON cat.category_id = p.category_id
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN orders o     ON o.order_id      = oi.order_id
                       AND o.order_status  = 'completed'
LEFT JOIN product_reviews pr ON pr.product_id = p.product_id
LEFT JOIN returns r    ON r.order_item_id = oi.order_item_id
GROUP BY p.product_id, p.product_name, cat.category_name,
         p.unit_cost, p.unit_price, p.is_active;


-- ============================================================================
-- END OF ANALYTICS ENGINE
-- ============================================================================
-- Skills demonstrated across this file:
--   ✓ JOINs (INNER, LEFT, self-join)
--   ✓ Aggregations (SUM, COUNT, AVG, MIN, MAX)
--   ✓ Window functions (LAG, ROW_NUMBER, RANK, NTILE, SUM OVER, PERCENT_RANK)
--   ✓ Window frames (ROWS BETWEEN)
--   ✓ CTEs (single, chained multi-step)
--   ✓ Subqueries (scalar, correlated)
--   ✓ CASE expressions (simple and searched)
--   ✓ FILTER clause (PostgreSQL conditional aggregation)
--   ✓ Date functions (DATE_TRUNC, EXTRACT, DATE_PART, AGE)
--   ✓ PERCENTILE_CONT (ordered-set aggregate)
--   ✓ NULLIF / COALESCE for safe division
--   ✓ CREATE VIEW for reporting layer
--   ✓ Indexing strategy (schema file)
--   ✓ CHECK constraints and data validation
--   ✓ Performance-conscious comments
-- ============================================================================

# RetailPulse: Ecommerce SQL Analytics

RetailPulse is a PostgreSQL analytics project built on a simulated online store. I designed the database, generated five years of order history (2020 to 2024), and wrote an analytics layer that answers the questions a retail team would ask every week: where revenue is coming from, which customers are slipping away, which products earn their shelf space, and how well orders get delivered. The results feed a Power BI dashboard.

## The data

The seed script builds a store with:

* About 2,000 customers across six acquisition channels
* About 15,000 orders and 35,000 order line items
* 60 products in 8 categories, each category with its own margin target
* Payments, shipping records from five carriers, product reviews, and returns

The schema has 9 related tables with primary keys, foreign keys, and indexes on the columns the queries join and filter on most.

## What the analysis covers

**Revenue.** Monthly revenue with month over month growth, quarterly revenue compared year over year, a 3 month rolling average to smooth out seasonality, and revenue per customer by acquisition channel.

**Customers.** RFM scoring (recency, frequency, monetary value) that sorts customers into segments such as Champion, Loyal, At Risk, and Hibernating. Historical customer lifetime value, a 90 day inactivity churn flag, and churn rate by acquisition channel.

**Cohorts and retention.** A monthly signup cohort retention matrix, cumulative revenue by quarterly cohort, and the repeat purchase rate (the share of customers who come back for a second order).

**Products and margin.** Gross profit and margin by product, actual category margin compared with each category's target, return rates with refund cost, and the product pairs most often bought together.

**Operations.** Order value percentiles, the typical gap between repeat orders, a carrier scorecard (average delivery time, cost, and share of shipments arriving more than 7 days after shipping), and payment method mix over time.

**Reporting views.** Three views built for dashboard use: an executive monthly summary with gross and net revenue, a one row per customer profile, and a product performance view for merchandising.

## Files

* `01_schema.sql` creates the tables, keys, and indexes
* `02_seed_data.sql` loads the simulated data
* `03_analytics_engine.sql` holds the 20 analysis queries and 3 reporting views
* `retailpulse_dashboard.pbix` is the Power BI dashboard built on the query results

## How to run

1. Create an empty PostgreSQL database.
2. Run `01_schema.sql`, then `02_seed_data.sql`, then `03_analytics_engine.sql`.
3. Open `retailpulse_dashboard.pbix` in Power BI Desktop and point it at your database.

The seed script uses random values, so exact figures will differ from one rebuild to the next.

## Tools

PostgreSQL, Power BI

## SQL techniques used

Common table expressions, window functions (LAG, NTILE, RANK, ROW_NUMBER, PERCENT_RANK, running totals), conditional aggregation with FILTER, self joins, ordered set aggregates (PERCENTILE_CONT), date functions, and views.

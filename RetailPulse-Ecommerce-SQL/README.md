# RetailPulse: E-Commerce SQL Analytics

A SQL analytics project on a simulated e-commerce dataset. It covers relational schema design, data seeding, and a set of multi-join analytical queries that surface revenue drivers, seller performance, logistics and order-delay patterns, and product-category trends.

## What is inside
| File | Description |
| --- | --- |
| `01_schema.sql` | Relational schema: tables, primary and foreign keys, relationships |
| `02_seed_data.sql` | Sample seed data for the schema |
| `03_analytics_engine.sql` | Analytical queries (revenue, sellers, logistics, delays, categories) |
| `retailpulse_dashboard.pbix` | Power BI dashboard built on the query results |

## Highlights
- Complex multi-join queries written for a realistic business intelligence use case
- Clear data modeling with documented keys and relationships
- Results visualized in a Power BI dashboard for a non-technical audience

## How to run
1. Create a PostgreSQL database.
2. Run the scripts in order: `01_schema.sql`, then `02_seed_data.sql`, then `03_analytics_engine.sql`.
3. Open `retailpulse_dashboard.pbix` in Power BI Desktop to explore the dashboard.

## Tech
SQL (PostgreSQL), Power BI.

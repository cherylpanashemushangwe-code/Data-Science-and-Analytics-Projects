# HIV and Economic Indicators: SQL Analysis (MySQL)

A SQL analytics project that builds a small data set from public health and economic data, cleans it, joins HIV statistics with GDP and unemployment indicators, and answers analytical questions through aggregate queries. Written in MySQL.

## What it demonstrates
- Schema creation and bulk data loading (`LOAD DATA INFILE`)
- Data cleaning and type casting (`NULLIF`, `TRIM`, `ALTER TABLE`)
- Joining data sets on common keys
- Aggregation, grouping, ratios, and trend analysis

## Query guide
| Files | Purpose |
| --- | --- |
| `Q1.sql`, `Q2.sql` | Enable and verify local file loading |
| `Q3.sql` | Create the `HIV_Project` table |
| `Q4.sql` | Load the HIV data set from CSV |
| `Q5.sql`, `Q6.sql` | Clean values and set proper column types |
| `Q7.sql`, `Q8.sql` | Inspect the HIV and economic tables |
| `Q9.sql` | Join HIV data with GDP and unemployment indicators |
| `Q10.sql`, `Q11.sql` | Inspect the joined table and compute HIV ratios |
| `Q12.sql`, `Q13.sql` | Country-level HIV prevalence and death-rate aggregates |
| `Q14.sql`, `Q15.sql` | Year-level trends of HIV against unemployment and GDP |

## How to run
1. Run the scripts in order (Q1 through Q15) in MySQL.
2. Update the file path in `Q4.sql` to point to your local CSV before loading.

## Tech
SQL (MySQL).

## Data
Uses public HIV and economic indicator data sets.

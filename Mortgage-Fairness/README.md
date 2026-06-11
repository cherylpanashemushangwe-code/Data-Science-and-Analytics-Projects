# FairLend Analytics: Mortgage Fairness Analysis

A project that examines fairness in mortgage lending decisions and presents the findings in an interactive Power BI dashboard. It combines a Python analysis notebook, a data-export script, and a step-by-step dashboard build guide.

## Approach
- Analyzed mortgage lending outcomes for disparities across applicant groups
- Engineered fairness and approval metrics in Python
- Exported model-ready tables to CSV for business intelligence reporting
- Built a Power BI dashboard to communicate the findings to a non-technical audience

## What is inside
| File | Description |
| --- | --- |
| `mortgage_fairness.ipynb` | Python analysis notebook |
| `export_for_powerbi.py` | Generates the CSV tables that feed the dashboard |
| `POWERBI_GUIDE.md` | Step-by-step guide to building the dashboard |
| `mortgage_fairness_dashboard.pbix` | The finished Power BI dashboard |

## How to run
1. Install the Python requirements (pandas, numpy, scikit-learn).
2. Run `python export_for_powerbi.py` to create the CSV files.
3. Follow `POWERBI_GUIDE.md` to build the dashboard, or open `mortgage_fairness_dashboard.pbix` directly in Power BI Desktop.

## Tech
Python (pandas, scikit-learn), Power BI.

## Data
Uses public mortgage lending data. No personal or confidential data is included.

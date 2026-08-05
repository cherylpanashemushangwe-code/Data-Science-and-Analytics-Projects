# Customer Churn Prediction

An end-to-end machine learning project that predicts telecom customer churn and reports the main drivers to support retention decisions. Built on a public sample telco dataset.

## What is inside
| File | Description |
| --- | --- |
| `churn_model_comparison.ipynb` | Model benchmark with full outputs: Logistic Regression vs one and two layer neural networks, overfitting diagnosis, confusion matrices, odds ratios, retention ROI |
| `customer_churn_analysis.ipynb` | EDA, feature engineering, model training and evaluation |
| `customer_churn_dashboard.pbix` | Power BI dashboard summarizing churn and key segments |
| `telco_churn.csv` | Public sample telco dataset (5,000 customers) used by the notebooks |

## Approach
- Exploratory data analysis and feature engineering on customer attributes
- Model benchmark: Logistic Regression against one and two layer neural networks, with a train vs test overfitting check (the deeper network hit 0.93 train accuracy but only 0.74 on test, so the simpler model won at 0.80 ROC AUC)
- Feature importance and odds ratios to identify the top behavioral and demographic drivers of churn
- Retention recommendations with an ROI estimate, framed for a business audience

## How to run
1. Create a Python environment and install: `pandas`, `numpy`, `scikit-learn`, `matplotlib`, `seaborn`.
2. Open `customer_churn_analysis.ipynb` in Jupyter and run the cells in order.
3. Open `customer_churn_dashboard.pbix` in Power BI Desktop for the dashboard view.

## Tech
Python (pandas, scikit-learn), Power BI.

## Data
Uses a public sample telecom churn dataset. No personal or confidential data is included.

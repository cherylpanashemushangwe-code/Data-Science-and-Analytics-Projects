Hospital Closure Risk Prediction Model by Cheryl Mushangwe

**Assessing the Impact of OBBBA Medicaid Cuts on U.S. Hospital Financial Viability**

![Python](https://img.shields.io/badge/Python-3.10+-blue)
![scikit-learn](https://img.shields.io/badge/scikit--learn-1.3+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Overview

On July 4, 2025, the One Big Beautiful Bill Act (OBBBA) was signed into law, enacting approximately $1 trillion in Medicaid spending cuts over the next decade the largest rollback of federal health care support in American history. The Congressional Budget Office projects 10.9 million Americans will lose health insurance as a result.

This project builds a machine learning prediction model to identify which U.S. hospitals are most at risk of closure or severe financial distress due to these cuts. Using 5 years of hospital financial data, it classifies hospitals into risk tiers, simulates the impact of various Medicaid revenue cut scenarios, and maps geographic vulnerability across all 50 states.

## Key Findings

| Finding | Detail |
|---------|--------|
| **22% of hospitals** already have negative operating margins | 956 out of 4,468 hospitals are losing money *before* any cuts |
| **481 hospitals classified as HIGH RISK** | Multiple simultaneous distress signals detected |
| **217 hospitals disappeared** from 2020-2024 | Real closures/mergers that validate the model's patterns |
| **Rural hospitals face 2x the risk** of urban hospitals | 75% of high-risk hospitals are rural |
| **20% Medicaid cut** pushes hundreds more into distress | Scenario simulation shows cascading impact |


## Dataset

**Source:** [NASHP Hospital Cost Tool](https://nashp.org/hospital-cost-tool/) (December 2025)

| Dimension | Value |
|-----------|-------|
| Records | 22,508 |
| Unique hospitals | 4,685 |
| Variables | 121 |
| Time period | 2020–2024 |
| Coverage | 50 states + DC |
| Facility types | Short-term general/specialty, Critical Access |

Data sourced from Medicare Cost Reports (CMS-2552-10) filed by hospitals to CMS.

## Methodology

```
Raw Data → Clean → EDA → Feature Engineering → Risk Classification → Model Training → Evaluation → Scenario Simulation → Geographic Analysis
```

1. **Data Loading & Cleaning**-Replace `.` missing indicators, convert 30+ columns to numeric, create binary flags
2. **Exploratory Data Analysis**-6 visualizations revealing baseline financial health; identified 217 disappeared hospitals
3. **Feature Engineering**-Created 15+ features across 4 categories (financial health, Medicaid vulnerability, structural, trends)
4. **Risk Classification**-Multi-factor scoring system (0–9 points) → High, Moderate, Low risk tiers
5. **Model Training & Evaluation**-Compared Logistic Regression, Random Forest, and Gradient Boosting

   | Model | Accuracy | ROC AUC | High-Risk Detected |
   |-------|----------|---------|-------------------|
   | Logistic Regression | 0.926 | 0.972 | 87/96 |
   | **Random Forest** | **0.952** | **0.991** | **89/96** |
   | Gradient Boosting | 0.987 | 0.997 | 87/96 |

6. **Scenario Simulation**-Simulated 5%–30% Medicaid revenue cuts across all hospitals
7. **Geographic Analysis**-State-level choropleth map of vulnerability

## Results

### Scenario Simulation

| Medicaid Cut | Newly At Risk | Total Negative Margin | Impact |
|-------------|---------------|----------------------|--------|
| 5% | 50 | 951 | Low |
| 10% | 97 | 998 | Moderate |
| 20% | 223 | 1,124 | Severe |
| 30% | 380 | 1,281 | Catastrophic |

### Most Impacted States (20% Medicaid Cut)

| State | Total Hospitals | % At Risk |
|-------|----------------|-----------|
| KS | 130 | 53.1% |
| AL | 85 | 48.2% |
| AR | 75 | 48.0% |
| ND | 44 | 47.7% |
| MT | 61 | 47.5% |

## Repository Structure

```
hospital-closure-risk-prediction/
├── README.md
├── LICENSE
├── requirements.txt
├── notebooks/
│   └── Hospital_Closure_Risk_Model.ipynb
├── data/
│   └── README.md                  # Download instructions
├── outputs/
│   ├── hospital_risk_report.csv
│   ├── scenario_analysis.csv
│   ├── state_impact_analysis.csv
│   └── figures/
├── reports/
│   ├── Hospital_Closure_Risk_Report.pdf
│   └── Presentation.pptx
└── src/
    ├── All_Project_Tables.py
    └── Visualization_Customization_Guide.py
```

---

## Getting Started

### Prerequisites

- Python 3.10+
- Google Colab (recommended) or Jupyter Notebook

### Quick Start

```bash
git clone https://github.com/yourusername/hospital-closure-risk-prediction.git
cd hospital-closure-risk-prediction
pip install -r requirements.txt
```

1. Download the dataset from [NASHP Hospital Cost Tool](https://nashp.org/hospital-cost-tool/)
2. Open `notebooks/Hospital_Closure_Risk_Model.ipynb` in Colab
3. Upload the dataset when prompted → Run All

## Technologies

| Tool | Purpose |
|------|---------|
| pandas | Data manipulation and cleaning |
| scikit-learn | ML models (Logistic Regression, Random Forest, Gradient Boosting) |
| matplotlib / seaborn | Static visualizations and tables |
| plotly | Interactive choropleth maps |
| numpy | Numerical computations |


## Policy Recommendations

1. **Targeted relief** for hospitals with >30% Medicaid dependence (363 hospitals)
2. **Enhanced support** for small rural hospitals (<50 beds)
3. **State-level contingency planning** in the 15 most impacted states
4. **Workforce transition programs** for affected communities
5. **Telehealth expansion** to maintain care access

## References

1. Congressional Budget Office. *Cost Estimate for H.R. 1.* 2025.
2. Kaiser Family Foundation. *Implications of the 2025 Reconciliation Bill for Hospitals.* 2025.
3. Center for American Progress. *The Truth About OBBBA's Medicaid Cuts.* August 2025.
4. American Hospital Association. *Statement on OBBBA.* July 2025.
5. NASHP. *Hospital Cost Tool, 2020–2024.* December 2025.


## Author

**Cheryl**- M.P.S. in Analytics, Northeastern University (Expected December 2026)


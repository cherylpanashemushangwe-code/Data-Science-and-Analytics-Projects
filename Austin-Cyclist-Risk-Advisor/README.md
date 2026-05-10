# 🚲 Austin Cyclist Risk Advisor

An interactive analytics application that helps Austin cyclists make safer go/no-go riding decisions using historical crash data.

---

## Overview

The City of Austin has recorded over **2,463 cyclist-vehicle crashes** between 2010 and 2017. This application transforms that raw crash data into a decision-focused tool that any cyclist can use before heading out:no data analysis skills required.

Instead of showing a spreadsheet or a generic chart, the app asks three simple questions:
- **What time are you leaving?**
- **What day is it?**
- **Is the road dry or wet?**

And returns one clear answer: **LOW RISK / MODERATE RISK / HIGH RISK** - with a recommendation and the historical evidence behind it.

---

## Features

- **Risk Level Banner** - color-coded LOW / MODERATE / HIGH verdict based on historical crash patterns
- **Risk Score Gauge** - 0-100 composite score driven by hour, day, and surface condition
- **Actionable Recommendation** - one-sentence guidance for every risk level
- **Low-Data Warning** - flags when fewer than 5 historical incidents match your exact conditions
- **Safest Hours Suggestion** - shows the historically lowest-crash departure windows
- **Interactive Charts** - crashes by hour, day of week, severity distribution, surface condition, and speed limit
- **Year-over-Year Trend** - total incidents and fatal crashes from 2010–2017
- **Raw Data Explorer** - filterable table of all 2,463 crash records

---

## How Risk Is Calculated

The risk score is a weighted composite of three data-driven components:

| Component | Weight | Logic |
|---|---|---|
| Hour risk | 50% | Crashes at selected hour ÷ max crashes in any single hour |
| Day risk | 25% | Crashes on selected day ÷ max crashes on any single day |
| Surface severity | 25% | Mean injury severity score on selected surface ÷ 4 (max severity) |

| Score Range | Risk Level |
|---|---|
| 0 - 37 | ✅ Low Risk |
| 38 - 61 | ⚠️ Moderate Risk |
| 62 - 100 | 🚨 High Risk |

---

## Dataset

| Field | Details |
|---|---|
| Source | City of Austin Open Data Portal |
| Records | 2,463 cyclist-vehicle crashes |
| Years | 2010 - 2017 |
| Key columns used | Crash Time, Day of Week, Surface Condition, Crash Severity, Crash Year, Speed Limit |

---

## Tech Stack

| Tool | Purpose |
|---|---|
| Python 3.10+ | Core language |
| Streamlit | Web application framework |
| Pandas | Data loading and transformation |
| Plotly | Interactive charts and gauge |
| NumPy | Numerical computations |

---

## Installation & Running Locally

**1. Clone the repository**
```bash
git clone https://github.com/cherylpanashemushangwe-code/Data-Science-and-Analytics-Projects.git
cd Data-Science-and-Analytics-Projects/Austin-Cyclist-Risk-Advisor
```

**2. Install dependencies**
```bash
pip install -r requirements.txt
```

**3. Run the app**
```bash
streamlit run app.py
```

**4. Open in browser**
```
http://localhost:8501
```

> Make sure `bike_crash-B-PF307G4M.csv` is in the same folder as `app.py`

---

## Project Structure

```
Austin-Cyclist-Risk-Advisor/
│
├── app.py                        # Main Streamlit application
├── requirements.txt              # Python dependencies
├── bike_crash-B-PF307G4M.csv    # Austin crash dataset
└── README.md                     # This file
```

---

## Key Findings from the Data

- **5 PM (17:00)** is the single most dangerous hour - crash volume peaks during evening commute
- **Fridays** have the highest crash count of any day of the week
- **11% of all crashes** resulted in incapacitating injury or death
- **Wet-surface crashes** average a higher severity score (1.88) than dry-surface crashes (1.75)
- Crash volume **peaked in 2011** at 380 incidents and has not returned to 2010 levels

---

## Course Information

**Course:** ALY6040 - Data Mining    
**Institution:** Northeastern University  
**Author:** Cheryl Mushangwe  

---

## License

This project is for academic purposes. Data sourced from the City of Austin Open Data Portal.

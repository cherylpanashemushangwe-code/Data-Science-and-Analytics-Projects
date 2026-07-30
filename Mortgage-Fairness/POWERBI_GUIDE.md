# Power BI Dashboard Guide
## FairLend Analytics - Mortgage Fairness Dashboard

---

## Step 0 - Generate the Data Files

Run this first (takes ~2 minutes):
```bash
python export_for_powerbi.py
```
This creates four CSV files in `powerbi_data/`.

---

## Step 1 - Import Data into Power BI Desktop

1. Open **Power BI Desktop** (free download: powerbi.microsoft.com)
2. **Home -> Get Data -> Text/CSV**
3. Import all four files one at a time:

| File | Load As |
|------|---------|
| `applications.csv` | Applications |
| `disparity.csv` | Disparity |
| `income_race.csv` | IncomeRace |
| `geography.csv` | Geography |

4. Click **Transform Data** for `income_race.csv` -> set `bracket_sort` as a **Sort By Column** for `income_bracket` (this fixes axis ordering)

---

## Step 2 - Create DAX Measures

In the **Applications** table, create these measures (**Home -> New Measure**):

```dax
Denial Rate =
DIVIDE(
    COUNTROWS(FILTER(Applications, Applications[denied] = 1)),
    COUNTROWS(Applications),
    0
)
```

```dax
White Denial Rate =
CALCULATE(
    [Denial Rate],
    Applications[race] = "White"
)
```

```dax
Disparity Ratio =
DIVIDE([Denial Rate], [White Denial Rate], 0)
```

```dax
Total Applications = COUNTROWS(Applications)
```

```dax
Total Denials =
COUNTROWS(FILTER(Applications, Applications[denied] = 1))
```

```dax
CFPB Flag =
IF([Disparity Ratio] > 1.25, "⚠️ Flagged", "✅ OK")
```

```dax
Avg Interest Rate =
AVERAGEX(
    FILTER(Applications, NOT(ISBLANK(Applications[interest_rate]))),
    Applications[interest_rate]
)
```

```dax
Avg Loan Amount ($k) =
AVERAGE(Applications[loan_amount])
```

---

## Step 3 - Build the Dashboard (3 Pages)

---

### PAGE 1 - Executive Summary

**Layout:** KPI cards across the top, main chart below

#### KPI Cards (Insert -> Card visual, one per metric)
| Card | Measure | Format |
|------|---------|--------|
| Total Applications | `Total Applications` | No decimal |
| Overall Denial Rate | `Denial Rate` | Percentage |
| Avg Loan Amount | `Avg Loan Amount ($k)` | `$#,##0"k"` |
| Avg Interest Rate | `Avg Interest Rate` | `0.00"%"` |

#### Main Chart - Clustered Bar Chart
- **Y-axis:** `Disparity[race]`
- **X-axis:** `Disparity[denial_rate]`
- **Color:** `Disparity[cfpb_flagged]`
  - True -> `#D62728` (red)
  - False -> `#1F77B4` (blue)
- **Data labels:** On, show `Disparity[disparity_ratio]`
- **Title:** *"Denial Rate by Race - CFPB 1.25× Threshold"*
- Add a **reference line** at the White denial rate value

#### Conditional Formatting Table
- Insert a **Table** visual
- Columns: Race, Applications, Denial Rate, Disparity Ratio, CFPB Flag
- Apply **conditional background color** on Disparity Ratio:
  - Rules: > 1.25 -> Red, 0.9 to 1.25 -> Yellow, < 0.9 -> Green

#### Slicers (right panel)
- `Applications[loan_purpose_label]`
- `Applications[sex]`
- `Applications[year]`

---

### PAGE 2 - Income & Race Deep Dive

**Layout:** Line chart top, heatmap matrix below

#### Line Chart - Denial Rate by Income Bracket and Race
- **X-axis:** `IncomeRace[income_bracket]` (sort by `bracket_sort`)
- **Y-axis:** `IncomeRace[denial_rate]`
- **Legend:** `IncomeRace[race]`
- **Line colors:**
  - White -> `#1F77B4`
  - Black -> `#D62728`
  - Hispanic -> `#FF7F0E`
  - Asian -> `#2CA02C`
- **Title:** *"Denial Rate by Income Bracket - Income Does Not Explain the Gap"*
- **Y-axis format:** Percentage

> **Key talking point:** If all four lines converged at the same income level,
> income would explain the disparity. Persistent vertical gaps prove it does not.

#### Matrix (Heatmap effect)
- Insert a **Matrix** visual
- **Rows:** `IncomeRace[income_bracket]`
- **Columns:** `IncomeRace[race]`
- **Values:** `IncomeRace[denial_rate]`
- Apply **Background Color** conditional formatting:
  - Lowest -> Green (`#2CA02C`), Highest -> Red (`#D62728`)
- Format values as percentage

#### Donut Chart - Application Mix by Race
- **Values:** `Total Applications`
- **Legend:** `Applications[race]`
- Place in the corner as context

---

### PAGE 3 - Geographic Analysis

**Layout:** Map on left, supporting charts on right

#### Filled Map (County Level)
- **Location:** `Geography[county_code]`  
  *(Power BI recognizes 5-digit FIPS codes as US counties)*
- **Color saturation:** `Geography[denial_rate]`
  - Color scale: Green -> Yellow -> Red
- **Tooltips:** Applications, Denial Rate, Avg Income, Minority %
- **Title:** *"Mortgage Denial Rate by County"*

> If the Filled Map struggles with FIPS codes, use **ArcGIS Maps** visual instead
> - paste county_code into Location and set location type to "US County FIPS".

#### Scatter Chart - Minority % vs Denial Rate
- **X-axis:** `Geography[minority_pct]`
- **Y-axis:** `Geography[denial_rate]`
- **Size:** `Geography[applications]`
- **Color:** `Geography[risk_tier]`
  - High Risk -> Red, Medium -> Orange, Low -> Green
- **Title:** *"Redlining Risk: Denial Rate vs Minority Population %"*
- Add a **Trend Line** (Analytics pane -> Trend Line)

#### Bar Chart - Top 10 Counties by Denial Rate
- **Y-axis:** `Geography[county_code]` (Top N filter: 10)
- **X-axis:** `Geography[denial_rate]`
- **Color:** `Geography[risk_tier]`
- Sort descending

#### KPI Card - Geographic Correlation
Create this measure in the Geography table:
```dax
Geo Risk Note =
IF(
    AVERAGE(Geography[minority_pct]) > 30,
    "⚠️ Elevated Geographic Concentration",
    "✅ No Significant Concentration"
)
```

---

*Data: CFPB HMDA 2023 · Methodology: CFPB Fair Lending Examination Procedures*

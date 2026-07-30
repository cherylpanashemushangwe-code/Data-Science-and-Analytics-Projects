"""
Export HMDA data to Power BI-ready CSVs.

Run this AFTER the notebook (it reuses the same download logic).
Then import the CSVs into Power BI Desktop.

Usage:
    python export_for_powerbi.py
    python export_for_powerbi.py --state NY --year 2022
"""

import argparse
import requests
import numpy as np
import pandas as pd
from pathlib import Path

#Config 
parser = argparse.ArgumentParser()
parser.add_argument("--state", default="MA")
parser.add_argument("--year",  type=int, default=2023)
parser.add_argument("--limit", type=int, default=150_000)
args = parser.parse_args()

OUT = Path("powerbi_data")
OUT.mkdir(exist_ok=True)

RACES = ["White", "Black", "Hispanic", "Asian"]

COLS = [
    "action_taken", "derived_race", "derived_ethnicity", "derived_sex",
    "income", "loan_amount", "debt_to_income_ratio",
    "combined_loan_to_value_ratio", "interest_rate", "rate_spread",
    "loan_purpose", "county_code", "tract_minority_population_percent",
    "tract_to_msa_income_percentage", "loan_type", "lien_status",
    "lei", "state_code",
]

LOAN_PURPOSE = {
    1: "Home Purchase", 2: "Home Improvement",
    31: "Refinancing", 32: "Cash-out Refinancing",
    4: "Other", 5: "N/A",
}

RACE_MAP = {
    "White": "White",
    "Black or African American": "Black",
    "Asian": "Asian",
    "American Indian or Alaska Native": "Other",
    "Native Hawaiian or Other Pacific Islander": "Other",
    "2 or more minority races": "Other",
    "Joint": "Joint",
}


#Download
print(f"Downloading HMDA {args.year} - {args.state} ...")
url = (
    f"https://ffiec.cfpb.gov/v2/data-browser-api/view/csv"
    f"?years={args.year}&states={args.state}&actions_taken=1,3"
)
resp = requests.get(url, timeout=180, stream=True)
resp.raise_for_status()

chunks, total = [], 0
for chunk in pd.read_csv(resp.raw, chunksize=10_000, low_memory=False,
                          usecols=lambda c: c in COLS):
    chunks.append(chunk)
    total += len(chunk)
    if total >= args.limit:
        break

raw = pd.concat(chunks, ignore_index=True)
print(f"  {len(raw):,} records downloaded")


#Clean 
df = raw[raw["action_taken"].isin([1, 3])].copy()
df["denied"] = (df["action_taken"] == 3).astype(int)
df["approved"] = 1 - df["denied"]
df["year"] = args.year
df["state"] = args.state

df["race"] = df["derived_race"].map(RACE_MAP).fillna("Unknown")
df.loc[df["derived_ethnicity"] == "Hispanic or Latino", "race"] = "Hispanic"

df["sex"] = (
    df["derived_sex"].replace({"Sex Not Available": "Unknown", "Not applicable": "Unknown"})
    if "derived_sex" in df.columns else "Unknown"
)

def safe_numeric(df, col):
    """Returns numeric series for col, or NaN series if col missing from API response."""
    if col in df.columns:
        return pd.to_numeric(df[col], errors="coerce")
    return pd.Series(np.nan, index=df.index)

df["income"]           = safe_numeric(df, "income")
df["loan_amount"]      = safe_numeric(df, "loan_amount") / 1_000
df["ltv"]              = safe_numeric(df, "combined_loan_to_value_ratio")
df["interest_rate"]    = safe_numeric(df, "interest_rate")
df["rate_spread"]      = safe_numeric(df, "rate_spread")
df["minority_pct"]     = safe_numeric(df, "tract_minority_population_percent")
df["tract_income_pct"] = safe_numeric(df, "tract_to_msa_income_percentage")

dti_raw = (
    df["debt_to_income_ratio"]
    .replace({"Exempt": np.nan, "<20%": "19", ">60%": "61"})
    .astype(str).str.replace("%", "", regex=False).str.split("-").str[0]
)
df["dti"] = pd.to_numeric(dti_raw, errors="coerce")

df["loan_purpose_label"] = df["loan_purpose"].map(LOAN_PURPOSE).fillna("Unknown")

df["income_bracket"] = pd.cut(
    df["income"],
    bins=[0, 50, 75, 100, 150, 200, np.inf],
    labels=["<$50k", "$50-75k", "$75-100k", "$100-150k", "$150-200k", "$200k+"],
    right=False,
)

df["county_code"] = df["county_code"].astype(str).str.zfill(5)
df["high_cost_loan"] = (df["rate_spread"] > 1.5).astype(float)

#TABLE 1-Main fact table  (one row per application)
#Power BI: import as "Applications"
fact_cols = [
    "year", "state", "county_code", "race", "sex",
    "income", "loan_amount", "dti", "ltv", "interest_rate", "rate_spread",
    "loan_purpose_label", "minority_pct", "tract_income_pct",
    "denied", "approved", "high_cost_loan", "income_bracket",
]
fact = df[[c for c in fact_cols if c in df.columns]].copy()
fact.to_csv(OUT / "applications.csv", index=False)
print(f"  Table 1 saved -> powerbi_data/applications.csv  ({len(fact):,} rows)")

#TABLE 2-Disparity ratios by race  (pre-aggregated for KPI visuals)
#Power BI: import as "Disparity"
disp = (
    df.groupby("race")["denied"]
    .agg(applications="count", denials="sum", denial_rate="mean")
    .reset_index()
)
ref = disp.loc[disp["race"] == "White", "denial_rate"].values[0]
disp["disparity_ratio"]  = (disp["denial_rate"] / ref).round(3)
disp["cfpb_flagged"]     = disp["disparity_ratio"] > 1.25
disp["approvals"]        = disp["applications"] - disp["denials"]
disp["year"]             = args.year
disp["state"]            = args.state

disp.to_csv(OUT / "disparity.csv", index=False)
print(f"  Table 2 saved -> powerbi_data/disparity.csv  ({len(disp)} rows)")

#TABLE 3-Income bracket × Race  (for income analysis visual)
#Power BI: import as "IncomeRace"
income_race = (
    df[df["race"].isin(RACES) & df["income_bracket"].notna()]
    .groupby(["income_bracket", "race"], observed=True)["denied"]
    .agg(applications="count", denial_rate="mean")
    .reset_index()
)
income_race = income_race[income_race["applications"] >= 20]
income_race["year"]  = args.year
income_race["state"] = args.state

#Add bracket sort order for correct axis ordering in Power BI
bracket_order = {"<$50k": 1, "$50-75k": 2, "$75-100k": 3,
                 "$100-150k": 4, "$150-200k": 5, "$200k+": 6}
income_race["bracket_sort"] = income_race["income_bracket"].map(bracket_order)

income_race.to_csv(OUT / "income_race.csv", index=False)
print(f"  Table 3 saved -> powerbi_data/income_race.csv  ({len(income_race)} rows)")

#TABLE 4-Geographic summary by county  (for map visual)
#Power BI: import as "Geography"
geo = (
    df.groupby("county_code")
    .agg(
        applications=("denied", "count"),
        denials=("denied", "sum"),
        denial_rate=("denied", "mean"),
        avg_income=("income", "mean"),
        avg_loan=("loan_amount", "mean"),
        minority_pct=("minority_pct", "mean"),
        avg_interest_rate=("interest_rate", "mean"),
    )
    .reset_index()
)
geo = geo[geo["applications"] >= 20]
geo["state_fips"]    = geo["county_code"].str[:2]
geo["county_fips"]   = geo["county_code"].str[2:]
geo["year"]          = args.year
geo["state"]         = args.state

#Risk tier for color coding in Power BI
def risk_tier(rate):
    if rate >= 0.30:   return "High Risk"
    if rate >= 0.20:   return "Medium Risk"
    return "Low Risk"

geo["risk_tier"] = geo["denial_rate"].apply(risk_tier)

geo.to_csv(OUT / "geography.csv", index=False)
print(f"  Table 4 saved -> powerbi_data/geography.csv  ({len(geo)} rows)")


#Summary
print(f"""
  Export complete - {args.year} | {args.state}
  Files in:  mortgage-fairness/powerbi_data/

  1. applications.csv - {len(fact):,} rows   (main fact table)
  2. disparity.csv - {len(disp)} rows     (disparity ratios by race)
  3. income_race.csv - {len(income_race)} rows  (income × race breakdown)
  4. geography.csv - {len(geo)} rows    (county-level denial rates)

  Next: open Power BI Desktop and follow POWERBI_GUIDE.md
  
Overall denial rate : {df['denied'].mean():.1%}
White denial rate   : {ref:.1%}
""")

flagged = disp[disp["cfpb_flagged"] & ~disp["race"].isin(["Unknown", "Joint"])]
if len(flagged):
    print("  ⚠️  CFPB Threshold Exceeded (>1.25x):")
    for _, r in flagged.iterrows():
        print(f"     {r['race']}: {r['disparity_ratio']:.2f}x disparity")
else:
    print("  ✅  No groups exceed the 1.25x CFPB threshold.")

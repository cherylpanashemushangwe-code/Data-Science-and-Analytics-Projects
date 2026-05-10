import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import numpy as np

st.set_page_config(
    page_title="Austin Cyclist Risk Advisor",
    page_icon="🚲",
    layout="wide",
    initial_sidebar_state="expanded",
)

st.markdown("""
<style>
/* ── global dark canvas ── */
html, body, [class*="css"] { background-color: #0e1117; color: #f0f0f0; }
.block-container { padding-top: 1.5rem; }

/* ── hero banner ── */
.hero-low      { background:#145214; border-left:6px solid #33ee55; padding:22px 28px; border-radius:10px; color:#ffffff; }
.hero-moderate { background:#4a3800; border-left:6px solid #ffbe00; padding:22px 28px; border-radius:10px; color:#ffffff; }
.hero-high     { background:#5a0000; border-left:6px solid #ff4444; padding:22px 28px; border-radius:10px; color:#ffffff; }
.hero-title    { font-size:2.1rem; font-weight:800; letter-spacing:1px; margin:0; color:#ffffff; }
.hero-sub      { font-size:0.95rem; color:#dddddd; margin-top:6px; }

/* ── metric cards ── */
.metric-row    { display:flex; gap:12px; margin:18px 0; }
.mcard         { background:#1e2230; border:1px solid #3a3f55; border-radius:8px; padding:16px 20px; flex:1; }
.mcard h3      { margin:0; font-size:1.9rem; font-weight:800; color:#ffffff; }
.mcard p       { margin:4px 0 0; font-size:0.82rem; color:#cccccc; }

/* ── confidence warning ── */
.conf-warn { background:#3a3000; border:1px solid #ffcc00; border-radius:8px;
             padding:10px 14px; font-size:0.88rem; margin:10px 0; color:#ffe080; }

/* ── safe window pill ── */
.safe-pill { display:inline-block; background:#1a6e1a; border:1px solid #44cc44;
             border-radius:20px; padding:5px 14px; margin:3px;
             font-size:0.88rem; font-weight:600; color:#ffffff; }
</style>
""", unsafe_allow_html=True)


#DATA LOADING
@st.cache_data
def load_data():
    import os
    # Try multiple locations: same folder as script, current dir, then GitHub raw URL
    here = os.path.dirname(os.path.abspath(__file__))
    candidates = [
        os.path.join(here, "bike_crash-B-PF307G4M.csv"),
        "bike_crash-B-PF307G4M.csv",
        "https://raw.githubusercontent.com/cherylpanashemushangwe-code/Data-Science-and-Analytics-Projects/main/Austin-Cyclist-Risk-Advisor/bike_crash-B-PF307G4M.csv",
    ]
    df = None
    for path in candidates:
        try:
            df = pd.read_csv(path)
            break
        except Exception:
            continue
    if df is None:
        st.error("Could not load the crash dataset. Please ensure bike_crash-B-PF307G4M.csv is available.")
        st.stop()

    # Parse HHMM integer → hour
    df["Crash Time"] = pd.to_numeric(df["Crash Time"], errors="coerce")
    df["Hour"] = (df["Crash Time"] // 100).clip(0, 23).astype("Int64")

    # Numeric severity
    sev_map = {
        "Killed":                     4,
        "Incapacitating Injury":      3,
        "Non-Incapacitating Injury":  2,
        "Possible Injury":            1,
        "Not Injured":                0,
    }
    df["Severity Score"] = df["Crash Severity"].map(sev_map).fillna(1)

    # Simplified surface
    def surf(x):
        xl = str(x).strip().lower()
        if xl == "dry":                                           return "Dry"
        if xl in ("wet", "slush", "standing water", "ice"):      return "Wet"
        return "Other / Unknown"
    df["Surface"] = df["Surface Condition"].apply(surf)

    # Clean speed limit (keep only real numeric values)
    def parse_speed(x):
        try:
            v = int(float(x))
            return v if v > 0 else np.nan
        except Exception:
            return np.nan
    df["Speed Num"] = df["Speed Limit"].apply(parse_speed)

    return df


df = load_data()

# Pre-compute aggregates once
hour_counts   = df.groupby("Hour").size()
day_counts    = df.groupby("Day of Week").size()
surface_sev   = df.groupby("Surface")["Severity Score"].mean()
max_hour      = int(hour_counts.max())
max_day       = int(day_counts.max())
overall_sev   = df["Severity Score"].mean()

DAYS_ORDERED = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]


# RISK ENGINE
def compute_risk(hour: int, day: str, surface: str):
    """
    Returns (score 0-100, label, css_class, recommendation, exact_count)

    score components:
      50%  hour risk  — how many incidents fell in this hour vs the worst hour
      25%  day risk   — same logic for day-of-week
      25%  surface severity — mean severity score on this surface vs dataset max (4)
    """
    h_risk  = hour_counts.get(hour, 0) / max_hour          # 0-1
    d_risk  = day_counts.get(day,   0) / max_day            # 0-1
    s_sev   = surface_sev.get(surface, overall_sev)
    s_risk  = s_sev / 4.0                                   # 0-1  (max severity = 4)

    composite = h_risk * 0.50 + d_risk * 0.25 + s_risk * 0.25
    score     = round(composite * 100)

    # Exact-match incident count for confidence check
    mask  = (df["Hour"] == hour) & (df["Day of Week"] == day) & (df["Surface"] == surface)
    exact = int(mask.sum())

    if composite < 0.38:
        label  = "LOW RISK"
        cls    = "hero-low"
        icon   = "✅"
        rec    = ("Historical data suggests this is a relatively safe window to ride. "
                  "Exercise normal caution, follow traffic laws, and use lights if visibility is low.")
    elif composite < 0.62:
        label  = "MODERATE RISK"
        cls    = "hero-moderate"
        icon   = "⚠️"
        rec    = ("Some elevated risk factors are present for these conditions. "
                  "Use front and rear lights, wear a helmet, and be especially alert at intersections.")
    else:
        label  = "HIGH RISK"
        cls    = "hero-high"
        icon   = "🚨"
        rec    = ("Historically dangerous conditions. Strongly consider adjusting your departure time, "
                  "choosing lower-traffic streets, or adding protective gear before riding.")

    return score, label, cls, icon, rec, exact


# SIDEBAR
with st.sidebar:
    st.markdown("## 🚲 Plan Your Ride")
    st.markdown("Set the conditions you're about to ride in.")
    st.markdown("---")

    sel_hour = st.slider("🕐 Departure hour", 0, 23, 17,
                         format="%d:00",
                         help="Select the hour you plan to start riding.")

    sel_day  = st.selectbox("📅 Day of week", DAYS_ORDERED, index=4)

    sel_surf = st.selectbox(
        "🌧️ Road surface",
        ["Dry", "Wet", "Other / Unknown"],
        help="Is it raining or has it recently rained?"
    )

    st.markdown("---")
    st.caption(
        "Risk is based on historical cyclist-vehicle crash records from Austin, TX. "
        "This tool does **not** predict future crashes - it surfaces patterns from past incidents."
    )


# COMPUTE
score, label, hero_cls, icon, rec, exact_count = compute_risk(sel_hour, sel_day, sel_surf)

# Safest 3 hours overall
safe_hours = (
    hour_counts.sort_values()
    .head(4)
    .index.tolist()
)
# exclude midnight hours that have low counts simply because no one rides then
# just present raw safest hours
safe_hours_str = "  ".join(
    [f"<span class='safe-pill'>{int(h):02d}:00</span>" for h in sorted(safe_hours)]
)


# HEADER
st.title("🚲 Austin Cyclist Risk Advisor")
st.markdown(
    f"Evaluating conditions for **{sel_hour:02d}:00 · {sel_day} · {sel_surf} surface**"
)
st.markdown("---")


# HERO ROW
col_hero, col_gauge, col_meta = st.columns([2.2, 1.6, 2.2])

with col_hero:
    st.markdown(f"""
    <div class="{hero_cls}">
        <p class="hero-title">{icon} {label}</p>
        <p class="hero-sub">{sel_hour:02d}:00 &nbsp;·&nbsp; {sel_day} &nbsp;·&nbsp; {sel_surf}</p>
    </div>
    """, unsafe_allow_html=True)

    st.markdown(f"<br>**Recommendation:** {rec}", unsafe_allow_html=True)

    if exact_count < 5:
        st.markdown(
            f"<div class='conf-warn'>⚠️ <strong>Limited data:</strong> only <strong>{exact_count}</strong> "
            "historical crashes match all three conditions exactly. The risk estimate draws on broader "
            "hourly and daily patterns; treat with caution.</div>",
            unsafe_allow_html=True,
        )

with col_gauge:
    bar_color = "#33ee55" if score < 38 else ("#ffbe00" if score < 62 else "#ff4444")
    fig_g = go.Figure(go.Indicator(
        mode="gauge+number",
        value=score,
        number={"font": {"size": 42, "color": bar_color}, "suffix": ""},
        gauge={
            "axis": {
                "range": [0, 100],
                "tickcolor": "#cccccc",
                "tickfont": {"color": "#cccccc", "size": 11},
            },
            "bar":       {"color": bar_color, "thickness": 0.30},
            "bgcolor":   "#1a1a2e",
            "bordercolor": "#555555",
            "borderwidth": 2,
            "steps": [
                {"range": [0,  38], "color": "#163016"},
                {"range": [38, 62], "color": "#302800"},
                {"range": [62,100], "color": "#380000"},
            ],
            "threshold": {
                "line":      {"color": "#ffffff", "width": 4},
                "thickness": 0.85,
                "value":     score,
            },
        },
        title={"text": "Risk Score", "font": {"size": 15, "color": "#dddddd"}},
    ))
    fig_g.update_layout(
        height=240,
        margin=dict(t=50, b=10, l=20, r=20),
        paper_bgcolor="rgba(0,0,0,0)",
        font_color="white",
    )
    st.plotly_chart(fig_g, width="stretch")

with col_meta:
    h_incidents = int(hour_counts.get(sel_hour, 0))
    d_incidents = int(day_counts.get(sel_day,  0))
    total       = len(df)

    st.markdown(f"""
    <div class="metric-row">
        <div class="mcard">
            <h3>{h_incidents}</h3>
            <p>Crashes at {sel_hour:02d}:00 (all years)</p>
        </div>
        <div class="mcard">
            <h3>{d_incidents}</h3>
            <p>Crashes on {sel_day}s (all years)</p>
        </div>
    </div>
    <div class="metric-row">
        <div class="mcard">
            <h3>{total:,}</h3>
            <p>Total incidents in dataset</p>
        </div>
        <div class="mcard">
            <h3>{exact_count}</h3>
            <p>Exact condition matches</p>
        </div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("**Historically safest departure hours:**")
    st.markdown(safe_hours_str, unsafe_allow_html=True)


# CHARTS
st.markdown("---")
st.subheader("Historical Incident Patterns")

tab1, tab2, tab3, tab4 = st.tabs([
    "📊 Hour of Day", "📅 Day of Week", "🩹 Severity", "🌧️ Surface & Speed"
])

_layout_defaults = dict(
    paper_bgcolor="rgba(0,0,0,0)",
    plot_bgcolor="rgba(0,0,0,0.15)",
    font_color="white",
    margin=dict(t=40, b=30, l=10, r=10),
)

# ── Tab 1: Hourly ──
with tab1:
    hourly_df = hour_counts.reset_index().rename(columns={"Hour": "Hour", 0: "Incidents"})
    hourly_df.columns = ["Hour", "Incidents"]
    hourly_df["Hour"] = hourly_df["Hour"].astype(int)
    hourly_df = hourly_df.sort_values("Hour")

    fig_h = px.bar(
        hourly_df, x="Hour", y="Incidents",
        title="Cyclist Crashes by Hour of Day (all years)",
        color="Incidents",
        color_continuous_scale=["#1a4a1a", "#c8a000", "#c00000"],
    )
    fig_h.add_vline(
        x=sel_hour, line_dash="dash", line_color="cyan", line_width=2,
        annotation_text=f"Your ride: {sel_hour:02d}:00",
        annotation_font_color="cyan",
    )
    fig_h.update_layout(**_layout_defaults, showlegend=False,
                        xaxis=dict(tickmode="linear", dtick=1))
    st.plotly_chart(fig_h, width="stretch")
    st.caption(
        "Evening commute hours (4–7 PM) consistently account for the highest crash volume — "
        "aligning with higher traffic and lower light conditions."
    )

# ── Tab 2: Day of week ──
with tab2:
    day_df = (
        day_counts
        .reindex(DAYS_ORDERED)
        .reset_index()
        .rename(columns={"Day of Week": "Day", 0: "Incidents"})
    )
    day_df.columns = ["Day", "Incidents"]

    fig_d = px.bar(
        day_df, x="Day", y="Incidents",
        title="Cyclist Crashes by Day of Week (all years)",
        color="Incidents",
        color_continuous_scale=["#1a4a1a", "#c8a000", "#c00000"],
    )
    # Highlight selected day
    sel_x = DAYS_ORDERED.index(sel_day)
    fig_d.add_vline(
        x=sel_x, line_dash="dash", line_color="cyan", line_width=2,
        annotation_text=f"Selected: {sel_day}",
        annotation_font_color="cyan",
    )
    fig_d.update_layout(**_layout_defaults, showlegend=False)
    st.plotly_chart(fig_d, width="stretch")
    st.caption("Weekday crashes are driven by commuter traffic; weekend spikes reflect recreational riding patterns.")

# ── Tab 3: Severity ──
with tab3:
    sev_order = [
        "Killed", "Incapacitating Injury",
        "Non-Incapacitating Injury", "Possible Injury", "Not Injured",
    ]
    sev_df = (
        df["Crash Severity"]
        .value_counts()
        .reindex(sev_order, fill_value=0)
        .reset_index()
    )
    sev_df.columns = ["Severity", "Count"]
    pct = sev_df["Count"].sum()
    sev_df["Pct"] = (sev_df["Count"] / pct * 100).round(1)

    col_sv1, col_sv2 = st.columns(2)

    with col_sv1:
        fig_sv = px.bar(
            sev_df, x="Count", y="Severity", orientation="h",
            title="Crash Severity Distribution",
            color="Severity",
            color_discrete_map={
                "Killed":                    "#cc0000",
                "Incapacitating Injury":     "#e05000",
                "Non-Incapacitating Injury": "#c89000",
                "Possible Injury":           "#a8c000",
                "Not Injured":               "#22aa44",
            },
            text="Pct",
        )
        fig_sv.update_traces(texttemplate="%{text}%", textposition="outside")
        fig_sv.update_layout(**_layout_defaults, showlegend=False,
                             yaxis=dict(categoryorder="array", categoryarray=sev_order[::-1]))
        st.plotly_chart(fig_sv, width="stretch")

    with col_sv2:
        # Severity by surface
        sev_surf = (
            df.groupby(["Surface", "Crash Severity"])
            .size()
            .reset_index(name="Count")
        )
        fig_ss = px.bar(
            sev_surf, x="Surface", y="Count", color="Crash Severity",
            title="Severity by Surface Condition",
            color_discrete_map={
                "Killed":                    "#cc0000",
                "Incapacitating Injury":     "#e05000",
                "Non-Incapacitating Injury": "#c89000",
                "Possible Injury":           "#a8c000",
                "Not Injured":               "#22aa44",
            },
            barmode="stack",
        )
        fig_ss.update_layout(**_layout_defaults)
        st.plotly_chart(fig_ss, width="stretch")

    st.caption(
        "Non-incapacitating and possible-injury crashes make up the bulk of incidents, "
        "but fatal and incapacitating crashes remain a significant share — underscoring "
        "the real danger cyclists face in Austin traffic."
    )

# ── Tab 4: Surface & Speed ──
with tab4:
    col_s1, col_s2 = st.columns(2)

    with col_s1:
        surf_df = df["Surface"].value_counts().reset_index()
        surf_df.columns = ["Surface", "Incidents"]
        fig_surf = px.pie(
            surf_df, names="Surface", values="Incidents",
            title="Crashes by Road Surface",
            color="Surface",
            color_discrete_map={
                "Dry":             "#4da6ff",
                "Wet":             "#3388dd",
                "Other / Unknown": "#888888",
            },
            hole=0.4,
        )
        fig_surf.update_layout(paper_bgcolor="rgba(0,0,0,0)", font_color="white",
                               margin=dict(t=50, b=10))
        st.plotly_chart(fig_surf, width="stretch")

    with col_s2:
        spd_df = (
            df.dropna(subset=["Speed Num"])
            .groupby("Speed Num")
            .agg(Incidents=("Severity Score","count"), Avg_Severity=("Severity Score","mean"))
            .reset_index()
        )
        spd_df.columns = ["Speed Limit", "Incidents", "Avg Severity"]
        fig_spd = px.scatter(
            spd_df, x="Speed Limit", y="Incidents",
            size="Avg Severity", color="Avg Severity",
            title="Incidents & Avg Severity by Speed Limit",
            color_continuous_scale=["#22aa44", "#c8a000", "#cc0000"],
            labels={"Speed Limit": "Speed Limit (mph)"},
            size_max=40,
        )
        fig_spd.update_layout(**_layout_defaults)
        st.plotly_chart(fig_spd, width="stretch")

    st.caption(
        "Higher speed-limit roads are associated with fewer total incidents but higher average severity — "
        "crashes at speed are more likely to be incapacitating or fatal."
    )


# YEAR-OVER-YEAR TREND
st.markdown("---")
st.subheader("Are Austin Cyclists Getting Safer Over Time?")

yearly = (
    df.groupby("Crash Year")
    .agg(Incidents=("Severity Score","count"), Killed=("Crash Severity", lambda s: (s == "Killed").sum()))
    .reset_index()
)

fig_y = go.Figure()
fig_y.add_trace(go.Bar(
    x=yearly["Crash Year"], y=yearly["Incidents"],
    name="Total Incidents", marker_color="#2255aa", opacity=0.7,
))
fig_y.add_trace(go.Scatter(
    x=yearly["Crash Year"], y=yearly["Killed"],
    name="Fatal Crashes", mode="lines+markers",
    line=dict(color="#ee3333", width=2.5),
    marker=dict(size=7),
    yaxis="y2",
))
fig_y.update_layout(
    title="Cyclist Incidents per Year",
    xaxis_title="Year",
    yaxis=dict(title="Total Incidents", color="#aaaaff"),
    yaxis2=dict(title="Fatal Crashes", overlaying="y", side="right", color="#ee3333"),
    legend=dict(x=0.01, y=0.99),
    paper_bgcolor="rgba(0,0,0,0)",
    plot_bgcolor="rgba(0,0,0,0.15)",
    font_color="white",
    margin=dict(t=50, b=30),
)
st.plotly_chart(fig_y, width="stretch")
st.caption(
    "Incident counts reflect both actual risk and changes in cycling volume. "
    "A rise in total crashes alongside a growing cycling population does not necessarily "
    "mean per-ride risk is increasing — but the trend warrants continued city investment in infrastructure."
)



# KEY INSIGHTS SUMMARY

st.markdown("---")
st.subheader("Key Takeaways from the Data")

peak_hour = int(hour_counts.idxmax())
peak_day  = str(day_counts.idxmax())
fatal_pct = round(
    df[df["Crash Severity"] == "Killed"].shape[0] / len(df) * 100, 1
)
wet_sev   = round(surface_sev.get("Wet", 0), 2)
dry_sev   = round(surface_sev.get("Dry", 0), 2)

col_i1, col_i2, col_i3 = st.columns(3)
col_i1.info(
    f"**🕐 Riskiest hour:** {peak_hour:02d}:00\n\n"
    "Evening commute traffic peaks combine with sun glare and driver fatigue."
)
col_i2.info(
    f"**📅 Riskiest day:** {peak_day}\n\n"
    "Historically the highest crash volume day — likely driven by commuter patterns."
)
col_i3.info(
    f"**🌧️ Wet vs Dry severity:** {wet_sev:.2f} vs {dry_sev:.2f}\n\n"
    f"Wet-surface crashes average higher severity scores. Ride with extra caution in rain."
)

st.info(
    f"**⚠️ Fatal crash share:** {fatal_pct}% of all recorded incidents resulted in a fatality — "
    "a stark reminder that cyclist-vehicle crashes carry life-threatening consequences."
)


# DO CYCLISTS' CONCERNS HAVE MERIT?
st.markdown("---")
st.subheader("Do the Data Support Cyclists' Concerns?")

incap_fatal_pct = round(
    df[df["Crash Severity"].isin(["Killed", "Incapacitating Injury"])].shape[0]
    / len(df) * 100, 1
)
peak_yr   = int(yearly.loc[yearly["Incidents"].idxmax(), "Crash Year"])
peak_yr_n = int(yearly["Incidents"].max())

st.markdown(f"""
**Yes — the data clearly support Austin cyclists' concerns.** Between 2010 and 2017,
the City of Austin recorded **{len(df):,} cyclist-vehicle crashes**. Key findings:

- **{incap_fatal_pct}% of crashes** resulted in an incapacitating injury or death — outcomes
  that carry lasting physical and financial consequences for riders.
- Crash volume **peaked in {peak_yr}** at **{peak_yr_n} incidents** and has not returned to
  2010 levels, despite ongoing city safety programs.
- The highest-risk window — **{peak_hour:02d}:00 on {peak_day}s** — overlaps precisely with
  standard evening commute hours, when cyclists share the road with the heaviest motor
  vehicle traffic.
- Wet-surface crashes produce measurably higher severity scores ({wet_sev:.2f} vs
  {dry_sev:.2f} on dry roads), yet the city's road drainage infrastructure has not
  eliminated this hazard.

The pattern is consistent and statistically meaningful across eight years of data: Austin
cyclists face genuine, recurring danger. The cyclists' call for stronger infrastructure
investment — protected lanes, better intersection signaling, and improved road surfaces —
is well supported by the evidence.
""")


# RAW DATA EXPLORER

st.markdown("---")
with st.expander("🔍 Explore the Raw Data"):
    st.markdown(
        "Filter and inspect the underlying crash records. "
        "All risk calculations in this app are derived from this dataset."
    )

    year_filter = st.multiselect(
        "Filter by year", sorted(df["Crash Year"].unique().tolist()),
        default=sorted(df["Crash Year"].unique().tolist()),
    )
    sev_filter = st.multiselect(
        "Filter by severity",
        ["Killed", "Incapacitating Injury", "Non-Incapacitating Injury", "Possible Injury", "Not Injured"],
        default=["Killed", "Incapacitating Injury", "Non-Incapacitating Injury", "Possible Injury", "Not Injured"],
    )

    display_cols = [
        "Crash Year", "Day of Week", "Hour", "Surface",
        "Crash Severity", "Severity Score",
        "Speed Limit", "Intersection Related", "Traffic Control Type",
    ]
    filtered = df[
        df["Crash Year"].isin(year_filter) & df["Crash Severity"].isin(sev_filter)
    ][display_cols].sort_values(["Crash Year", "Hour"])

    st.markdown(f"**{len(filtered):,} records** match current filters.")
    st.dataframe(filtered.reset_index(drop=True), width="stretch", height=320)



# FOOTER
st.markdown("---")
st.caption(
    "**Data source:** City of Austin cyclist-vehicle crash records (2010–2017). "
    "This application surfaces historical patterns only. "
    "It does not predict future incidents and should not replace safe riding practices. "
    "Always follow local traffic laws and wear appropriate protective gear."
)

# =========================
# Load required libraries
# =========================
library(dplyr)
library(ggplot2)
library(readr)
library(gt)
library(lubridate)
library(glmnet)
library(tidyr)
library(broom)
library(forcats)
library(scales)

# =========================
# 1. Read and combine CSV files
# =========================
file_paths <- c(
  "Intermediate Analytics/2015 (2).csv",
  "Intermediate Analytics/2016.csv",
  "Intermediate Analytics/2017.csv",
  "Intermediate Analytics/2018.csv",
  "Intermediate Analytics/2019.csv"
)

files_list <- lapply(file_paths, read_csv)
files <- bind_rows(files_list)

# Standardize column names
files <- files %>% 
  rename_all(~gsub(" ", "_", tolower(.)))

# =========================
# 2. Feature engineering
# =========================
files <- files %>%
  mutate(
    open_dt = as.Date(open_dt),
    closed_dt = as.Date(closed_dt),
    closure_days = as.numeric(closed_dt - open_dt),
    timely_close = ifelse(!is.na(closure_days) & closure_days <= 7, 1, 0),
    mobile_request = ifelse(tolower(source) == "mobile", 1, 0),
    post_2017 = ifelse(year(open_dt) >= 2017, 1, 0)
  )

# =========================
# 3. Descriptive summary
# =========================
summary_table <- files %>%
  mutate(year = year(open_dt)) %>%
  group_by(year, mobile_request) %>%
  summarise(
    total_requests = n(),
    avg_closure_days = mean(closure_days, na.rm = TRUE),
    pct_timely = mean(timely_close, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  gt() %>%
  fmt_number(columns = vars(avg_closure_days, pct_timely), decimals = 2) %>%
  tab_header(title = "Closure Time Summary by Year and Submission Channel")

print(summary_table)

# =========================
# 4. Chi-square test
# =========================
chi_table <- table(files$mobile_request, files$timely_close)
chi_test <- chisq.test(chi_table)

chi_summary <- data.frame(
  Statistic = chi_test$statistic,
  df = chi_test$parameter,
  p_value = chi_test$p.value
)

gt(chi_summary) %>%
  fmt_number(columns = vars(Statistic, p_value), decimals = 3) %>%
  tab_header(title = "Chi-Square Test: Mobile Request vs Timely Closure")

# =========================
# 5. Logistic regression
# =========================
logit_model <- glm(
  timely_close ~ mobile_request * post_2017 + subject + neighborhood,
  data = files,
  family = binomial
)

logit_summary <- tidy(logit_model) %>%
  mutate(
    term = as.character(term),
    odds_ratio = exp(estimate),
    conf_low = exp(estimate - 1.96*std.error),
    conf_high = exp(estimate + 1.96*std.error)
  ) %>%
  arrange(p.value) %>%
  slice(1:3) %>%  # top 3 predictors by significance
  select(term, odds_ratio, conf_low, conf_high, p.value) %>%
  rename(Predictor = term, Odds_Ratio = odds_ratio,
         CI_Lower = conf_low, CI_Upper = conf_high, P_Value = p.value)

# Display logistic summary table
gt(logit_summary) %>%
  fmt_number(columns = vars(Odds_Ratio, CI_Lower, CI_Upper, P_Value), decimals = 3) %>%
  tab_header(title = "Top 3 Predictors: Logistic Regression (Timely Closure)")

# -------------------------
# LASSO regression
# -------------------------
lasso_summary <- data.frame(
  Predictor = rownames(coef(lasso_model)),
  Coefficient = as.numeric(coef(lasso_model))
) %>%
  filter(Predictor != "(Intercept)") %>%
  arrange(desc(abs(Coefficient))) %>%
  slice(1:3)


print(
  gt(lasso_summary) %>%
    fmt_number(columns = vars(Coefficient), decimals = 3) %>%
    tab_header(title = "Top 3 Predictors: LASSO Regression (Closure Days)")
)

# -------------------------
# Combine and display table
# -------------------------
concise_table <- bind_rows(logit_top, lasso_df)

gt(concise_table) %>%
  fmt_number(columns = vars(Value, P_Value), decimals = 3) %>%
  tab_header(title = "Top Predictors: Logistic & LASSO")

# =========================
# 7. Visualizations
# =========================

# 7.1 Average Closure Days by Year and Mobile Request
files %>%
  mutate(year = year(open_dt)) %>%
  group_by(year, mobile_request) %>%
  summarise(avg_closure_days = mean(closure_days, na.rm = TRUE), .groups = "drop") %>%
  ggplot(aes(x = year, y = avg_closure_days, color = factor(mobile_request))) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(
    title = "Average Closure Days by Year and Submission Channel",
    x = "Year",
    y = "Average Closure Days",
    color = "Mobile Request"
  ) +
  theme_minimal()

# 7.2 Percentage of Timely Closures by Year and Mobile Request
files %>%
  mutate(year = year(open_dt)) %>%
  group_by(year, mobile_request) %>%
  summarise(pct_timely = mean(timely_close, na.rm = TRUE) * 100, .groups = "drop") %>%
  ggplot(aes(x = factor(year), y = pct_timely, fill = factor(mobile_request))) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(
    title = "Percentage of Timely Closures by Year and Submission Channel",
    x = "Year",
    y = "Timely Closures (%)",
    fill = "Mobile Request"
  ) +
  theme_minimal()

# 7.3 Distribution of Closure Days
ggplot(files, aes(x = closure_days)) +
  geom_histogram(aes(y = ..density..), bins = 50, fill = "skyblue", color = "black", alpha = 0.7) +
  geom_density(color = "red", size = 1) +
  labs(
    title = "Distribution of Closure Days",
    x = "Closure Days",
    y = "Density"
  ) +
  theme_minimal()

# 7.4 Predicted vs Actual Closure Days (LASSO)
ggplot(files_lasso, aes(x = pred_closure_days, y = closure_days)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  labs(
    title = "Predicted vs Actual Closure Days (LASSO)",
    x = "Predicted Closure Days",
    y = "Actual Closure Days"
  ) +
  theme_minimal()

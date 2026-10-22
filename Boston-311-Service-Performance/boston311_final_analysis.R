
# Boston 311 Service Request Analysis (2015–2019)


# -----------------------------
# 1. Load libraries
# -----------------------------
library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)
library(broom)
library(gt)
library(scales)
library(glmnet)
library(webshot2)

# -----------------------------
# 2. Read & combine data
# -----------------------------
file_paths <- c(
  "Intermediate Analytics/2015 (2).csv",
  "Intermediate Analytics/2016.csv",
  "Intermediate Analytics/2017.csv",
  "Intermediate Analytics/2018.csv",
  "Intermediate Analytics/2019.csv"
)

files <- file_paths %>%
  lapply(read_csv) %>%
  bind_rows() %>%
  rename_all(~tolower(gsub(" ", "_", .)))

# -----------------------------
# 3. Feature engineering
# -----------------------------
files <- files %>%
  mutate(
    open_dt = as.Date(open_dt),
    closed_dt = as.Date(closed_dt),
    year = year(open_dt),
    closure_days = as.numeric(closed_dt - open_dt),
    timely_close = ifelse(!is.na(closure_days) & closure_days <= 7, 1, 0),
    mobile_request = ifelse(
      source %in% c("Citizens Connect App", "Citizens Connect Mobile"),
      "Mobile", "Non-Mobile"
    ),
    post_2017 = ifelse(year >= 2017, 1, 0)
  ) %>%
  filter(year >= 2015 & year <= 2019)

# =====================================================
# DESCRIPTIVE ANALYSIS
# =====================================================

# -----------------------------
# Dataset overview table
# -----------------------------
dataset_overview <- tibble(
  Metric = c("Time Period",
             "Total Requests",
             "Neighborhoods",
             "Departments",
             "Mobile Submissions"),
  Value = c(
    "2015–2019",
    comma(nrow(files)),
    n_distinct(files$neighborhood),
    n_distinct(files$department),
    percent(mean(files$mobile_request == "Mobile"), 0.1)
  )
)

dataset_overview_gt <- dataset_overview %>%
  gt() %>%
  tab_header(title = md("**Boston 311 Dataset Overview**"))

dataset_overview_gt
gtsave(dataset_overview_gt, "dataset_overview.png")

# -----------------------------
# Request volume trend
# -----------------------------
volume_plot <- files %>%
  group_by(year) %>%
  summarise(total_requests = n(), .groups = "drop") %>%
  ggplot(aes(factor(year), total_requests)) +
  geom_col(fill = "#4F81BD") +
  geom_line(aes(group = 1), color = "#1F4E79", linewidth = 1.2) +
  geom_point(color = "#1F4E79", size = 3) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "311 Request Volume (2015–2019)",
    x = "Year",
    y = "Number of Requests"
  ) +
  theme_minimal(base_size = 14)

print(volume_plot)
ggsave("volume_plot.png", volume_plot, 10, 6, dpi = 300)

# =====================================================
# STATISTICAL ANALYSIS
# =====================================================

# -----------------------------
# Chi-square test + plot
# -----------------------------
chi_data <- files %>%
  filter(!is.na(mobile_request)) %>%
  mutate(
    mobile_request = factor(mobile_request),
    timely_close = factor(timely_close,
                          levels = c(0,1),
                          labels = c("Delayed", "Timely"))
  )

chisq.test(table(chi_data$mobile_request, chi_data$timely_close))

chi_plot <- chi_data %>%
  count(mobile_request, timely_close) %>%
  group_by(mobile_request) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ggplot(aes(mobile_request, pct, fill = timely_close)) +
  geom_col() +
  geom_text(
    aes(label = paste0(round(pct,1), "%")),
    position = position_stack(vjust = 0.5),
    color = "white"
  ) +
  scale_fill_manual(values = c("#9DC3E6", "#1F4E79")) +
  labs(
    title = "Timely Closure by Submission Channel",
    x = "Submission Channel",
    y = "Percentage"
  ) +
  theme_minimal(base_size = 14)

print(chi_plot)
ggsave("chi_square_plot.png", chi_plot, 8, 6, dpi = 300)

# -----------------------------
# Logistic regression
# -----------------------------
logit_model <- glm(
  timely_close ~ mobile_request + year + post_2017,
  data = files,
  family = binomial
)

logit_table <- tidy(logit_model) %>%
  mutate(Odds_Ratio = exp(estimate)) %>%
  arrange(desc(abs(estimate))) %>%
  slice(1:6) %>%
  select(term, Odds_Ratio, p.value)

logit_gt <- logit_table %>%
  gt() %>%
  fmt_number(Odds_Ratio, decimals = 3) %>%
  fmt_number(p.value, decimals = 4) %>%
  tab_header(title = "Top Logistic Regression Predictors")

logit_gt
gtsave(logit_gt, "logistic_table.png")

# =====================================================
# LASSO REGRESSION (KEY SLIDE)
# =====================================================

# -----------------------------
# Prepare data for LASSO
# -----------------------------
lasso_data <- files %>%
  select(timely_close, mobile_request, year, post_2017) %>%
  mutate(
    mobile_request = factor(mobile_request),
    timely_close = as.numeric(timely_close)
  ) %>%
  na.omit()

x <- model.matrix(timely_close ~ . , lasso_data)[,-1]
y <- lasso_data$timely_close

# -----------------------------
# Fit LASSO model
# -----------------------------
set.seed(123)

lasso_cv <- cv.glmnet(
  x,
  y,
  alpha = 1,
  family = "binomial"
)

# -----------------------------
# Extract important predictors
# -----------------------------
lasso_data <- files %>%
  select(timely_close, mobile_request, year, post_2017) %>%
  mutate(
    mobile_request = factor(mobile_request),
    timely_close = as.numeric(timely_close)
  ) %>%
  na.omit()

x <- model.matrix(timely_close ~ ., lasso_data)[, -1]
y <- lasso_data$timely_close

set.seed(123)

lasso_cv <- cv.glmnet(
  x,
  y,
  alpha = 1,
  family = "binomial"
)

# ---- Extract coefficients at lambda.1se 
lasso_coef <- coef(lasso_cv, s = "lambda.1se")

lasso_df <- as.data.frame(as.matrix(lasso_coef))
lasso_df$term <- rownames(lasso_df)
colnames(lasso_df)[1] <- "coefficient"

lasso_df <- lasso_df %>%
  filter(term != "(Intercept)", coefficient != 0) %>%
  mutate(Odds_Ratio = exp(coefficient)) %>%
  arrange(desc(abs(coefficient)))

if (nrow(lasso_df) == 0) {
  message("⚠️ LASSO selected no predictors at lambda.1se")
} else {
  
  # ---- LASSO table
  lasso_gt <- lasso_df %>%
    select(term, Odds_Ratio) %>%
    gt() %>%
    fmt_number(Odds_Ratio, decimals = 3) %>%
    tab_header(title = "LASSO-Selected Predictors (Odds Ratios)")
  
  lasso_gt
  gtsave(lasso_gt, "lasso_table.png")
  
  # ---- LASSO plot
  lasso_plot <- ggplot(
    lasso_df,
    aes(x = reorder(term, Odds_Ratio), y = Odds_Ratio)
  ) +
    geom_col(fill = "#1F4E79") +
    coord_flip() +
    labs(
      title = "LASSO: Key Predictors of Timely Closure",
      x = "Predictor",
      y = "Odds Ratio"
    ) +
    theme_minimal(base_size = 14)
  
  print(lasso_plot)
  ggsave("lasso_plot.png", plot = lasso_plot, width = 8, height = 5, dpi = 300)
}

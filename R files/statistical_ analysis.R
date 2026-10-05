#Installing library

library(DBI)
library(RPostgres)
library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(scales)

# Building Dataset

application_customer <- application_customer %>%
  mutate(
    debt_to_revenue = existing_debt_bdt / annual_revenue_bdt,
    requested_to_revenue = requested_amount_bdt / annual_revenue_bdt,
    collateral_coverage = collateral_value_bdt / requested_amount_bdt,
    decision = case_when(
      application_status == "Approved" ~ "Approved",
      application_status == "Rejected" ~  "Rejected",
      TRUE ~ NA_character_
      )
  )

# Descriptive Statistics

application_customer %>%
  summarise(
    mean = mean(debt_to_revenue, na.rm = TRUE),
    median = median(debt_to_revenue, na.rm = TRUE),
    sd = sd(debt_to_revenue, na.rm = TRUE),
    minimum = min(debt_to_revenue, na.rm = TRUE),
    maximum = max(debt_to_revenue, na.rm = TRUE)
  )

# Quartile and IQR for tat days

IQR(
  applications$tat_days,
  na.rm = TRUE
)

# Confidence Interval for approval rate
# Will do proportion test as it is not mean

decided <- application_customer %>%
  filter(
    application_status %in% c("Approved", "Rejected")
  )

approved_n <- sum(decided$application_status == "Approved")

total_decided = nrow(decided)


prop.test(
  x = approved_n,
  n = total_decided
)

# Confidence Interval for mean TAT
# Will do t-test as it is mean

t.test(
  applications$tat_days
)


# T-Test : Do approved and rejected applications differ in Debt_to_Revenue
# First summarise the target Debt_to_Revenue

decided %>%
  group_by(application_status) %>%
  summarise(
    applications = n(),
    mean_debt_to_revenue = mean(debt_to_revenue, na.rm = TRUE),
    median_debt_to_revenue = median(debt_to_revenue, na.rm = TRUE),
    sd_debt_to_revenue = sd(debt_to_revenue, na.rm = TRUE)
  )

# Visualize

ggplot(
  decided,
  aes(
    x = application_status,
    y = debt_to_revenue
  )
) +
  geom_boxplot() +
  labs(
    title = "Debt-to-Revenue by Application Status",
    x = "Decision",
    y = "Debt / Annual Revenue"
  )

# Perform t-test

t.test(
  debt_to_revenue ~ application_status
  ,data = decided
)

# Now look for raw differences

decision_summary <- decided %>%
  group_by(application_status) %>%
  summarise(
    mean_dtr = mean(debt_to_revenue, na.rm = TRUE)
  )

decision_summary

# Chi square test (Test for categories)
# create a contingency table

sector_decision_table <- table(
  decided$business_sector, decided$application_status
)

sector_decision_table

# Then go for the chisq test

chisq.test(
  sector_decision_table
)

# Don't relay on the p value calculate percentage too

sector_decision_rates <- decided %>%
  group_by(
    business_sector,
    application_status
  ) %>%
  summarise(
    n =  n(), .groups = "drop"
  ) %>%
  group_by(business_sector) %>%
  mutate(
    percentage = 100 * n / sum(n)
  )

sector_decision_rates

# Visualize approval rate by sector

sector_approval <- decided %>%
  group_by(business_sector) %>%
  summarise(
    applications = n(),
    approved = sum(application_status == "Approved"),
    approval_rate = 100 * approved / applications
  )

sector_approval

ggplot(
  sector_approval,
  aes(
    x = reorder(
      business_sector,
      approval_rate),
    y = approval_rate
  )
) + geom_col() +
  coord_flip() +
  labs(
    title = "Approval Rate by Business Sector",
    x = "Business Sector",
    y = "Approval Rate (%)"
  )

# Correlation between annual revenuw and request loan amount 

cor.test(
  application_customer$annual_revenue_bdt,
  application_customer$requested_amount_bdt,
  use = "complete.obs"
)

# A scatterplot describe correlation better

ggplot(
  application_customer,
  aes(
    x = annual_revenue_bdt / 1000000,
    y = requested_amount_bdt / 1000000
  )
) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm",
              se = TRUE) +
  labs(
    title = "Revenue and Requested Loan Amount",
    x = "Annual Revenue (Million BDT)",
    y = "Request Loan Amount (Million BDT)"
  )

# T-Test: Do Approved and Rejected applications request different amounts

t.test(
  requested_amount_bdt ~ application_status,
  data = decided
)

ggplot(
  decided,
  aes(x = application_status,
      y = requested_amount_bdt / 1000000)
) + 
  geom_boxplot()

# Mann-Whitney / Wilcox test

wilcox.test(
  requested_amount_bdt ~ application_status,
  data = decided
)

# Logistic Regression

decided <- decided %>%
  mutate(
    approved_flag = if_else(application_status == "Approved", 1,0)
  )

simple_model <- glm(
  approved_flag ~ debt_to_revenue,
  data = decided,
  family = binomial()
)

simple_model


# A complete investigation case of T-Test
# Q1: Is debt burden different between Approved and Rejected applications?
# Q2: Do applications with higher existing debt appear less 
#     likely to recive approval?


# Step 1: Visualize
ggplot(
  decided,
  aes(x = application_status,
      y = debt_to_revenue)
) + 
  geom_boxplot()

# Step 2: Summarize

decided %>%
  group_by(application_status) %>%
  summarise(
    n = n(),
    mean = mean(debt_to_revenue, na.rm = TRUE),
    median = median(debt_to_revenue, na.rm = TRUE),
    sd = sd(debt_to_revenue, na.rm =TRUE)
  )

# T-Test

t.test(
  debt_to_revenue ~ application_status,
  data = decided
)

# Chi-square inestigation
# Q: Does approval rate differ across business sector?

# Step 1: Create table

sector_table <- table(
  decided$business_sector,
  decided$application_status
)

# Step2: chisq test

chisq.test(
  sector_table
)

# Calculate approval rate

decided %>%
  group_by(business_sector) %>%
  summarise(
    applications = n(),
    approved = sum(application_status == "Approved"),
    approval_rate = 100 * approved / applications
  )

# Correlation investigation
# Q: Do larger business request larger financing amounts?

# Step 1: Corr test

cor.test(
  application_customer$annual_revenue_bdt,
  application_customer$requested_amount_bdt,
  use = "complete.obs"
)

# visualize

ggplot(
  application_customer,
  aes(x = annual_revenue_bdt / 1000000,
      y = requested_amount_bdt / 1000000)
) + geom_point(alpha = .40) +
  geom_smooth(model = "lm")

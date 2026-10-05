install.packages(c(
  "DBI",
  "RPostgres",
  "dplyr",
  "ggplot2",
  "tidyr",
  "lubridate",
  "scales",
  "shiny",
  "shinydashboard",
  "DT"
))

library(DBI)
library(RPostgres)
library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(scales)

# connecting database

library(DBI)
library(RPostgres)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "sme_credit_analytics",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "020697"
)

dbListTables(con)

# import all six tables

branches <- dbGetQuery(
  con,
  "SELECT * FROM branches"
)

customers <- dbGetQuery(
  con,
  "SELECT * FROM customers"
)

applications <- dbGetQuery(
  con,
  "SELECT * fROM applications"
)

application_stages <- dbGetQuery(
  con,
  "SELECT * FROM application_stages"
)

loans <- dbGetQuery(
  con,
  "SELECT * FROM loans"
)

repayments <- dbGetQuery(
  con,
  "SELECT * FROM repayments"
)

# Inspect data

head(applications)

str(applications)

library(dplyr)
glimpse(applications)

dim(applications)
nrow(applications)
ncol(applications)

# summary 

summary(applications)

# dpylr

# select
applications %>%
  select(
    application_id,
    requested_amount_bdt,
    application_status
  )

# Filter
applications %>%
  filter( application_status == "Approved")

# combine select and filter
applications %>%
  filter(application_status == "Approved") %>%
  select(
    application_id,
    requested_amount_bdt,
    approved_amount_bdt
  )

# arrange() use to sort data
applications %>%
  arrange(desc(requested_amount_bdt))

# Summarise() use to calculate summary
applications %>%
  summarise(
    avg_requested = mean(requested_amount_bdt, na.rm = TRUE)
  )

# Group By and summarise

applications %>%
  group_by(application_status) %>%
  summarise(
    applications = n()
  )

applications %>%
  group_by(application_status) %>%
  summarise(
    avg_requested_amount = mean(requested_amount_bdt, na.rm = TRUE)
  )

# Mutate() use to create new variable
applications <- applications %>%
  mutate(requested_amount_million = requested_amount_bdt/1000000)

applications %>%
  select(
    requested_amount_bdt,
    requested_amount_million
  )

# Create TAT days

applications <- applications %>%
  mutate(tat_days = as.numeric(decision_date - application_date))


# First EDA question what does requested loan amount look like

applications %>%
  summarise(
    minimum = min(requested_amount_bdt, na.rm = TRUE),
    median = median(requested_amount_bdt, na.rm = TRUE),
    mean = mean(requested_amount_bdt, na.rm = TRUE),
    maximum = max(requested_amount_bdt, na.rm = TRUE)
  )

# Using ggplot for histogram of requested amount

library(ggplot2)

ggplot(
  applications,
  aes(x = requested_amount_million) 
) + 
  geom_histogram(bins = 20) +
  labs(
    title = "Distribution of SME Loan Requests",
    x = "Requested Amount (Million BDT)",
    y = "Number Of Applications"
  )

# Boxplot

ggplot(
  applications,
  aes(y = requested_amount_million)
) + geom_boxplot() + 
  labs(
    title = "SME Requested Loan Amounts",
    y = "Requested Amount (Million BDT)"
  )

# Compare loan amount by business sector

# Joining tables in R

application_customer <- applications %>%
  left_join(
    customers, by = "customer_id"
  )

# Analyze aveage request by sector

application_customer %>%
  group_by(business_sector) %>%
  summarise(
    applications = n(),
    avg_requested_millions = mean(
      requested_amount_bdt, na.rm = TRUE
    ) / 1000000,
    median_requested_million = median(
      requested_amount_bdt, na.rm = TRUE
    ) / 1000000
  ) %>%
  arrange(
    desc(avg_requested_millions)
  )


# visualize sectors

ggplot(
  application_customer,
  aes(x = business_sector,
      y = requested_amount_bdt/1000000)
) +
  geom_boxplot() +
  labs(
    title = "Loan Requests by Business Sectors",
    x = "Business Sectors",
    y = "Requested Amount (Million BDT)"
  ) +
  coord_flip()

# Analyze Appliction Status

status_summary <- applications %>%
  count(application_status) %>%
  mutate(percentage = 100 * n / sum(n))

status_summary

# visualize application status
ggplot(
  status_summary,
  aes(x = application_status,
      y = n)
) +
  geom_col() +
  labs(
    title = "SME Application Status",
    x = 'Application Status',
    y = "Number of Applications"
  )

# Analyze TAT distribution

appli

ggplot(
  applications %>%
    filter(! is.na(tat_days)),
  aes(x = tat_days)
) +
  geom_histogram(bins = 25) +
  labs(
    title = "Distribution Of Application Turnaround Time",
    x = "TAT (Days)",
    y = "Applications"
  )

# Mean Median and percentile TAT

applications %>%
  summarise(
    avg_tat = mean(tat_days, na.rm = TRUE),
  
    median_tat = median(tat_days, na.rm = TRUE),
    
    p75_tat = quantile(tat_days, 0.75, na.rm = TRUE),
    
    p90_tat = quantile(tat_days, 0.90, na.rm = TRUE)
  )

# Compare TAT by branches

application_branch <- applications %>%
  left_join(branches, by = "branch_id")

application_branch %>%
  group_by(branch_name) %>%
  summarise(
    applications = n(),
    
    avg_tat = mean(tat_days, na.rm = TRUE),
    
    median_tat = median(tat_days, na.rm = TRUE)) %>%
  arrange(desc(avg_tat))

# Visualize tat by branch

ggplot(
  application_branch %>%
    filter(!is.na(tat_days)),
  aes(x = branch_name,
      y = tat_days)) +
  geom_boxplot()+
  labs(
    title = "Application TAT By Branches",
    x = "Branch",
    y = "TAT (Days)"
  ) +
  coord_flip()

# Loan portfolio EDA

glimpse(loans)

loans <- loans %>%
  mutate(
    disbursed_million = disbursed_amount_bdt/1000000,
    outstanding_million = outstanding_balance_bdt/1000000
  )

# Analyze loan summary

loan_summary <- loans %>%
  count(current_loan_status)

ggplot(
  loan_summary,
  aes(
    x = current_loan_status,
    y = n
  )) +
  geom_col() +
  labs(
    title = "Current SME Loan Status",
    x = "Loan Status",
    y = "Number of Loans"
  )


loans %>%
  group_by(current_loan_status) %>%
  summarise(
    number_of_loans = n(),
    outstanding_million = sum(outstanding_balance_bdt, na.rm = TRUE)/1000000
  )

# Join loans with customers

loan_customer <- loans %>%
  left_join(customers, by = "customer_id")

# Outstanding portfolio by sectors

sector_portfolio <- loan_customer %>%
  filter(current_loan_status != "Closed") %>%
  group_by(business_sector) %>%
  summarise(
    loans = n(),
    outstanding_bdt = sum(outstanding_balance_bdt, na.rm = TRUE)
  ) %>%
  mutate(
    portfolio_share_pct = 100 * outstanding_bdt /
      sum(outstanding_bdt)
  ) %>%
  arrange(desc(outstanding_bdt))

sector_portfolio

# visualize portfolio concentration

ggplot(
  sector_portfolio,
  aes(
    x = reorder(
      business_sector,
      outstanding_bdt),
    y = outstanding_bdt / 1000000
  )) +
  geom_col() +
  labs(
    title = "Outstanding SME Portfolio By Sectors",
    x = "Business Sector",
    y = "Outstanding Balance (Million BDT)"
  )

# Analyze par30 by sectors

sector_par30 <- loan_customer %>%
  filter(current_loan_status != "Closed") %>%
  group_by(business_sector) %>%
  summarise(
    outstanding = sum(outstanding_balance_bdt,na.rm = TRUE),
    par30_balance = sum(
      outstanding_balance_bdt[days_past_due >= 30], na.rm = TRUE),
    par30_pct = 100 * par30_balance / outstanding
  ) %>%
  arrange(desc(par30_pct))


# Visualize par30

ggplot(
  sector_par30,
  aes(x = reorder(
    business_sector,
    par30_pct),
    y = par30_pct
  )) +
  geom_col()+
  labs(
    title = "PAR30 BY BUSINESS SECTOR",
    x = "Business Sector",
    y = "PAR30 (%)"
  )

# Investigate customer debt

loan_customer <- loan_customer %>%
  mutate(
    debt_to_revenue = existing_debt_bdt /
      annual_revenue_bdt
  )

summary(
  loan_customer$debt_to_revenue
)

# visualize 

ggplot(
  loan_customer,
  aes(
    x = debt_to_revenue)
) + geom_histogram(bins = 30) +
  labs(
    title = "Existing Debt-to-Revenue Distribution",
    x = "Debt/Annual Revenue",
    y = "Brrowers"
  )

# compare debt to revenue with DPD

loan_customer <- loan_customer %>%
  mutate(
    delinquent_30 = if_else(days_past_due >= 30, "30+ DPD","Below 30 DPD")
  )

loan_customer %>%
  group_by(delinquent_30) %>%
  summarise(
    avg_debt_to_revenue = mean(debt_to_revenue, na.rm = TRUE),
    median_debt_to_revenue = median(debt_to_revenue, na.rm = TRUE)
  )

# Visualize the relation 

ggplot(
  loan_customer,
  aes(x = delinquent_30,
      y = debt_to_revenue)) + 
  geom_boxplot() +
  labs(
    title = "Debt-To-Revenue and Delinquency",
    x = "Loan Performance",
    y = "Existing Debt / Annual Revenue"
  )

# Correlation between c annual_revenue  & requested_amount

cor(
  application_customer$annual_revenue_bdt,
  application_customer$requested_amount_bdt,
  use = "complete.obs"
)

# Scatter plot for revenue vs requestd amount

ggplot(
  application_customer,
  aes(x = annual_revenue_bdt / 1000000,
      y = requested_amount_bdt / 1000000
  )) +
  geom_point(alpha = 0.4) +
  labs(
    title = "Annual Revenue vs Requested Loan Amount",
    x = "Annual Revenue (Million BDT)",
    y = "Requested Amount (Million BDT)"
  )

# Combined dataset 

credit_analysis_data <- applications %>%
  left_join(customers, by = "customer_id") %>%
  left_join(branches, by = "branch_id")

# save it to csv

write.csv(
  credit_analysis_data,
  "credit_analysis_data.csv",
  row.names = FALSE
)

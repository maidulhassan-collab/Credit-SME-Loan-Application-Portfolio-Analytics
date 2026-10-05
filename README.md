# Credit-SME Loan Application & Portfolio Analytics

## 📌 Project Overview

![Project Preview](https://github.com/maidulhassan-collab/Credit-SME-Loan-Application-Portfolio-Analytics/blob/main/shiny_dash_gif.gif)

This project presents an end-to-end **Credit-SME analytics solution** developed using **PostgreSQL, R, and R Shiny**.

The project simulates the analytical workflow of an SME lending or credit-risk team by analyzing:

- Loan applications
- Approval and rejection outcomes
- Application processing time
- Branch performance
- Loan disbursement
- Outstanding portfolio exposure
- Delinquency
- PAR30 and PAR90
- Sector concentration
- Borrower financial characteristics

The final output is an **interactive R Shiny management dashboard** that allows users to monitor application activity, operational efficiency, and portfolio risk using branch and business-sector filters.

> **Note:** The dataset used in this project is completely synthetic and was created for learning and portfolio demonstration purposes. It does not contain real customer or institutional data.

---

# 🎯 Business Problem

An SME credit team needs a centralized analytical view of both the **loan application pipeline** and the **existing credit portfolio**.

Management needs to answer questions such as:

- How many SME loan applications are being received?
- What proportion of decided applications are approved?
- How long does the application process take?
- Which processing stages create the longest delays?
- How much financing has been disbursed?
- What is the current outstanding portfolio?
- How much exposure is past due?
- Which sectors or branches show higher delinquency?
- Where is portfolio concentration highest?
- Which loans may require closer monitoring?

This project was designed to transform raw lending data into **management-level KPIs, visualizations, and actionable insights**.

---

# 🎯 Project Objectives

The key objectives of the project were to:

1. Design a relational PostgreSQL database for SME lending data.
2. Perform data-quality validation before analysis.
3. Analyze application volume, approval, rejection, and pending cases.
4. Measure Turnaround Time (TAT) and processing-stage duration.
5. Analyze loan disbursement and outstanding portfolio exposure.
6. Monitor delinquency using Days Past Due (DPD).
7. Calculate portfolio-risk indicators such as PAR30 and PAR90.
8. Compare portfolio performance across branches and business sectors.
9. Perform exploratory and statistical analysis in R.
10. Develop an interactive management dashboard using R Shiny.

---

# 🏦 SME Lending Process

The project follows a simplified SME lending workflow:

```text
SME Customer
     ↓
Loan Application
     ↓
Initial Screening
     ↓
Credit Assessment
     ↓
Risk Review
     ↓
Approval / Rejection
     ↓
Documentation
     ↓
Disbursement
     ↓
Loan Portfolio
     ↓
Repayment Monitoring
     ↓
Delinquency / Portfolio Risk Analysis
```

This allows the project to cover both:

```text
Pre-disbursement analytics
        +
Post-disbursement portfolio analytics
```

---

# 🗃️ Dataset

The synthetic dataset consists of six relational tables.

| Table | Description |
|---|---|
| `branches` | Branch and regional information |
| `customers` | SME borrower characteristics |
| `applications` | SME loan applications and decisions |
| `application_stages` | Application movement through processing stages |
| `loans` | Disbursed SME facilities |
| `repayments` | Installment and repayment records |

### Dataset Size

| Table | Records |
|---|---:|
| Branches | 8 |
| Customers | 1,000 |
| Applications | 1,500 |
| Application Stages | 8,978 |
| Loans | 995 |
| Repayments | 12,218 |

---

# 🔗 Relational Data Model

The main relationships are:

```text
Customers
   │
   └──────── Applications
                    │
                    ├──────── Application Stages
                    │
                    └──────── Loans
                                 │
                                 └──────── Repayments


Branches
   │
   ├──────── Applications
   │
   └──────── Loans
```

### Important Data Grain

Understanding the grain of each table was critical to avoiding duplicate aggregation.

```text
Customers
1 row = 1 customer

Applications
1 row = 1 loan application

Application Stages
1 row = 1 application-stage record

Loans
1 row = 1 disbursed loan

Repayments
1 row = 1 installment/payment record
```

---

# 🛠️ Technology Stack

### Database

- PostgreSQL
- pgAdmin 4

### Data Analysis

- R
- dplyr
- tidyr
- lubridate
- ggplot2
- scales

### Statistical Analysis

- Descriptive statistics
- Confidence intervals
- Welch two-sample t-test
- Chi-square test
- Correlation analysis
- Logistic regression introduction

### Dashboard

- R Shiny
- shinydashboard
- DT

### Database Connection

- DBI
- RPostgres

---

# 🔄 Project Workflow

```text
Synthetic SME Lending Data
            ↓
PostgreSQL Database
            ↓
Data Quality Validation
            ↓
SQL Business Analysis
            ↓
Credit-SME KPI Development
            ↓
Advanced SQL Analysis
            ↓
R Exploratory Data Analysis
            ↓
Statistical Analysis
            ↓
R Shiny Dashboard
            ↓
Business Insights
            ↓
Management Recommendations
```

---

# 🧹 Data Quality Assessment

Before calculating business KPIs, several data-quality checks were performed.

The validation framework covered:

### Uniqueness

- Duplicate Customer IDs
- Duplicate Application IDs

### Completeness

- Missing business-sector information
- Missing revenue values
- Missing decision dates
- Missing processing-stage information

### Validity

- Negative loan amounts
- Negative outstanding balances
- Invalid Days Past Due
- Invalid revenue values

### Consistency

Examples checked included:

```text
Decision Date < Application Date
```

```text
Stage End Date < Stage Start Date
```

```text
Outstanding Balance > Disbursed Amount
```

```text
Rejected Application → Disbursed Loan
```

```text
Paid On Time + Days Late > 0
```

The purpose of these checks was to ensure that:

> Correct SQL calculations were not being applied to incorrect or inconsistent data.

---

# 🧮 PostgreSQL Analysis

PostgreSQL was used for:

- Data storage
- Relational database design
- Primary and foreign keys
- JOIN operations
- Data-quality validation
- Business KPI calculation
- Advanced analytical queries

Important SQL concepts used in the project include:

```sql
JOIN
LEFT JOIN
GROUP BY
HAVING
CASE WHEN
CTE
FILTER
DATE_TRUNC()
LAG()
ROW_NUMBER()
RANK()
Window Functions
PERCENTILE_CONT()
```

---

# 📊 Key Credit-SME KPIs

The project produced the following management KPIs.

| KPI | Result |
|---|---:|
| Total Applications | 1,500 |
| Approved Applications | 1,004 |
| Rejected Applications | 394 |
| Pending Applications | 7 |
| Withdrawn Applications | 95 |
| Approval Rate | 71.8% |
| Median TAT | 15 days |
| Average TAT | ~14.1 days |
| Total Loans | 995 |
| Total Disbursement | ~BDT 4.108 Billion |
| Average Loan Size | ~BDT 4.13 Million |
| Active Outstanding Portfolio | ~BDT 1.341 Billion |
| PAR30 | 45.1% |
| PAR90 | ~12.35% |

> Approval Rate is calculated as:

```text
Approved
------------------------- × 100
Approved + Rejected
```

Pending and withdrawn applications are excluded from this KPI definition.

---

# ⏱️ Turnaround Time Analysis

Turnaround Time was calculated as:

```text
TAT = Decision Date - Application Date
```

Both mean and median TAT were analyzed because lending-process durations can contain unusually slow applications.

The project also analyzed processing-stage duration.

One important finding from the synthetic portfolio was that **Credit Assessment had the longest average processing duration**, at approximately:

```text
4.45 days
```

followed by Documentation at approximately:

```text
3.53 days
```

This suggests that stage-level analysis can provide more actionable information than overall TAT alone.

---

# 📅 Monthly Application Trend

Monthly application volumes were analyzed using:

```sql
DATE_TRUNC('month', application_date)
```

Advanced analysis also included:

- Month-over-month application growth
- Previous-month comparison using `LAG()`
- Rolling three-month averages

These techniques help management distinguish short-term fluctuations from broader trends.

---

# ⏳ Pending Application Aging

Pending applications were analyzed based on how long they had remained unresolved.

Example aging groups included:

```text
0–3 Days
4–7 Days
8–14 Days
15+ Days
```

The latest processing stage for each application was identified using:

```sql
ROW_NUMBER()
OVER (
    PARTITION BY application_id
    ORDER BY stage_order DESC
)
```

This makes it possible to identify both:

```text
How old is the application?
```

and:

```text
Where is it currently waiting?
```

---

# 💳 Portfolio Risk Analysis

The post-disbursement analysis focused on:

- Outstanding exposure
- DPD distribution
- PAR30
- PAR90
- Sector concentration
- Branch concentration
- Early-warning indicators

---

# 📌 Days Past Due (DPD)

Loans were grouped into simplified delinquency buckets:

```text
Current
1–30 DPD
31–60 DPD
61–90 DPD
90+ DPD
```

The project analyzed both:

```text
Number of loans
```

and:

```text
Outstanding financial exposure
```

because a small number of large delinquent loans may create more portfolio risk than many small loans.

---

# ⚠️ PAR30

For this project:

```text
PAR30 =
Outstanding Balance of Active Loans with DPD ≥ 30
-------------------------------------------------
Total Active Outstanding Portfolio
```

The synthetic portfolio produced:

```text
PAR30 ≈ 45.1%
```

This value is specific to the synthetic training dataset and should not be interpreted as a real institutional benchmark.

---

# 🚨 PAR90

Similarly:

```text
PAR90 =
Outstanding Balance of Active Loans with DPD ≥ 90
-------------------------------------------------
Total Active Outstanding Portfolio
```

The project produced approximately:

```text
PAR90 ≈ 12.35%
```

PAR90 represents more severe repayment deterioration than PAR30.

---

# 🏭 Sector Portfolio Analysis

Outstanding exposure was analyzed across SME business sectors.

Two separate concepts were considered:

### Portfolio Exposure

```text
How much money is outstanding in the sector?
```

### Portfolio Risk Rate

```text
What proportion of that sector's outstanding balance
is delinquent?
```

These metrics should not be interpreted interchangeably.

A sector may have:

```text
High outstanding exposure
+
Moderate PAR30
```

while another may have:

```text
Low exposure
+
High PAR30
```

Both situations may require different management responses.

---

# 🔍 Early-Warning Monitoring

A simplified rule-based watchlist was created using borrower and loan characteristics.

Example rules included:

```text
DPD ≥ 90
→ High Alert
```

and:

```text
DPD ≥ 30
OR
Previous Default = 1
OR
High Debt-to-Revenue
→ Watch
```

This was designed as a transparent monitoring framework rather than a predictive credit-scoring model.

Predictive credit-risk modeling is planned as a future extension.

---

# 📈 R Exploratory Data Analysis

R was used to investigate:

- Requested-loan distributions
- Loan-size outliers
- Business-sector differences
- TAT distribution
- Branch-level TAT
- Portfolio concentration
- DPD exposure
- PAR30 by sector
- Borrower financial characteristics

Important packages included:

```r
dplyr
ggplot2
tidyr
lubridate
scales
```

---

# 📊 Requested Loan Amount Analysis

Loan-request distributions were examined using:

- Mean
- Median
- Minimum
- Maximum
- Histograms
- Boxplots

The analysis emphasized that:

```text
Outlier ≠ Error
```

Large SME financing requests may represent legitimate larger businesses and should be investigated before being removed.

---

# 📐 Financial Ratio Engineering

Several borrower-level analytical variables were created.

### Debt-to-Revenue

```text
Existing Debt
-------------
Annual Revenue
```

### Requested-to-Revenue

```text
Requested Loan Amount
---------------------
Annual Revenue
```

### Collateral Coverage

```text
Collateral Value
----------------
Requested Loan Amount
```

Ratios help compare companies of different sizes more fairly than absolute values alone.

---

# 📊 Statistical Analysis

The project also introduced inferential statistics to move beyond descriptive analysis.

Methods included:

### Welch Two-Sample t-test

Used to investigate whether numerical borrower characteristics differed across application outcomes.

Example question:

```text
Does Debt-to-Revenue differ between
Approved and Rejected applications?
```

### Chi-Square Test

Used to investigate associations between categorical variables.

Example:

```text
Is application decision associated with business sector?
```

### Correlation Analysis

Used to investigate relationships such as:

```text
Annual Revenue
vs
Requested Loan Amount
```

The analysis followed the principle:

```text
Correlation ≠ Causation
```

and statistical significance was interpreted together with practical/business significance.

---

# 📊 R Shiny Management Dashboard

The final analytical output is an interactive **R Shiny dashboard**.

The dashboard contains four main sections:

```text
SME Credit Analytics
│
├── Executive Overview
│
├── Applications
│
├── Processing & TAT
│
└── Portfolio Risk
```

---

# 🎛️ Interactive Filters

Users can filter the dashboard by:

```text
Branch
```

and:

```text
Business Sector
```

The KPIs, charts, and tables update automatically using Shiny's reactive programming framework.

Conceptually:

```text
User Selection
      ↓
Shiny Input
      ↓
Reactive Dataset
      ↓
KPI Calculations
      ↓
Charts + Tables
      ↓
Updated Dashboard
```

---

# 🖥️ Executive Overview

The Executive Overview includes:

- Total Applications
- Approval Rate
- Median TAT
- Total Disbursement
- Active Outstanding Portfolio
- PAR30
- Application Status
- Monthly Application Trend

![Executive Overview](https://github.com/maidulhassan-collab/Credit-SME-Loan-Application-Portfolio-Analytics/blob/main/screenplay/exe_dash_gif.gif)

---

# 📑 Applications Dashboard

The Applications page contains analysis such as:

- Applications by loan purpose
- Requested loan amount distribution
- Branch application summary

![Applications Dashboard](https://github.com/maidulhassan-collab/Credit-SME-Loan-Application-Portfolio-Analytics/blob/main/screenplay/app_dash_gif.gif)

---

# ⏱️ Processing & TAT Dashboard

The processing page includes:

- Turnaround Time by Branch
- Average Processing Time by Stage
- Application Stage Summary

![Processing and TAT](https://github.com/maidulhassan-collab/Credit-SME-Loan-Application-Portfolio-Analytics/blob/main/screenplay/pro_dash_gif.gif)

---

# ⚠️ Portfolio Risk Dashboard

The portfolio page provides:

- DPD analysis
- Outstanding exposure
- PAR30 by sector
- Portfolio details

![Portfolio Risk](https://github.com/maidulhassan-collab/Credit-SME-Loan-Application-Portfolio-Analytics/blob/main/screenplay/folio_dash_gif.gif)

---

# 🔎 Selected Project Findings

Several analytical findings emerged from the synthetic portfolio.

### 1. Application Decisions

Among decided applications, approximately:

```text
71.8%
```

were approved.

This KPI should be monitored together with application mix, borrower characteristics, and credit quality rather than interpreted as a standalone measure of branch performance.

---

### 2. Application Processing

The portfolio showed:

```text
Median TAT = 15 days
```

while:

```text
Average TAT ≈ 14.1 days
```

Stage-level analysis showed that **Credit Assessment** had the longest average duration.

This suggests that operational analysis should investigate stage-level workflow rather than relying only on overall TAT.

---

### 3. Portfolio Exposure

The project contained approximately:

```text
BDT 1.341 Billion
```

in active outstanding SME exposure.

Portfolio analysis therefore considered both:

```text
Exposure amount
```

and:

```text
Risk rate
```

when evaluating sectors and branches.

---

### 4. Portfolio Delinquency

The synthetic portfolio produced approximately:

```text
PAR30 = 45.1%
```

and:

```text
PAR90 = 12.35%
```

The gap between PAR30 and PAR90 suggests that delinquency severity should be examined across multiple DPD buckets rather than summarized with a single risk indicator.

---

### 5. Sector Risk

Sector-level analysis showed that portfolio exposure and delinquency rates vary across business sectors.

A sector with high PAR30 should not automatically be classified as unsuitable for lending.

Further analysis should determine whether the result is driven by:

- A small number of large loans
- Broad borrower deterioration
- Portfolio concentration
- Loan maturity
- Geographic concentration
- Borrower financial characteristics

---

# 💡 Business Recommendations

Based on the analytical framework, the following actions are recommended.

### Processing Efficiency

Monitor both median TAT and stage-level duration.

Where delays are identified:

```text
Overall TAT
    ↓
Branch
    ↓
Processing Stage
    ↓
Individual Applications
```

This creates a more actionable operational investigation process.

---

### Portfolio Monitoring

Management should monitor:

```text
PAR30
PAR90
DPD buckets
Outstanding exposure
```

together rather than relying on one delinquency indicator.

---

### Sector Monitoring

Portfolio concentration and portfolio risk should be monitored separately.

A sector with:

```text
High exposure
```

may require concentration management even when delinquency is moderate.

A sector with:

```text
High PAR30
```

may require deeper borrower-level investigation even when total exposure is small.

---

### Early Warning

The rule-based monitoring approach can be expanded into a predictive early-warning system using:

- Borrower characteristics
- Previous repayment behavior
- Financial ratios
- DPD migration
- Historical default outcomes

---

# ⚠️ Limitations

This project has several important limitations.

1. The dataset is synthetic.
2. Results do not represent any actual financial institution.
3. PAR definitions are simplified for training purposes.
4. The project does not include macroeconomic variables.
5. Borrower financial statements are simplified.
6. Causal conclusions cannot be drawn from the observational analysis.
7. The rule-based watchlist is not a validated credit-risk model.

The primary purpose of the project is to demonstrate the complete analytics workflow.

---

# 🚀 Future Development

The next stage of this work is a dedicated **SME Credit Risk Scoring & Default Prediction Project**.

Planned areas include:

```text
Probability of Default
Logistic Regression
Weight of Evidence (WoE)
Information Value (IV)
Credit Scorecards
Random Forest
XGBoost
ROC-AUC
KS Statistic
Gini Coefficient
Risk Grades
Model Calibration
Population Stability Index
Model Monitoring
```

This would extend the current project from:

```text
Descriptive + Diagnostic Analytics
```

toward:

```text
Predictive Credit Risk Analytics
```

---

# 📁 Recommended Repository Structure

```text
credit-sme-loan-analytics/
│
├── README.md
│
├── app.R
│
├── renv.lock
│
├── .gitignore
│
│
├── data/
│   ├── branches.csv
│   ├── customers.csv
│   ├── applications.csv
│   ├── application_stages.csv
│   ├── loans.csv
│   ├── repayments.csv
│   └── data_dictionary.xlsx
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_data_quality.sql
│   ├── 03_application_analysis.sql
│   ├── 04_advanced_analysis.sql
│   └── 05_portfolio_kpis.sql
│
├── analysis/
│   ├── exploratory_data_analysis.R
│   └── statistical_analysis.R
│
├── assets/
│   ├── dashboard_overview.png
│   ├── dashboard_applications.png
│   ├── dashboard_processing.png
│   ├── dashboard_portfolio_par30.png
│   ├── data_model.png
│   └── workflow.png
│
└── docs/
    └── SME_Credit_Analytics_Project_Report.pdf
```

---

# ▶️ How to Run the Project

## 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/credit-sme-loan-analytics.git
```

Move into the repository:

```bash
cd credit-sme-loan-analytics
```

---

## 2. Create the PostgreSQL Database

Create a database named:

```text
sme_credit_analytics
```

Then run the SQL table-creation script:

```text
sql/01_create_tables.sql
```

Import the CSV files in this order:

```text
branches
customers
applications
application_stages
loans
repayments
```

The order is important because of foreign-key relationships.

---

## 3. Install Required R Packages

Run this once:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "DBI",
  "RPostgres",
  "dplyr",
  "ggplot2",
  "tidyr",
  "lubridate",
  "scales",
  "DT"
))
```

---

## 4. Configure PostgreSQL Password

Do **not** place the database password directly inside `app.R`.

Open the R environment configuration:

```r
file.edit("~/.Renviron")
```

Add:

```text
PGPASSWORD=your_postgresql_password
```

Restart RStudio.

The application can then access the password using:

```r
Sys.getenv("PGPASSWORD")
```

---

## 5. Run the Shiny Dashboard

Open:

```text
shiny.R
```

and click:

```text
Run App
```

The dashboard should open locally in the browser.

---

# 🔐 Security

Database passwords and confidential credentials must never be committed to GitHub.

The project should use:

```r
Sys.getenv("PGPASSWORD")
```

instead of hard-coded credentials.

The `.Renviron` file should also be excluded using `.gitignore`.

Example:

```text
.Renviron
.Rhistory
.RData
.Ruserdata
```

---

# 📦 Reproducibility

For improved reproducibility, the project can use:

```r
renv
```

Initialize:

```r
install.packages("renv")
renv::init()
```

Save package versions:

```r
renv::snapshot()
```

Other users can reproduce the package environment using:

```r
renv::restore()
```

---

# 📄 Full Project Report

A detailed project report covering the methodology, SQL analysis, R analysis, statistics, dashboard development, findings, recommendations, and limitations is available in:


[**Project Report**](https://github.com/maidulhassan-collab/Credit-SME-Loan-Application-Portfolio-Analytics/blob/main/SME_Credit_Analytics_Project_Report.pdf)

## **A Small Presentation on the project**

[**Presentation**](https://github.com/maidulhassan-collab/Credit-SME-Loan-Application-Portfolio-Analytics/blob/main/Credit_SME_Analytics_Presentation.pptx)


---

# 🎓 Skills Demonstrated

This project demonstrates practical experience in:

- PostgreSQL
- SQL
- Relational database design
- Data-quality validation
- Advanced SQL
- R
- dplyr
- ggplot2
- Statistical analysis
- R Shiny
- Interactive dashboards
- Credit-SME analytics
- Portfolio-risk monitoring
- Business KPI development
- Analytical communication

---

# 👤 Author

**Md. Maidul Hassan Shanto**

Data Analyst | Credit Analytics | SQL | R | R Shiny

**LinkedIn:**  
`www.linkedin.com/in/maidulhassan`

**GitHub:**  
`https://github.com/maidulhassan-collab`

**Email:**  
`maidulhassan116.com`

---

# ⭐ Project Summary

This project demonstrates how raw SME lending data can be transformed into a complete analytical solution using:

```text
PostgreSQL
      ↓
SQL Analysis
      ↓
R
      ↓
Statistics
      ↓
R Shiny
      ↓
Management Decision Support
```

The main focus was not simply to create visualizations, but to connect **data engineering, statistical analysis, credit-domain knowledge, and interactive reporting** into one end-to-end analytics workflow.

# Libraries

library(DBI)
library(RPostgres)
library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(scales)
library(shiny)
library(shinydashboard)
library(DT)

# Before building shiny data preparation

# Connecting with Postgres

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "sme_credit_analytics",
  host = "localhost",
  port = 5432,
  user ="postgres",
  password = "020697"
)

# loading tables

branches <- dbReadTable(
  con,
  "branches"
)

customers <- dbReadTable(
  con,
  "customers"
)

applications <- dbReadTable(
  con,
  "applications"
)

application_stages <- dbReadTable(
  con,
  "application_stages"
)

loans <- dbReadTable(
  con,
  "loans"
)

# Disconnecting database connection as we have load our tables

dbDisconnect(con)

# Prepare application level data

app_data <- applications %>%
  left_join(
    customers %>%
      select(
        customer_id,
        business_sector,
        business_name,
        annual_revenue_bdt,
        business_age_years,
        existing_debt_bdt,
        previous_default_flag
      ), by = "customer_id"
  ) %>%
  left_join(
    branches %>%
      select(
        branch_id,
        branch_name,
        region
      ), by = "branch_id"
  ) %>%
  mutate(
    
    # Convert dates properly
    application_date = as.Date(application_date),
    decision_date = as.Date(decision_date),
    
    # Turnaround Time
    tat_days = as.numeric(decision_date - application_date),
    
    # Requested amount in millions
    requested_amount_million = requested_amount_bdt / 1000000,
    
    # Debt-To_Revenue ratio
    debt_to_revenue = existing_debt_bdt / annual_revenue_bdt
  )

app_data

# Prepare loan level data

loan_data <- loans %>%
  left_join(
    customers %>%
      select(
        customer_id,
        business_sector,
        business_name,
        annual_revenue_bdt,
        existing_debt_bdt,
        previous_default_flag
      ), by = "customer_id"
  ) %>%
  left_join(
    branches %>%
      select(
        branch_id,
        branch_name,
        district,
        region
      ), by = "branch_id"
  ) %>%
  mutate(
    disbursed_million = disbursed_amount_bdt / 1000000,
    
    outstanding_million = outstanding_balance_bdt / 1000000,
  )

loan_data

# Prepare Stage level data

stage_data <- application_stages %>%
  left_join(
    app_data %>%
      select(
        application_id,
        branch_name,
        business_name,
        business_sector
      ), by = "application_id"
  )

stage_data

# Helper Function
# Helps to avoid error and filter usable data

safe_median <- function(x) {
  x <- x[!is.na(x)]
  if(length(x) == 0){
    return(NA_real_)
  }
  median(x)
}

safe_percent <- function(numerator, denominator){
  if(
    is.na(denominator) || denominator == 0
  ) {
    return(NA_real_)
  }
  100 * 
    numerator /
    denominator
}

# User Interface UI

ui <- dashboardPage(
  
  # HEADER 
  
  dashboardHeader(
    
    title = "SME Credit Analytics"
    
  ),
  
  # SIDEBAR-
  
  dashboardSidebar(
    
    
    # Branch filter
    
    selectInput(
      
      inputId = "branch",
      
      label = "Branch",
      
      choices = c(
        
        "All",
        
        sort(
          
          unique(
            app_data$branch_name
          )
          
        )
        
      ),
      
      selected = "All"
      
    ),
    
    
    
    # Sector filter
    
    selectInput(
      
      inputId = "sector",
      
      label = "Business Sector",
      
      choices = c(
        
        "All",
        
        sort(
          
          unique(
            app_data$business_sector
          )
          
        )
        
      ),
      
      selected = "All"
      
    ),
    
    
    
    # Dashboard menu
    
    sidebarMenu(
      
      
      menuItem(
        
        "Executive Overview",
        
        tabName = "overview",
        
        icon = icon("chart-line")
        
      ),
      
      
      menuItem(
        
        "Applications",
        
        tabName = "applications",
        
        icon = icon("file")
        
      ),
      
      
      menuItem(
        
        "Processing & TAT",
        
        tabName = "processing",
        
        icon = icon("clock")
        
      ),
      
      
      menuItem(
        
        "Portfolio Risk",
        
        tabName = "portfolio",
        
        icon = icon("triangle-exclamation")
        
      )
      
    )
    
  ),
  
  # DASHBOARD BODY
  
  
  dashboardBody(
    
    
    tabItems(
      
      
      
      # TAB 1 - EXECUTIVE OVERVIEW
      
      
      tabItem(
        
        tabName = "overview",
        
        
        fluidRow(
          
          
          valueBoxOutput(
            
            "total_applications",
            
            width = 4
            
          ),
          
          
          valueBoxOutput(
            
            "approval_rate",
            
            width = 4
            
          ),
          
          
          valueBoxOutput(
            
            "median_tat",
            
            width = 4
            
          )
          
        ),
        
        
        
        fluidRow(
          
          
          valueBoxOutput(
            
            "total_disbursement",
            
            width = 4
            
          ),
          
          
          valueBoxOutput(
            
            "outstanding",
            
            width = 4
            
          ),
          
          
          valueBoxOutput(
            
            "par30",
            
            width = 4
            
          )
          
        ),
        
        
        
        fluidRow(
          
          
          box(
            
            title = "Application Status",
            
            width = 6,
            
            plotOutput(
              
              "application_status_plot"
              
            )
            
          ),
          
          
          
          box(
            
            title = "Monthly Application Trend",
            
            width = 6,
            
            plotOutput(
              
              "monthly_applications_plot"
              
            )
            
          )
          
        ),
        
        
        
        fluidRow(
          
          
          box(
            
            title = "Outstanding Portfolio by Sector",
            
            width = 6,
            
            plotOutput(
              
              "sector_portfolio_plot"
              
            )
            
          ),
          
          
          
          box(
            
            title = "Outstanding Exposure by DPD",
            
            width = 6,
            
            plotOutput(
              
              "dpd_exposure_plot"
              
            )
            
          )
          
        )
        
      ),
      
      
      
      
      # TAB 2 - APPLICATIONS
      
      
      tabItem(
        
        tabName = "applications",
        
        
        fluidRow(
          
          
          box(
            
            title = "Applications by Loan Purpose",
            
            width = 6,
            
            plotOutput(
              
              "loan_purpose_plot"
              
            )
            
          ),
          
          
          
          box(
            
            title = "Requested Loan Amount Distribution",
            
            width = 6,
            
            plotOutput(
              
              "requested_amount_plot"
              
            )
            
          )
          
        ),
        
        
        
        fluidRow(
          
          
          box(
            
            title = "Branch Application Summary",
            
            width = 12,
            
            DTOutput(
              
              "branch_table"
              
            )
            
          )
          
        )
        
      ),
      
      
      # TAB 3 - PROCESSING & TAT
      
      
      tabItem(
        
        tabName = "processing",
        
        
        fluidRow(
          
          
          box(
            
            title = "Turnaround Time by Branch",
            
            width = 6,
            
            plotOutput(
              
              "tat_branch_plot"
              
            )
            
          ),
          
          
          
          box(
            
            title = "Average Processing Time by Stage",
            
            width = 6,
            
            plotOutput(
              
              "stage_duration_plot"
              
            )
            
          )
          
        ),
        
        
        
        fluidRow(
          
          
          box(
            
            title = "Application Stage Summary",
            
            width = 12,
            
            DTOutput(
              
              "stage_table"
              
            )
            
          )
          
        )
        
      ),
      
      
      
      # TAB 4 - PORTFOLIO RISK
      
      
      tabItem(
        
        tabName = "portfolio",
        
        
        fluidRow(
          
          
          box(
            
            title = "Loan Count by DPD Bucket",
            
            width = 6,
            
            plotOutput(
              
              "dpd_count_plot"
              
            )
            
          ),
          
          
          
          box(
            
            title = "Outstanding Exposure by DPD",
            
            width = 6,
            
            plotOutput(
              
              "portfolio_dpd_exposure_plot"
              
            )
            
          )
          
        ),
        
        
        
        fluidRow(
          
          
          box(
            
            title = "PAR30 by Business Sector",
            
            width = 12,
            
            plotOutput(
              
              "sector_par30_plot"
              
            )
            
          )
          
        ),
        
        
        
        fluidRow(
          
          
          box(
            
            title = "Loan Portfolio Detail",
            
            width = 12,
            
            DTOutput(
              
              "loan_table"
              
            )
            
          )
          
        )
        
      )
      
    )
    
  )
  
)

# Server

server <- function(
    input,
    output,
    session
) {
  
  # FILTER APPLICATION DATA
  
  filtered_apps <- reactive({
    
    
    data <- app_data
    
    
    # Apply branch filter
    
    if (
      input$branch != "All"
    ) {
      
      data <- data %>%
        
        filter(
          
          branch_name ==
            input$branch
          
        )
      
    }
    
    
    # Apply sector filter
    
    if (
      input$sector != "All"
    ) {
      
      data <- data %>%
        
        filter(
          
          business_sector ==
            input$sector
          
        )
      
    }
    
    
    data
    
  })
  
  
  # FILTER LOAN DATA
  
  filtered_loans <- reactive({
    
    
    data <- loan_data
    
    
    if (
      input$branch != "All"
    ) {
      
      data <- data %>%
        
        filter(
          
          branch_name ==
            input$branch
          
        )
      
    }
    
    
    if (
      input$sector != "All"
    ) {
      
      data <- data %>%
        
        filter(
          
          business_sector ==
            input$sector
          
        )
      
    }
    
    
    data
    
  })
  
  # FILTER STAGE DATA
  
  filtered_stages <- reactive({
    
    
    data <- stage_data
    
    
    if (
      input$branch != "All"
    ) {
      
      data <- data %>%
        
        filter(
          
          branch_name ==
            input$branch
          
        )
      
    }
    
    
    if (
      input$sector != "All"
    ) {
      
      data <- data %>%
        
        filter(
          
          business_sector ==
            input$sector
          
        )
      
    }
    
    
    data
    
  })
  
  # EXECUTIVE KPI 1: TOTAL APPLICATIONS

  output$total_applications <- renderValueBox({
    
    
    total <- nrow(
      
      filtered_apps()
      
    )
    
    
    valueBox(
      
      value = comma(total),
      
      subtitle = "Total Applications",
      
      icon = icon("file"),
      
      color = "blue"
      
    )
    
  })
  
  # EXECUTIVE KPI 2: APPROVAL RATE
  
  output$approval_rate <- renderValueBox({
    
    
    data <- filtered_apps()
    
    
    decided <- data %>%
      
      filter(
        
        application_status %in%
          c(
            "Approved",
            "Rejected"
          )
        
      )
    
    
    approved <- sum(
      
      decided$application_status ==
        "Approved"
      
    )
    
    
    rate <- safe_percent(
      
      approved,
      
      nrow(decided)
      
    )
    
    
    valueBox(
      
      value =
        
        ifelse(
          
          is.na(rate),
          
          "N/A",
          
          paste0(
            round(rate, 1),
            "%"
          )
          
        ),
      
      subtitle = "Approval Rate",
      
      icon = icon("circle-check"),
      
      color = "green"
      
    )
    
  })
  

  # EXECUTIVE KPI 3: MEDIAN TAT
  
  output$median_tat <- renderValueBox({
    
    
    med <- safe_median(
      
      filtered_apps()$
        tat_days
      
    )
    
    
    valueBox(
      
      value =
        
        ifelse(
          
          is.na(med),
          
          "N/A",
          
          paste0(
            round(med, 1),
            " days"
          )
          
        ),
      
      subtitle = "Median TAT",
      
      icon = icon("clock"),
      
      color = "yellow"
      
    )
    
  })
  
  # EXECUTIVE KPI 4: TOTAL DISBURSEMENT
  
  output$total_disbursement <- renderValueBox({
    
    
    total <- sum(
      
      filtered_loans()$
        disbursed_amount_bdt,
      
      na.rm = TRUE
      
    )
    
    
    valueBox(
      
      value = paste0(
        
        "৳",
        
        comma(
          
          round(
            total / 1000000,
            1
          )
          
        ),
        
        "M"
        
      ),
      
      subtitle = "Total Disbursement",
      
      icon = icon("money-bill"),
      
      color = "aqua"
      
    )
    
  })
  
  # EXECUTIVE KPI 5: ACTIVE OUTSTANDING
  
  output$outstanding <- renderValueBox({
    
    
    active <- filtered_loans() %>%
      
      filter(
        
        current_loan_status !=
          "Closed"
        
      )
    
    
    total <- sum(
      
      active$
        outstanding_balance_bdt,
      
      na.rm = TRUE
      
    )
    
    
    valueBox(
      
      value = paste0(
        
        "৳",
        
        comma(
          
          round(
            total / 1000000,
            1
          )
          
        ),
        
        "M"
        
      ),
      
      subtitle = "Active Outstanding",
      
      icon = icon("wallet"),
      
      color = "purple"
      
    )
    
  })
  
  # EXECUTIVE KPI 6: PAR30
  
  output$par30 <- renderValueBox({
    
    
    active <- filtered_loans() %>%
      
      filter(
        
        current_loan_status !=
          "Closed"
        
      )
    
    
    total_outstanding <- sum(
      
      active$
        outstanding_balance_bdt,
      
      na.rm = TRUE
      
    )
    
    
    par30_balance <- sum(
      
      active$
        outstanding_balance_bdt[
          active$days_past_due >= 30
        ],
      
      na.rm = TRUE
      
    )
    
    
    par30_rate <- safe_percent(
      
      par30_balance,
      
      total_outstanding
      
    )
    
    
    valueBox(
      
      value =
        
        ifelse(
          
          is.na(par30_rate),
          
          "N/A",
          
          paste0(
            
            round(
              par30_rate,
              1
            ),
            
            "%"
            
          )
          
        ),
      
      subtitle = "PAR30",
      
      icon = icon("triangle-exclamation"),
      
      color = "red"
      
    )
    
  })
  
  # APPLICATION STATUS CHART
  
  output$application_status_plot <- renderPlot({
    
    
    status_data <- filtered_apps() %>%
      
      count(
        
        application_status
        
      )
    
    
    ggplot(
      
      status_data,
      
      aes(
        
        x = application_status,
        
        y = n
        
      )
      
    ) +
      
      geom_col() +
      
      labs(
        
        x = NULL,
        
        y = "Applications"
        
      ) +
      
      theme_minimal()
    
  })
  
  # MONTHLY APPLICATION TREND
  
  output$monthly_applications_plot <- renderPlot({
    
    # Take the filtered application data
    data <- filtered_apps()
    
    
    # Make sure application_date is a real Date
    data$application_date <- as.Date(
      data$application_date
    )
    
    
    # Remove rows where application date is missing
    data <- data %>%
      filter(
        !is.na(application_date)
      )
    
    
    # Create Year-Month variable
    monthly_data <- data %>%
      
      mutate(
        
        month = format(
          application_date,
          "%Y-%m"
        )
        
      ) %>%
      
      group_by(month) %>%
      
      summarise(
        
        applications = n(),
        
        .groups = "drop"
        
      ) %>%
      
      arrange(month)
    
    
    # Check that data actually exists
    validate(
      
      need(
        nrow(monthly_data) > 0,
        "No monthly application data available."
      )
      
    )
    
    
    # Draw chart
    ggplot(
      monthly_data,
      aes(
        x = month,
        y = applications,
        group = 1
      )
    ) +
      
      geom_line(
        linewidth = 1
      ) +
      
      geom_point(
        size = 2
      ) +
      
      labs(
        x = "Month",
        y = "Applications"
      ) +
      
      theme_minimal() +
      
      theme(
        
        axis.text.x = element_text(
          angle = 45,
          hjust = 1
        )
        
      )
    
  })
  
  
  # OUTSTANDING PORTFOLIO BY SECTOR
  
  output$sector_portfolio_plot <- renderPlot({
    
    
    sector_data <- filtered_loans() %>%
      
      filter(
        
        current_loan_status !=
          "Closed"
        
      ) %>%
      
      group_by(
        
        business_sector
        
      ) %>%
      
      summarise(
        
        outstanding = sum(
          
          outstanding_balance_bdt,
          
          na.rm = TRUE
          
        ),
        
        .groups = "drop"
        
      )
    
    
    ggplot(
      
      sector_data,
      
      aes(
        
        x = reorder(
          
          business_sector,
          
          outstanding
          
        ),
        
        y =
          outstanding /
          1000000
        
      )
      
    ) +
      
      geom_col() +
      
      coord_flip() +
      
      labs(
        
        x = NULL,
        
        y =
          "Outstanding (Million BDT)"
        
      ) +
      
      theme_minimal()
    
  })
  
  # EXECUTIVE DPD EXPOSURE
  
  output$dpd_exposure_plot <- renderPlot({
    
    
    data <- filtered_loans() %>%
      
      filter(
        
        current_loan_status !=
          "Closed"
        
      ) %>%
      
      mutate(
        
        dpd_bucket = case_when(
          
          days_past_due == 0 ~
            "Current",
          
          days_past_due <= 30 ~
            "1-30 DPD",
          
          days_past_due <= 60 ~
            "31-60 DPD",
          
          days_past_due <= 90 ~
            "61-90 DPD",
          
          TRUE ~
            "90+ DPD"
          
        )
        
      ) %>%
      
      group_by(
        
        dpd_bucket
        
      ) %>%
      
      summarise(
        
        outstanding = sum(
          
          outstanding_balance_bdt,
          
          na.rm = TRUE
          
        ),
        
        .groups = "drop"
        
      )
    
    
    ggplot(
      
      data,
      
      aes(
        
        x = dpd_bucket,
        
        y =
          outstanding /
          1000000
        
      )
      
    ) +
      
      geom_col() +
      
      labs(
        
        x = NULL,
        
        y =
          "Outstanding (Million BDT)"
        
      ) +
      
      theme_minimal()
    
  })
  
  # LOAN PURPOSE CHART

  
  output$loan_purpose_plot <- renderPlot({
    
    
    data <- filtered_apps() %>%
      
      count(
        
        loan_purpose,
        
        sort = TRUE
        
      )
    
    
    ggplot(
      
      data,
      
      aes(
        
        x = reorder(
          
          loan_purpose,
          
          n
          
        ),
        
        y = n
        
      )
      
    ) +
      
      geom_col() +
      
      coord_flip() +
      
      labs(
        
        x = NULL,
        
        y = "Applications"
        
      ) +
      
      theme_minimal()
    
  })
  
  # REQUESTED LOAN AMOUNT DISTRIBUTION

  
  output$requested_amount_plot <- renderPlot({
    
    
    ggplot(
      
      filtered_apps(),
      
      aes(
        
        x =
          requested_amount_bdt /
          1000000
        
      )
      
    ) +
      
      geom_histogram(
        
        bins = 30
        
      ) +
      
      labs(
        
        x =
          "Requested Amount (Million BDT)",
        
        y =
          "Applications"
        
      ) +
      
      theme_minimal()
    
  })
  
  # BRANCH SUMMARY TABLE
  
  output$branch_table <- renderDT({
    
    
    data <- app_data
    
    
    # Apply sector filter.
    
    
    if (
      input$sector != "All"
    ) {
      
      data <- data %>%
        
        filter(
          
          business_sector ==
            input$sector
          
        )
      
    }
    
    
    branch_summary <- data %>%
      
      group_by(
        
        branch_name
        
      ) %>%
      
      summarise(
        
        applications = n(),
        
        
        approved = sum(
          
          application_status ==
            "Approved"
          
        ),
        
        
        rejected = sum(
          
          application_status ==
            "Rejected"
          
        ),
        
        
        median_tat =
          
          safe_median(
            tat_days
          ),
        
        
        .groups = "drop"
        
      ) %>%
      
      mutate(
        
        approval_rate =
          
          100 *
          approved /
          pmax(
            
            approved +
              rejected,
            
            1
            
          )
        
      ) %>%
      
      select(
        
        Branch = branch_name,
        
        Applications =
          applications,
        
        `Approval Rate (%)` =
          approval_rate,
        
        `Median TAT (Days)` =
          median_tat
        
      )
    
    
    datatable(
      
      branch_summary,
      
      rownames = FALSE,
      
      options = list(
        
        pageLength = 8,
        
        autoWidth = TRUE
        
      )
      
    ) %>%
      
      formatRound(
        
        columns = c(
          
          "Approval Rate (%)",
          "Median TAT (Days)"
          
        ),
        
        digits = 1
        
      )
    
  })
  
  # TAT BY BRANCH

  
  output$tat_branch_plot <- renderPlot({
    
    
    data <- filtered_apps() %>%
      
      filter(
        
        !is.na(
          tat_days
        )
        
      )
    
    
    validate(
      
      need(
        
        nrow(data) > 0,
        
        "No TAT data available for this selection."
        
      )
      
    )
    
    
    ggplot(
      
      data,
      
      aes(
        
        x = branch_name,
        
        y = tat_days
        
      )
      
    ) +
      
      geom_boxplot() +
      
      coord_flip() +
      
      labs(
        
        x = NULL,
        
        y = "TAT (Days)"
        
      ) +
      
      theme_minimal()
    
  })
  
  # STAGE DURATION CHART
  
  output$stage_duration_plot <- renderPlot({
    
    
    stage_summary <- filtered_stages() %>%
      
      filter(
        
        !is.na(
          duration_days
        )
        
      ) %>%
      
      group_by(
        
        stage_name
        
      ) %>%
      
      summarise(
        
        average_duration = mean(
          
          duration_days,
          
          na.rm = TRUE
          
        ),
        
        .groups = "drop"
        
      )
    
    
    ggplot(
      
      stage_summary,
      
      aes(
        
        x = reorder(
          
          stage_name,
          
          average_duration
          
        ),
        
        y =
          average_duration
        
      )
      
    ) +
      
      geom_col() +
      
      coord_flip() +
      
      labs(
        
        x = NULL,
        
        y =
          "Average Duration (Days)"
        
      ) +
      
      theme_minimal()
    
  })
  
  # STAGE SUMMARY TABLE
  
  
  output$stage_table <- renderDT({
    
    
    stage_summary <- filtered_stages() %>%
      
      filter(
        
        !is.na(
          duration_days
        )
        
      ) %>%
      
      group_by(
        
        stage_name,
        
        department
        
      ) %>%
      
      summarise(
        
        records = n(),
        
        average_duration = mean(
          
          duration_days,
          
          na.rm = TRUE
          
        ),
        
        .groups = "drop"
        
      ) %>%
      
      arrange(
        
        desc(
          average_duration
        )
        
      ) %>%
      
      rename(
        
        Stage = stage_name,
        
        Department = department,
        
        Records = records,
        
        `Average Duration (Days)` =
          average_duration
        
      )
    
    
    datatable(
      
      stage_summary,
      
      rownames = FALSE
      
    ) %>%
      
      formatRound(
        
        columns =
          "Average Duration (Days)",
        
        digits = 2
        
      )
    
  })
  
  # DPD COUNT CHART
  
  output$dpd_count_plot <- renderPlot({
    
    
    data <- filtered_loans() %>%
      
      filter(
        
        current_loan_status !=
          "Closed"
        
      ) %>%
      
      mutate(
        
        dpd_bucket = case_when(
          
          days_past_due == 0 ~
            "Current",
          
          days_past_due <= 30 ~
            "1-30 DPD",
          
          days_past_due <= 60 ~
            "31-60 DPD",
          
          days_past_due <= 90 ~
            "61-90 DPD",
          
          TRUE ~
            "90+ DPD"
          
        )
        
      ) %>%
      
      count(
        
        dpd_bucket
        
      )
    
    
    ggplot(
      
      data,
      
      aes(
        
        x = dpd_bucket,
        
        y = n
        
      )
      
    ) +
      
      geom_col() +
      
      labs(
        
        x = NULL,
        
        y = "Number of Loans"
        
      ) +
      
      theme_minimal()
    
  })
  

  # PORTFOLIO DPD EXPOSURE

  
  output$portfolio_dpd_exposure_plot <- renderPlot({
    
    
    data <- filtered_loans() %>%
      
      filter(
        
        current_loan_status !=
          "Closed"
        
      ) %>%
      
      mutate(
        
        dpd_bucket = case_when(
          
          days_past_due == 0 ~
            "Current",
          
          days_past_due <= 30 ~
            "1-30 DPD",
          
          days_past_due <= 60 ~
            "31-60 DPD",
          
          days_past_due <= 90 ~
            "61-90 DPD",
          
          TRUE ~
            "90+ DPD"
          
        )
        
      ) %>%
      
      group_by(
        
        dpd_bucket
        
      ) %>%
      
      summarise(
        
        outstanding = sum(
          
          outstanding_balance_bdt,
          
          na.rm = TRUE
          
        ),
        
        .groups = "drop"
        
      )
    
    
    ggplot(
      
      data,
      
      aes(
        
        x = dpd_bucket,
        
        y =
          outstanding /
          1000000
        
      )
      
    ) +
      
      geom_col() +
      
      labs(
        
        x = NULL,
        
        y =
          "Outstanding (Million BDT)"
        
      ) +
      
      theme_minimal()
    
  })
  
  # PAR30 BY BUSINESS SECTOR

  
  output$sector_par30_plot <- renderPlot({
    
    
    data <- filtered_loans() %>%
      
      filter(
        
        current_loan_status !=
          "Closed"
        
      ) %>%
      
      group_by(
        
        business_sector
        
      ) %>%
      
      summarise(
        
        outstanding = sum(
          
          outstanding_balance_bdt,
          
          na.rm = TRUE
          
        ),
        
        
        par30_balance = sum(
          
          outstanding_balance_bdt[
            days_past_due >= 30
          ],
          
          na.rm = TRUE
          
        ),
        
        
        .groups = "drop"
        
      ) %>%
      
      mutate(
        
        par30_pct =
          
          if_else(
            
            outstanding > 0,
            
            100 *
              par30_balance /
              outstanding,
            
            NA_real_
            
          )
        
      )
    
    
    ggplot(
      
      data,
      
      aes(
        
        x = reorder(
          
          business_sector,
          
          par30_pct
          
        ),
        
        y =
          par30_pct
        
      )
      
    ) +
      
      geom_col() +
      
      coord_flip() +
      
      labs(
        
        x = NULL,
        
        y = "PAR30 (%)"
        
      ) +
      
      theme_minimal()
    
  })
  
  # LOAN-LEVEL PORTFOLIO TABLE
  
  output$loan_table <- renderDT({
    
    
    table_data <- filtered_loans() %>%
      
      select(
        
        loan_id,
        business_name,
        branch_name,
        business_sector,
        disbursed_amount_bdt,
        outstanding_balance_bdt,
        days_past_due,
        current_loan_status
        
      ) %>%
      
      arrange(
        
        desc(
          days_past_due
        )
        
      ) %>%
      
      rename(
        
        `Loan ID` = loan_id,
        
        Business = business_name,
        
        Branch = branch_name,
        
        Sector = business_sector,
        
        `Disbursed BDT` =
          disbursed_amount_bdt,
        
        `Outstanding BDT` =
          outstanding_balance_bdt,
        
        DPD =
          days_past_due,
        
        Status =
          current_loan_status
        
      )
    
    
    datatable(
      
      table_data,
      
      rownames = FALSE,
      
      options = list(
        
        pageLength = 10,
        
        scrollX = TRUE
        
      )
      
    ) %>%
      
      formatCurrency(
        
        columns = c(
          
          "Disbursed BDT",
          "Outstanding BDT"
          
        ),
        
        currency = "৳",
        
        interval = 3,
        
        mark = ",",
        
        digits = 0
        
      )
    
  })
  
}

# RUN THE SHINY APPLICATION

shinyApp(
  
  ui = ui,
  
  server = server
  
)



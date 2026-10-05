-- Build a DPD summary using case when

SELECT
	CASE
		WHEN days_past_due = 0 THEN 'Current'
		WHEN days_past_due BETWEEN 1 AND 30 THEN '1-30 DPD'
		WHEN days_past_due BETWEEN 31 AND 60 THEN '31-60 DPD'
		WHEN days_past_due BETWEEN 61 AND 90 THEN '61-90 DPD'
		ELSE '90+ DPD'
	END AS dpd_bucket,
	COUNT(*) AS number_of_loans,
	ROUND(
		SUM(outstanding_balance_bdt)
		,2) AS outstasnding_bdt
FROM loans
WHERE current_loan_status <> 'Closed'
GROUP BY
	CASE
		WHEN days_past_due = 0 THEN 'Current'
		WHEN days_past_due BETWEEN 1 AND 30 THEN '1-30 DPD'
		WHEN days_past_due BETWEEN 31 AND 60 THEN '31-60 DPD'
		WHEN days_past_due BETWEEN 61 AND 90 THEN '61-90 DPD'
		ELSE '90+ DPD'
	END
ORDER BY 1;

-- Create business flag

SELECT 
	loan_id,
	days_past_due,
	CASE
		WHEN days_past_due >= 30 THEN 'Needs Attention'
		ELSE 'Normal'
	END
FROM loans;

-- Monthly trend analysis

SELECT
	DATE_TRUNC('month', application_date) AS month,
	COUNT(*) AS applications
FROM applications
GROUP BY 1
ORDER BY 1;

-- LAG() function

-- Applications change compared with last month

WITH monthly_applications AS (
	SELECT
	DATE_TRUNC('month', application_date) AS month,
	COUNT(*) AS applications
FROM applications
GROUP BY 1
)
SELECT 
	month,
	applications,
	LAG(applications) OVER(ORDER BY month) previous_month_applications
FROM monthly_applicationS
ORDER BY 1;

-- Calculate Month over Month growth

WITH monthly_applications AS (
	SELECT
	DATE_TRUNC('month', application_date) AS month,
	COUNT(*) AS applications
FROM applications
GROUP BY 1
),
with_previous AS (
SELECT 
	month,
	applications,
	LAG(applications) OVER(ORDER BY month) previous_month_applications
FROM monthly_applications
)
SELECT
	month,
	applications,
	previous_month_applications,
	ROUND(
		100.0 * (applications - previous_month_applications) /
		NULLIF(previous_month_applications,0)
	,2) AS mom_growth_pct
FROM with_previous
ORDER BY 1;

-- Monthly approval rate trend

SELECT
	DATE_TRUNC('month', application_date) AS month,
	COUNT(*) FILTER(WHERE application_status = 'Approved') AS approved,
	COUNT(*) FILTER(WHERE application_status = 'Rejected') AS rejected,
	ROUND(
		100.0 * COUNT(*) FILTER(WHERE application_status = 'Approved') /
		NULLIF(COUNT(*) FILTER(WHERE application_status IN ('Approved', 'Rejected')),0)
	,2) AS approval_rate_pct
FROM applications
GROUP BY 1
ORDER BY 1;

-- Monthly TAT trend

SELECT
	DATE_TRUNC('month', application_date) AS month,
	COUNT(*) AS applications,
	ROUND(
		AVG(decision_date - application_date)
	,2) AS average_tat_days
FROM applications
WHERE decision_date IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- Find out pending applications aging

SELECT
	application_id,
	customer_id,
	branch_id,
	application_date,
	DATE '2026-10-03' - application_date AS pending_days
FROM applications
WHERE application_status = 'Pending'
ORDER BY 4 DESC;

-- Create aging buckets

SELECT
	CASE
		WHEN DATE '2026-10-04' - application_date <= 3 THEN '0-3 Days'
		WHEN DATE '2026-10-04' - application_date <= 7 THEN '4-7 Days'
		WHEN DATE '2026-10-04' - application_date <= 14 THEN '8-14 Days'
		ELSE '15+ Days'
	END AS aging_bucket,
	COUNT(*) AS pending_applications
FROM applications
WHERE application_status = 'Pending'
GROUP BY 
	CASE
		WHEN DATE '2026-10-04' - application_date <= 3 THEN '0-3 Days'
		WHEN DATE '2026-10-04' - application_date <= 7 THEN '4-7 Days'
		WHEN DATE '2026-10-04' - application_date <= 14 THEN '8-14 Days'
		ELSE '15+ Days'
	END;

-- Identify the exact current stage of applications

WITH ranked_stages AS (
	SELECT
		application_id,
		stage_name,
		department,
		stage_start_date,
		stage_end_date,
		stage_status,
		ROW_NUMBER() OVER(PARTITION BY application_id 
			ORDER BY stage_order DESC) AS rn
	FROM application_stages
)
SELECT *
FROM ranked_stages
WHERE rn = 1;

-- Find where pending applications are stuck

WITH ranked_stages AS (
	SELECT
		application_id,
		stage_name,
		department,
		stage_start_date,
		stage_end_date,
		stage_status,
		ROW_NUMBER() OVER(PARTITION BY application_id 
			ORDER BY stage_order DESC) AS rn
	FROM application_stages
)
SELECT
	a.application_id,
	a.application_date,
	rs.stage_name,
	rs.department,
	rs.stage_start_date,
	DATE '2026-10-04' - rs.stage_start_date AS days_in_current_stage
FROM applicationS AS a
JOIN ranked_stages AS rs
	ON a.application_id = rs.application_id
	AND rs.rn = 1
WHERE a.application_status = 'Pending'
ORDER BY 6 DESC;

-- Summarize pending applications by current stages

WITH ranked_stages AS (
	SELECT
		application_id,
		stage_name,
		department,
		stage_start_date,
		stage_end_date,
		stage_status,
		ROW_NUMBER() OVER(PARTITION BY application_id 
			ORDER BY stage_order DESC) AS rn
	FROM application_stages
)
SELECT 
	rs.stage_name,
	rs.department,
	COUNT(*) AS pending_applications
FROM applications AS a
JOIN ranked_stages AS rs
	ON a.application_id = rs.application_id
	AND rs.rn = 1
WHERE a.application_status = 'Pending'
GROUP BY 1,2
ORDER BY 3 DESC;

-- Ranking branches

WITH branch_volume AS (
SELECT
	b.branch_name,
	COUNT(*) AS applications
FROM applications AS a
JOIN branches AS b
	ON a.branch_id = b.branch_id
GROUP BY 1
)
SELECT
	branch_name,
	applications,
	RANK() OVER(ORDER BY applications DESC) AS volume_rank
FROM branch_volume
ORDER BY 3;

-- Branch level PAR 30(Portfolio At Risk)

SELECT 
	b.branch_name,
	ROUND(
		SUM(l.outstanding_balance_bdt)
	,2) AS active_outstanding_bdt,
	ROUND(
		SUM(l.outstanding_balance_bdt) FILTER(WHERE l.days_past_due >=30)
	,2) AS par30_balance_bdt,
	ROUND(
	100.0 * SUM(l.outstanding_balance_bdt) FILTER(WHERE l.days_past_due >=30) /
	NULLIF(SUM(l.outstanding_balance_bdt),0)
	,2) AS par30_pct
FROM loans AS l
JOIN branches AS b
	ON l.branch_id = b.branch_id
WHERE l.current_loan_status <> 'Closed'
GROUP BY 1
ORDER BY 4 DESC;

-- Sector level PAR30

SELECT
	c.business_sector,
	ROUND(
		SUM(l.outstanding_balance_bdt)
	,2) AS active_outstanding_bdt,
	ROUND(
		SUM(l.outstanding_balance_bdt) FILTER(WHERE l.days_past_due >=30)
	,2) AS par30_balance_bdt,
	ROUND(
	100.0 * SUM(l.outstanding_balance_bdt) FILTER(WHERE l.days_past_due >=30) /
	NULLIF(SUM(l.outstanding_balance_bdt),0)
	,2) AS par30_pct
FROM loans AS l
JOIN customers AS c
	ON l.customer_id = c.customer_id
WHERE l.current_loan_status <> 'Closed'
GROUP BY 1
ORDER BY 4 DESC;

-- Calculate debt to revenue ratio

SELECT
	customer_id,
	annual_revenue_bdt,
	existing_debt_bdt,
	ROUND(
		100.0 * existing_debt_bdt/
		NULLIF(annual_revenue_bdt,0)
	,2)
FROM customers;

-- Build watchlist 

SELECT 
	l.loan_id,
	c.customer_id,
	c.business_sector,
	l.outstanding_balance_bdt,
	l.days_past_due,
	c.previous_default_flag,
	ROUND(
		100.0 * C.existing_debt_bdt/
		NULLIF(C.annual_revenue_bdt,0)
	,2) AS debt_to_revenue_pct,
	CASE
		WHEN days_past_due >= 90 THEN 'High Alert'
		WHEN days_past_due >= 30
			OR c.previous_default_flag = 1
			OR ROUND(
			100.0 * C.existing_debt_bdt/
			NULLIF(C.annual_revenue_bdt,0)
			,2) > 0.45
			THEN 'Watch'
		ELSE 'Normal'
	END AS monitoring_status
FROM loans AS l
JOIN customers AS c
	ON l.customer_id = c.customer_id
WHERE l.current_loan_status <> 'Closed';

-- Count Watchlist loans

WITH watchlist AS (
SELECT 
	l.loan_id,
	c.customer_id,
	c.business_sector,
	l.outstanding_balance_bdt,
	l.days_past_due,
	c.previous_default_flag,
	ROUND(
		100.0 * C.existing_debt_bdt/
		NULLIF(C.annual_revenue_bdt,0)
	,2) AS debt_to_revenue_pct,
	CASE
		WHEN days_past_due >= 90 THEN 'High Alert'
		WHEN days_past_due >= 30
			OR c.previous_default_flag = 1
			OR ROUND(
			100.0 * C.existing_debt_bdt/
			NULLIF(C.annual_revenue_bdt,0)
			,2) > 0.45
			THEN 'Watch'
		ELSE 'Normal'
	END AS monitoring_status
FROM loans AS l
JOIN customers AS c
	ON l.customer_id = c.customer_id
WHERE l.current_loan_status <> 'Closed'
)
SELECT
	monitoring_status,
	COUNT(*) AS loans,
	ROUND(SUM(outstanding_balance_bdt),2) AS outstanding_bdt
FROM watchlist
GROUP BY 1
ORDER BY 3 DESC;

-- Calculate rolling three month average

WITH monthly_applications AS (
SELECT
	DATE_TRUNC('month', application_date) AS month,
	COUNT(*) AS applications
FROM applications
GROUP BY 1
)
SELECT 
	month,
	applications,
	ROUND(
		AVG(applications) OVER(ORDER BY month 
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
	,2) AS rolling_3_month_avg
FROM monthly_applications
ORDER BY 1;

-- Top applications by requested amount within each sector

WITH ranked_applications AS (
	SELECT
		C.business_sector,
		a.application_id,
		a.requested_amount_bdt,
		ROW_NUMBER() OVER(PARTITION BY c.business_sector
						ORDER BY a.requested_amount_bdt DESC) AS rn
	FROM applications AS a
	JOIN customers AS c
		ON a.customer_id = c.customer_id
)
SELECT 
	business_sector,
	application_id,
	requested_amount_bdt
FROM ranked_applications
WHERE rn <= 3
ORDER BY business_sector, rn;

-- Branch Monitoring table

WITH applications_summary AS (
	SELECT
		branch_id,
		COUNT(*) AS applications,
		ROUND(
			COUNT(*) FILTER(WHERE application_status = 'Approved')
			,2) AS approved,
		ROUND(
			COUNT(*) FILTER(WHERE application_status = 'Rejected')
			,2) AS rejected,
		ROUND(
			AVG(decision_date - application_date) FILTER(WHERE decision_date IS NOT NULL)
		,2) AS average_tat_days
	FROM applications
	GROUP BY 1
),
loan_summary AS (
	SELECT
		branch_id,
		SUM(outstanding_balance_bdt) 
			FILTER(WHERE current_loan_status <> 'Closed') AS outstanding_bdt,
		SUM(outstanding_balance_bdt) 
			FILTER(WHERE current_loan_status <> 'Closed' AND days_past_due >= 30) 
			AS par30_balance_bdt
	FROM loans AS l
	GROUP BY 1
)
SELECT
	b.branch_name,
	a.applications,
	ROUND(
		100.0 * a.approved / NULLIF(a.approved + a.rejected,0)
		,2) AS approval_rate_pct,
	a.average_tat_days,
	ROUND(
		l.outstanding_bdt
		,2) AS outstanding_bdt,
	ROUND(
		100.0 * l.outstanding_bdt /
		NULLIF(l.par30_balance_bdt,0)
		,2) AS par30_pct
FROM branches AS b
JOIN applications_summary AS a
	ON b.branch_id = a.branch_id
JOIN loan_summary AS l
	ON l.branch_id = a.branch_id
ORDER BY 1;
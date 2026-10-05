-- KPI 1: Total applications

SELECT 
	COUNT(*) AS total_applications
FROM applications;

-- KPI 2: Application status distribution

SELECT
	application_status,
	COUNT(*) AS applications,
	ROUND(
		100.0 * COUNT(*) / SUM(COUNT(*)) OVER()
	,2) AS percentage
FROM applications
GROUP BY 1
ORDER BY 3 DESC;

-- KPI 3: Approval Rate

SELECT 
	ROUND(
		100.0 * COUNT(*) FILTER(WHERE application_status = 'Approved') / 
		NULLIF(COUNT(*) FILTER(WHERE application_status IN ('Approved', 'Rejected')),0)
		,2) AS approval_rate_pct
FROM applications;

--KPI 4: Rejection Rate

SELECT 
	ROUND(
		100.0 * COUNT(*) FILTER(WHERE application_status = 'Rejected') / 
		NULLIF(COUNT(*) FILTER(WHERE application_status IN ('Approved', 'Rejected')),0)
		,2) AS rejection_rate_pct
FROM applications;

-- KPI 5: Pending Rate

SELECT 
	ROUND(
		100.0 * COUNT(*) FILTER(WHERE application_status = 'Pending') / 
		COUNT(*)
		,2) AS pending_rate_pct
FROM applications;

-- KPI 6: Average TAT

SELECT 
	ROUND(
		AVG(decision_date - application_date)
	,2) AS average_tat_days
FROM applications
WHERE decision_date IS NOT NULL;

-- KPI 7 Median TAT

SELECT
	ROUND(
		PERCENTILE_CONT(0.5)
		WITHIN GROUP (
			ORDER BY decision_date - application_date
		) :: numeric
	,2) AS median_tat_days
FROM applications
WHERE decision_date IS NOT NULL;

-- KPI 8: Total disbursement

SELECT
	ROUND(
		SUM(disbursed_amount_bdt)
	,2) AS total_disbursed_amount_bdt
FROM loans;

-- KPI9 Average loan size

SELECT
	ROUND(
		AVG(disbursed_amount_bdt)
	,2) AS average_loan_size_bdt
FROM loans;

--  KPI 10: Total outstanding portfolio

SELECT
	ROUND(
		SUM(outstanding_balance_bdt)
	,2) AS total_outstanding_bdt
FROM loans;

-- Active outstanding portfolio

SELECT
	ROUND(
		SUM(outstanding_balance_bdt)
	,2) AS active_outstanding_bdt
FROM loans
WHERE current_loan_status != 'Closed';

-- KPI 11: Past due loan count

SELECT COUNT(*) AS past_due_loans
FROM loans
WHERE days_past_due > 0;

-- KPI 12: Past due outstanding balance

SELECT 
	ROUND(SUM(outstanding_balance_bdt),2) AS past_due_outstanding_bdt
FROM loans
WHERE days_past_due > 0;

-- Calculating PAR 30 (Portfolio At Risk)

SELECT
	ROUND(
		100.0 * SUM(outstanding_balance_bdt) FILTER(WHERE days_past_due >= 30) /
		NULLIF(SUM(outstanding_balance_bdt) FILTER(WHERE current_loan_status <> 'Closed'),0)
	,2) AS par_30_pcr
FROM loans

-- Calculating PAR 90

SELECT
	ROUND(
	100.0 * SUM(outstanding_balance_bdt) FILTER(WHERE days_past_due >= 90) /
	NULLIF(SUM(outstanding_balance_bdt) FILTER(WHERE current_loan_status <> 'Closed'),0)
	,2) AS par_90_pct
FROM loans;

-- Portfolio concentration by business sectors

SELECT 
	c.business_sector,
	ROUND(
		SUM(l.outstanding_balance_bdt)
	,2) AS outstanding_bdt,
	ROUND(
		100.0 * SUM(l.outstanding_balance_bdt) /
		SUM(SUM(l.outstanding_balance_bdt)) OVER()
	,2) AS portfolio_share_pct
FROM loans AS l
JOIN customers AS c
	ON l.customer_id = c.customer_id
WHERE l.current_loan_status <> 'Closed'
GROUP BY 1
ORDER BY 2 DESC;

-- Build application summary by branch

WITH application_summary AS (
	SELECT 
		branch_id,
		COUNT(*) AS total_applications,
		COUNT(*) FILTER(WHERE application_status = 'Approved') AS approved,
		COUNT(*) FILTER(WHERE application_status = 'Rejected') AS rejected,
		ROUND(
			AVG(decision_date - application_date)
			FILTER(WHERE decision_date IS NOT NULL)
			,2) AS average_tat_days
	FROM applications
	GROUP BY 1
)
SELECT *
FROM application_summary;

-- Build Loan summary by branches

WITH loan_summary AS (
	SELECT
		branch_id,
		COUNT(*) AS number_of_loans,
		SUM(disbursed_amount_bdt) AS total_disbursed_bdt,
		SUM(outstanding_balance_bdt) AS outstanding_bdt
	FROM loans
	GROUP BY 1
)
SELECT * 
FROM loan_summary;

-- Combining both of the CTE

WITH application_summary AS (
	SELECT 
		branch_id,
		COUNT(*) AS total_applications,
		COUNT(*) FILTER(WHERE application_status = 'Approved') AS approved,
		COUNT(*) FILTER(WHERE application_status = 'Rejected') AS rejected,
		ROUND(
			AVG(decision_date - application_date)
			FILTER(WHERE decision_date IS NOT NULL)
			,2) AS average_tat_days
	FROM applications
	GROUP BY 1
),
loan_summary AS (
	SELECT
		branch_id,
		COUNT(*) AS number_of_loans,
		SUM(disbursed_amount_bdt) AS total_disbursed_bdt,
		SUM(outstanding_balance_bdt) AS outstanding_bdt
	FROM loans
	GROUP BY 1
)
SELECT 
	b.branch_name,
	a.total_applications,
	ROUND(
		100.0 * a.approved / NULLIF(a.approved + a.rejected, 0),
	2) AS approval_rate_pct,
	a.average_tat_days,
	l.number_of_loans,
	ROUND(l.total_disbursed_bdt,2) AS total_disbursed_bdt,
	ROUND(l.outstanding_bdt,2) AS outstanding_bdt
FROM branches AS b
LEFT JOIN application_summary AS a
	ON b.branch_id = a.branch_id
LEFT JOIN loan_summary AS l
	ON b.branch_id = l.branch_id
ORDER BY outstanding_bdt DESC;

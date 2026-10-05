-- Check row counts

SELECT COUNT(*) AS branches
FROM branches;

SELECT COUNT(*) AS customers
FROM customers;

SELECT COUNT(*) AS applications
FROM applications;

SELECT COUNT(*) AS application_stages
FROM application_stages;

SELECT COUNT(*) AS loans
FROM loans;

SELECT COUNT(*) AS repayments
FROM repayments;

-- Check duplicates

-- For customers

SELECT
	customer_id,
	COUNT(*) AS occurrences
FROM customers
GROUP BY 1
HAVING COUNT(*) > 1;

-- For applications

SELECT
	application_id,
	COUNT(*) AS occurrences
FROM applications
GROUP BY 1
HAVING COUNT(*) > 1;

-- Check missing customer information

SELECT 
	COUNT(*) AS customers_missing_sector
FROM customers
WHERE business_sector IS NULL;

SELECT 
	COUNT(*) AS customers_missing_revenue
FROM customers
WHERE annual_revenue_bdt IS NULL;

SELECT 
	COUNT(*) AS customers_missing_business_age
FROM customers
WHERE business_age_years IS NULL;

-- Check approved applications without decision date

SELECT
	application_id,
	application_status,
	decision_date
FROM applications
WHERE application_status = 'Approved'
	AND decision_date IS NULL;

-- Check pending applications with decision date

SELECT
	application_id,
	application_status,
	decision_date
FROM applications
WHERE application_status = 'Pending'
	AND decision_date IS NOT NULL;

-- Check impossible date relationship

SELECT
	application_id,
	application_date,
	decision_date
FROM applications
WHERE decision_date < application_date;

SELECT
	application_id,
	stage_name,
	stage_start_date,
	stage_end_date
FROM application_stages
WHERE stage_end_date < stage_start_date;

-- Check negative financial value

SELECT *
FROM applications
WHERE requested_amount_bdt < 0;

SELECT *
FROM loans
WHERE disbursed_amount_bdt < 0;

SELECT *
FROM loans
WHERE outstanding_balance_bdt < 0;

-- Check annual revenue

SELECT *
FROM customers
WHERE annual_revenue_bdt <= 0;

-- Check application statuses

SELECT DISTINCT application_status
FROM applications
ORDER BY 1;

-- Check loan status

SELECT DISTINCT current_loan_status
FROM loans
ORDER BY 1;

-- Check customer to application relationship

SELECT
	a.application_id,
	a.customer_id
FROM applications AS a
LEFT JOIN customers AS c
	ON a.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check approved applications without loan records 

SELECT 
	a.application_id,
	a.customer_id,
	a.approved_amount_bdt
FROM applications AS a
LEFT JOIN loans AS l
	ON a.application_id = l.application_id
WHERE application_status = 'Approved'
	AND l.loan_id IS NULL;

-- Check rejected applications that somehow have loans

SELECT
	a.application_id,
	a.application_status,
	l.loan_id
FROM applications AS a
JOIN loans AS l
	ON a.application_id = l.application_id
WHERE a.application_status = 'Rejected';

-- Check whether outstanding exceeds original disbursement

SELECT
	loan_id,
	disbursed_amount_bdt,
	outstanding_balance_bdt
FROM loans
WHERE outstanding_balance_bdt > disbursed_amount_bdt;

-- Check negative DPD

SELECT *
FROM loans
WHERE days_past_due < 0;

-- Repayment quality check

SELECT *
FROM repayments
WHERE amount_due_bdt < 0
	OR amount_paid_bdt < 0;

-- Check payment date before due date

SELECT
	loan_id,
	due_date,
	payment_date,
	payment_status
FROM repayments
WHERE payment_date < due_date;

-- Check unpaid installments with payment amounts

SELECT *
FROM repayments
WHERE payment_status = 'Unpaid' 
	AND amount_paid_bdt > 0;

-- Check paid on time rows with days late

SELECT *
FROM repayments
WHERE payment_status = 'Paid On Time'
	AND days_late > 0;

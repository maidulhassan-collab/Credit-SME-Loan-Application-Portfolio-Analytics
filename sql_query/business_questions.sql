-- Business question 1: Applications by business sector

SELECT 
	c.business_sector,
	COUNT(*) AS total_applications
FROM applications AS a
JOIN customers AS c
	ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC;

-- Business question 2: Applications by branches

SELECT 
	b.branch_name,
	COUNT(*) AS total_applications
FROM applications AS a
JOIN branches AS b
	ON 	a.branch_id = b.branch_id
GROUP BY 1
ORDER BY 2 DESC;

-- Branch wise application status

SELECT
	b.branch_name,
	a.application_status,
	COUNT(*) AS applications
FROM applications AS a
JOIN branches AS b
	ON a.branch_id = b.branch_id
GROUP BY 1,2
ORDER BY 1,2;

-- Business question 3: Approval rate by branches

SELECT 
	b.branch_name,
	COUNT(*) FILTER(WHERE a.application_status = 'Approved') AS approved_applications,
	COUNT(*) FILTER(WHERE a.application_status = 'Rejected') AS rejected_applications,
	ROUND(
		100.0 * COUNT(*) FILTER(WHERE a.application_status = 'Approved')/
		NULLIF(COUNT(*) FILTER(WHERE a.application_status IN ('Approved', 'Rejected')),0)
		,2
	) AS approval_rate
FROM applications AS a
JOIN branches AS b
	ON a.branch_id = b.branch_id
GROUP BY 1
ORDER BY 4 DESC;

-- Business question 4: Average requested amount by business sectors

SELECT 
	c.business_sector,
	COUNT(*) AS applications,
	ROUND(
	AVG(a.requested_amount_bdt)
	,2) AS average_requested_amount
FROM applications AS a
JOIN customers AS c
	ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 3  DESC;

-- Business question 5: Total requested amount by business sectors

SELECT 
	c.business_sector,
	COUNT(*) AS applications,
	ROUND(
		SUM(a.requested_amount_bdt)
	,2) AS total_requested_amount_bdt
FROM applications AS a
JOIN customers AS c
	ON a.customer_id = c.customer_id
GROUP BY 1
ORDER BY 3 DESC;

-- Business Question 6: Average TAT by branches

SELECT 
	b.branch_name,
	COUNT(*) AS decided_applications,
	ROUND(
		AVG(a.decision_date - a.application_date)
	,2) AS average_tat_days
FROM applications AS a
JOIN branches AS b
	ON a.branch_id = b.branch_id
WHERE a.decision_date IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC;

-- BUSINESS QUESTION 7: Average Duration by application stage

SELECT 
	stage_name,
	COUNT(*) AS stage_records,
	ROUND(
		AVG(duration_days)
	,2) AS average_duration_days
FROM application_stages
WHERE duration_days IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC;

-- Business Question 8: Stage duration by departments

SELECT
	department,
	COUNT(*) AS stage_records,
	ROUND(
		AVG(duration_days)
	,2) AS average_duration_days
FROM application_stages
WHERE duration_days IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC;

-- Branch that do slowest credit assesment

SELECT 
	b.branch_name,
	s.stage_name,
	ROUND(
		AVG(s.duration_days)
	,2) AS average_duration_days
FROM applicationS AS a
JOIN branches AS b
	ON b.branch_id = a.branch_id
JOIN application_stages AS s
	ON a.application_id = s.application_id
WHERE s.duration_days IS NOT NULL AND s.stage_name = 'Credit Assessment'
GROUP BY 1,2
ORDER BY 1,3 DESC;

-- Business Question 9: Total disbursement by branches

SELECT 
	b.branch_name,
	COUNT(*) AS number_of_loans,
	ROUND(
		SUM(l.disbursed_amount_bdt)
	,2) AS total_disbursed_amount_bdt
FROM loans AS l
JOIN branches AS b
	ON l.branch_id = b.branch_id
GROUP BY 1
ORDER BY 3 DESC;

-- Business Question 10: Outstanding portfolio by branch

SELECT
	b.branch_name,
	ROUND(
		SUM(l.outstanding_balance_bdt)
	,2) AS total_outstanding_amount_bdt
FROM loans AS l
JOIN branches AS b
	ON l.branch_id = b.branch_id
GROUP BY 1
ORDER BY 2 DESC;

-- Business Question 11: Outstanding portfolio by sectors

SELECT 
	c.business_sector,
	COUNT(*) AS number_of_loans,
	ROUND(
		SUM(l.outstanding_balance_bdt)
		,2) AS total_outstanding_bdt
FROM loans AS l
JOIN customers AS C
	ON c.customer_id = l.customer_id
GROUP BY 1
ORDER BY 3 DESC;

-- Business Question 12: DPD distribution

SELECT 
 	current_loan_status,
 	COUNT(*) AS number_of_loans,
 	ROUND(
 		SUM(outstanding_balance_bdt)
 	,2) AS  total_outstanding_bdt
 FROM loans
 GROUP BY 1
 ORDER BY 1 DESC;

--   Business Question 13: Approved applications that have not produced a loan record

SELECT
	a.application_id,
	a.customer_id,
	a.application_status,
	l.loan_id
FROM applications AS a
LEFT JOIN loans AS l
	ON a.application_id = l.application_id
WHERE a.application_status = 'Approved';

-- Business Question 14: Approved applications without a loan

SELECT
	a.application_id,
	a.customer_id,
	a.application_status,
	l.loan_id
FROM applications AS a
LEFT JOIN loans AS l
	ON a.application_id = l.application_id
WHERE a.application_status = 'Approved'
	AND l.loan_id IS NULL;


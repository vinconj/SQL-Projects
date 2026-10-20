-- ============================================================
-- EXPLORATORY DATA ANALYSIS (EDA): ds_salaries
-- Dataset: Data Science Job Salaries (607 rows, 12 columns)
-- ============================================================


-- ============================================================
-- SECTION 1: UNDERSTAND THE SHAPE OF DATA
-- ============================================================

-- Preview the dataset
SELECT * FROM salaries LIMIT 10;

-- Total row count
SELECT COUNT(*) AS total_rows FROM salaries;
-- Result: 607 rows

-- Column overview (data types, nullability)
SHOW COLUMNS FROM salaries;


-- ============================================================
-- SECTION 2: SUMMARY STATISTICS — PROFILE EACH COLUMN
-- ============================================================

-- 2a. Categorical column distinct counts
SELECT
    COUNT(DISTINCT job_title)          AS distinct_job_titles,    -- 50
    COUNT(DISTINCT experience_level)   AS distinct_exp_levels,    -- 4
    COUNT(DISTINCT employment_type)    AS distinct_emp_types,     -- 4
    COUNT(DISTINCT salary_currency)    AS distinct_currencies,    -- 17
    COUNT(DISTINCT employee_residence) AS distinct_residences,
    COUNT(DISTINCT company_location)   AS distinct_company_locs,
    COUNT(DISTINCT company_size)       AS distinct_company_sizes  -- 3
FROM salaries;

-- 2b. Distinct values for key categorical columns
SELECT DISTINCT experience_level FROM salaries;
-- EN = Entry, MI = Mid, SE = Senior, EX = Executive

SELECT DISTINCT employment_type FROM salaries;
-- FT = Full-time, PT = Part-time, CT = Contract, FL = Freelance

SELECT DISTINCT company_size FROM salaries;
-- S = Small, M = Medium, L = Large

-- 2c. Summary statistics for all numeric columns
SELECT
    -- salary (in local currency — not comparable across rows)
    MAX(salary)              AS max_salary,
    MIN(salary)              AS min_salary,
    ROUND(AVG(salary), 2)   AS avg_salary,

    -- salary_in_usd (standardised — use this for all comparisons)
    MAX(salary_in_usd)              AS max_salary_usd,
    MIN(salary_in_usd)              AS min_salary_usd,
    ROUND(AVG(salary_in_usd), 2)   AS avg_salary_usd,
    ROUND(STDDEV(salary_in_usd), 2) AS stddev_salary_usd,

    -- work_year range
    MIN(work_year) AS earliest_year,
    MAX(work_year) AS latest_year
FROM salaries;


-- ============================================================
-- SECTION 3: DISTRIBUTIONS
-- ============================================================

-- 3a. Record count by experience level
-- Shows how the dataset is distributed across seniority levels
SELECT
    experience_level,
    COUNT(*)                                                    AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)         AS percentage
FROM salaries
GROUP BY experience_level
ORDER BY total DESC;

-- 3b. Record count by employment type
SELECT
    employment_type,
    COUNT(*)                                                    AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)         AS percentage
FROM salaries
GROUP BY employment_type
ORDER BY total DESC;

-- 3c. Record count by company size
SELECT
    company_size,
    COUNT(*)                                                    AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)         AS percentage
FROM salaries
GROUP BY company_size
ORDER BY total DESC;

-- 3d. Record count by year
-- Shows data volume growth over time
SELECT
    work_year,
    COUNT(*)                                                    AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)         AS percentage
FROM salaries
GROUP BY work_year
ORDER BY work_year;

-- 3e. Remote work distribution
-- 0 = On-site, 50 = Hybrid, 100 = Fully remote
SELECT
    remote_ratio,
    COUNT(*)                                                    AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)         AS percentage
FROM salaries
GROUP BY remote_ratio
ORDER BY remote_ratio;


-- ============================================================
-- SECTION 4: SALARY ANALYSIS
-- ============================================================

-- 4a. Average salary by experience level
-- Shows how seniority affects pay
SELECT
    experience_level,
    COUNT(*)                            AS total_records,
    ROUND(MIN(salary_in_usd), 2)       AS min_salary,
    ROUND(MAX(salary_in_usd), 2)       AS max_salary,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary,
    ROUND(STDDEV(salary_in_usd), 2)    AS salary_stddev
FROM salaries
GROUP BY experience_level
ORDER BY avg_salary DESC;

-- 4b. Average salary by employment type
-- Fixed bug: work_year added to GROUP BY to match SELECT
SELECT
    employment_type,
    work_year,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd
FROM salaries
GROUP BY employment_type, work_year
ORDER BY employment_type, work_year;

-- 4c. Average salary by company size
SELECT
    company_size,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd
FROM salaries
GROUP BY company_size
ORDER BY avg_salary_usd DESC;

-- 4d. Average salary by job title (all 50 titles)
SELECT
    job_title,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd
FROM salaries
GROUP BY job_title
ORDER BY avg_salary_usd DESC;


-- ============================================================
-- SECTION 5: TOP JOB TITLES ANALYSIS
-- ============================================================

-- 5a. Top 10 highest paying job titles (min 5 records for reliability)
SELECT
    job_title,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd,
    ROUND(MAX(salary_in_usd), 2)       AS max_salary_usd
FROM salaries
GROUP BY job_title
HAVING COUNT(*) >= 5
ORDER BY avg_salary_usd DESC
LIMIT 10;

-- 5b. Top 10 most common job titles
SELECT
    job_title,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd
FROM salaries
GROUP BY job_title
ORDER BY total_records DESC
LIMIT 10;

-- 5c. Salary ranking across all job titles using window function
-- RANK() assigns the same rank to ties
SELECT
    job_title,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd,
    COUNT(*)                            AS total_records,
    RANK() OVER (ORDER BY AVG(salary_in_usd) DESC) AS salary_rank
FROM salaries
GROUP BY job_title
ORDER BY salary_rank;


-- ============================================================
-- SECTION 6: SALARY TRENDS OVER TIME
-- ============================================================

-- 6a. Overall average salary per year — is pay growing?
SELECT
    work_year,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd,
    ROUND(MAX(salary_in_usd), 2)       AS max_salary_usd,
    ROUND(MIN(salary_in_usd), 2)       AS min_salary_usd
FROM salaries
GROUP BY work_year
ORDER BY work_year;

-- 6b. Salary trend by experience level per year
-- Shows which seniority levels are growing fastest
SELECT
    work_year,
    experience_level,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd
FROM salaries
GROUP BY work_year, experience_level
ORDER BY work_year, avg_salary_usd DESC;

-- 6c. Year-over-year salary change using LAG window function
-- Compares each year's average salary to the previous year
WITH yearly_avg AS (
    SELECT
        work_year,
        ROUND(AVG(salary_in_usd), 2) AS avg_salary_usd
    FROM salaries
    GROUP BY work_year
)
SELECT
    work_year,
    avg_salary_usd,
    LAG(avg_salary_usd) OVER (ORDER BY work_year)                               AS prev_year_salary,
    ROUND(avg_salary_usd - LAG(avg_salary_usd) OVER (ORDER BY work_year), 2)   AS salary_change,
    ROUND(
        (avg_salary_usd - LAG(avg_salary_usd) OVER (ORDER BY work_year))
        / LAG(avg_salary_usd) OVER (ORDER BY work_year) * 100, 2
    )                                                                            AS pct_change
FROM yearly_avg
ORDER BY work_year;


-- ============================================================
-- SECTION 7: REMOTE WORK ANALYSIS
-- ============================================================

-- 7a. Average salary by remote ratio
-- Does remote work correlate with higher pay?
SELECT
    remote_ratio,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd,
    ROUND(MAX(salary_in_usd), 2)       AS max_salary_usd
FROM salaries
GROUP BY remote_ratio
ORDER BY avg_salary_usd DESC;

-- 7b. Remote work trend by year
-- Has remote work increased over time?
SELECT
    work_year,
    remote_ratio,
    COUNT(*)                                                    AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY work_year), 2) AS pct_within_year
FROM salaries
GROUP BY work_year, remote_ratio
ORDER BY work_year, remote_ratio;

-- 7c. Remote ratio breakdown by experience level
-- Are senior roles more or less remote?
SELECT
    experience_level,
    remote_ratio,
    COUNT(*)                                                        AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY experience_level), 2) AS pct_within_exp
FROM salaries
GROUP BY experience_level, remote_ratio
ORDER BY experience_level, remote_ratio;

-- 7d. Average salary by remote ratio AND experience level
SELECT
    experience_level,
    remote_ratio,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd
FROM salaries
GROUP BY experience_level, remote_ratio
ORDER BY experience_level, avg_salary_usd DESC;


-- ============================================================
-- SECTION 8: COMPANY & GEOGRAPHY ANALYSIS
-- ============================================================

-- 8a. Top 10 company locations by average salary
SELECT
    company_location,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd
FROM salaries
GROUP BY company_location
HAVING COUNT(*) >= 5
ORDER BY avg_salary_usd DESC
LIMIT 10;

-- 8b. Salary comparison by company size AND experience level
SELECT
    company_size,
    experience_level,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd
FROM salaries
GROUP BY company_size, experience_level
ORDER BY company_size, avg_salary_usd DESC;

-- 8c. Top employee residence countries by count
SELECT
    employee_residence,
    COUNT(*)                            AS total_records,
    ROUND(AVG(salary_in_usd), 2)       AS avg_salary_usd
FROM salaries
GROUP BY employee_residence
ORDER BY total_records DESC
LIMIT 10;


-- ============================================================
-- SECTION 9: KEY INSIGHTS SUMMARY
-- ============================================================
-- Run these queries last to compile the most important findings.

-- Highest paying experience level
SELECT experience_level, ROUND(AVG(salary_in_usd), 2) AS avg_salary
FROM salaries GROUP BY experience_level ORDER BY avg_salary DESC LIMIT 1;

-- Highest paying employment type
SELECT employment_type, ROUND(AVG(salary_in_usd), 2) AS avg_salary
FROM salaries GROUP BY employment_type ORDER BY avg_salary DESC LIMIT 1;

-- Highest paying company size
SELECT company_size, ROUND(AVG(salary_in_usd), 2) AS avg_salary
FROM salaries GROUP BY company_size ORDER BY avg_salary DESC LIMIT 1;

-- Most common job title
SELECT job_title, COUNT(*) AS total
FROM salaries GROUP BY job_title ORDER BY total DESC LIMIT 1;

-- Highest paying job title (min 5 records)
SELECT job_title, ROUND(AVG(salary_in_usd), 2) AS avg_salary
FROM salaries GROUP BY job_title HAVING COUNT(*) >= 5
ORDER BY avg_salary DESC LIMIT 1;

-- Remote ratio with highest average salary
SELECT remote_ratio, ROUND(AVG(salary_in_usd), 2) AS avg_salary
FROM salaries GROUP BY remote_ratio ORDER BY avg_salary DESC LIMIT 1;
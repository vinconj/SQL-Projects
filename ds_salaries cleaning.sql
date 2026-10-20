-- ============================================================
-- DATA CLEANING SCRIPT: ds_salaries
-- Dataset: Data Science Job Salaries (607 rows, 12 columns)
-- ============================================================

-- ============================================================
-- STEP 0: INDEX COLUMN NOTE (MyUnknownColumn / row_id)
-- ============================================================
-- The first column is a pandas-generated index artifact from CSV export.
-- It carries no analytical value and is not a true primary key.
-- It has been retained in this dataset but EXCLUDED from the duplicate
-- check in Step 2 — including it would mask true duplicates since
-- every row has a unique index number.
-- To drop it in future: ALTER TABLE salaries DROP COLUMN MyUnknownColumn;

-- ============================================================
-- STEP 1: INITIAL INSPECTION
-- ============================================================
 
-- Preview the data
SELECT * FROM salaries LIMIT 10;
 
-- Total row count
SELECT COUNT(*) AS total_rows FROM salaries;
-- Expected: 607 rows

-- ============================================================
-- STEP 2: DUPLICATE CHECK
-- ============================================================
-- IMPORTANT NOTE ON INDEX COLUMN:
-- When the index column (row_id / MyUnknownColumn) is present in the
-- PARTITION BY clause, every row appears unique because each row has
-- a different index number (0, 1, 2, 3...). This masks true duplicates.
-- The index column must be excluded from PARTITION BY for an accurate check.
--
-- Upon removing the index column and re-running the duplicate check,
-- duplicates WERE found in this dataset.
-- Decision: Duplicate records were identified after excluding the index column from the duplicate check. 
-- Because the dataset does not contain a unique employee identifier, 
-- it is impossible to determine whether these records represent true duplicates or 
-- different individuals sharing identical attributes. 
-- Therefore, the records were retained to avoid the risk of removing legitimate observations.
-- since the duplicate rows may represent different individuals with
-- identical job profiles and salaries, which is plausible in this context.
 
WITH duplicates AS (
    SELECT *,
        ROW_NUMBER() OVER ( PARTITION BY work_year, experience_level, employment_type,
                         job_title, salary, salary_currency, salary_in_usd,
                         employee_residence, remote_ratio, company_location, company_size) AS rn
    FROM salaries
)
SELECT *
FROM duplicates
WHERE rn > 1;
-- Result: duplicates found when index column excluded from PARTITION BY
-- Retained intentionally — see note above

-- ============================================================
-- STEP 3: NULL VALUE CHECK
-- ============================================================
-- COUNT() ignores NULLs, so COUNT(*) - COUNT(col) = number of NULLs.
SELECT
	COUNT(*) - COUNT(MyUnknownColumn) AS null_MyUnknownColumn,
	COUNT(*) - COUNT(work_year) AS null_work_year,
	COUNT(*) - COUNT(experience_level) AS null_experience_level,
	COUNT(*) - COUNT(employment_type) AS null_employment_type,
	COUNT(*) - COUNT(job_title) AS null_job_title,
	COUNT(*) - COUNT(salary) AS null_salary,
	COUNT(*) - COUNT(salary_currency) AS null_salary_currency,
	COUNT(*) - COUNT(salary_in_usd) AS null_salary_in_usd,
	COUNT(*) - COUNT(employee_residence) AS null_employee_residence,
	COUNT(*) - COUNT(remote_ratio) AS null_remote_ratio,
	COUNT(*) - COUNT(company_location) AS null_company_location,
	COUNT(*) - COUNT(company_size) AS null_company_size
FROM salaries; -- hence no null values found on salaries table

-- ============================================================
-- STEP 4: STANDARDIZE TEXT COLUMNS (TRIM + UPPER)
-- ============================================================
-- Removes accidental leading/trailing whitespace and enforces
-- consistent uppercase formatting across all categorical columns.
SET SQL_SAFE_UPDATES = 0; -- uncomment if safe mode blocks UPDATEs

SELECT DISTINCT experience_level
FROM salaries; 
-- experience_level (EN, MI, SE, EX)
-- to be sure everything is in older
UPDATE salaries SET experience_level = UPPER(TRIM(experience_level));

SELECT DISTINCT employment_type
FROM salaries;
-- employment_type (FT, PT, CT, FL)
UPDATE salaries SET employment_type = UPPER(TRIM(employment_type));

SELECT DISTINCT job_title
FROM salaries;
-- job_title (free text — trim only, preserve original casing)
UPDATE salaries SET job_title = TRIM(job_title);

SELECT DISTINCT salary_currency
FROM salaries;
-- salary_currency (ISO codes e.g. USD, EUR, GBP)
UPDATE salaries SET salary_currency = UPPER(TRIM(salary_currency));

SELECT DISTINCT employee_residence
FROM salaries;
-- employee_residence (ISO country codes e.g. US, GB, DE)
UPDATE salaries SET employee_residence = UPPER(employee_residence);
UPDATE salaries SET employee_residence = TRIM(employee_residence);

SELECT DISTINCT company_location
FROM salaries;
-- company_location (ISO country codes)
UPDATE salaries SET company_location = UPPER(company_location);
UPDATE salaries SET company_location = TRIM(company_location);

SELECT DISTINCT company_size
FROM salaries;
-- company_size (S, M, L)
UPDATE salaries SET company_size = UPPER(TRIM(company_size));

-- ============================================================
-- STEP 5: DATA TYPE VERIFICATION
-- ============================================================
-- Confirms column types match expected formats before analysis.
 
SHOW COLUMNS FROM salaries;

-- ============================================================
-- STEP 6: NUMERICAL RANGE VALIDATION
-- ============================================================
-- Check for negative values (invalid for all three columns)
SELECT 'salary'        AS col, COUNT(*) AS negative_count FROM salaries WHERE salary < 0
UNION ALL
SELECT 'salary_in_usd',        COUNT(*) FROM salaries WHERE salary_in_usd < 0
UNION ALL
SELECT 'remote_ratio',         COUNT(*) FROM salaries WHERE remote_ratio < 0;
-- Result: all return 0 — no negative values found

-- Valid range check: work_year (expected: 2020–2023)
SELECT DISTINCT work_year FROM salaries ORDER BY work_year;
 
SELECT COUNT(*) AS invalid_years
FROM salaries
WHERE work_year < 2020 OR work_year > 2023;
-- Result: 0 — all years fall within the expected range
 
-- Valid Remote Ratio -> Allowed values are only:0, 50,100
SELECT *
FROM salaries
WHERE remote_ratio NOT IN (0,50,100);
-- Result: 0 — all values are valid

-- ============================================================
-- STEP 7: OUTLIER DETECTION ON SALARY
-- ============================================================
-- Uses the IQR method (industry standard).
-- Outlier boundaries: below Q1 - 1.5*IQR  or  above Q3 + 1.5*IQR
-- NOTE: outliers here are not automatically errors — a $400k senior DS salary in the US is legitimate. 
-- so i just flag and investigate; but not delete.

-- Basic distribution overview
SELECT
    MIN(salary_in_usd)              AS min_salary,
    MAX(salary_in_usd)              AS max_salary,
    ROUND(AVG(salary_in_usd), 2)   AS avg_salary,
    ROUND(STDDEV(salary_in_usd), 2) AS std_dev
FROM salaries;

-- Calculate IQR boundaries
WITH quartiles AS (
    SELECT
        salary_in_usd,
        NTILE(4) OVER (ORDER BY salary_in_usd) AS quartile
    FROM salaries
),
bounds AS (
    SELECT
        MAX(CASE WHEN quartile = 1 THEN salary_in_usd END) AS Q1,
        MAX(CASE WHEN quartile = 3 THEN salary_in_usd END) AS Q3
    FROM quartiles
)
SELECT
    Q1,
    Q3,
    Q3 - Q1                       AS IQR,
    Q1 - 1.5 * (Q3 - Q1)         AS lower_bound,
    Q3 + 1.5 * (Q3 - Q1)         AS upper_bound
FROM bounds;
 
-- View flagged outlier rows
WITH quartiles AS (
    SELECT salary_in_usd,
           NTILE(4) OVER (ORDER BY salary_in_usd) AS quartile
    FROM salaries
),
bounds AS (
    SELECT
        MAX(CASE WHEN quartile = 1 THEN salary_in_usd END) AS Q1,
        MAX(CASE WHEN quartile = 3 THEN salary_in_usd END) AS Q3
    FROM quartiles
)
SELECT
    s.job_title,
    s.experience_level,
    s.company_location,
    s.salary_in_usd,
    CASE
        WHEN s.salary_in_usd < (b.Q1 - 1.5 * (b.Q3 - b.Q1)) THEN 'LOW OUTLIER'
        WHEN s.salary_in_usd > (b.Q3 + 1.5 * (b.Q3 - b.Q1)) THEN 'HIGH OUTLIER'
    END AS outlier_flag
FROM salaries s
CROSS JOIN bounds b
WHERE s.salary_in_usd < (b.Q1 - 1.5 * (b.Q3 - b.Q1))
   OR s.salary_in_usd > (b.Q3 + 1.5 * (b.Q3 - b.Q1))
ORDER BY s.salary_in_usd DESC;
 
-- Outlier count summary
WITH quartiles AS (
    SELECT salary_in_usd,
           NTILE(4) OVER (ORDER BY salary_in_usd) AS quartile
    FROM salaries
),
bounds AS (
    SELECT
        MAX(CASE WHEN quartile = 1 THEN salary_in_usd END) AS Q1,
        MAX(CASE WHEN quartile = 3 THEN salary_in_usd END) AS Q3
    FROM quartiles
)
SELECT
    COUNT(*)                                                                    AS total_outliers,
    SUM(CASE WHEN s.salary_in_usd > (b.Q3 + 1.5*(b.Q3-b.Q1)) THEN 1 ELSE 0 END) AS high_outliers,
    SUM(CASE WHEN s.salary_in_usd < (b.Q1 - 1.5*(b.Q3-b.Q1)) THEN 1 ELSE 0 END) AS low_outliers
FROM salaries s
CROSS JOIN bounds b
WHERE s.salary_in_usd < (b.Q1 - 1.5*(b.Q3-b.Q1))
   OR s.salary_in_usd > (b.Q3 + 1.5*(b.Q3-b.Q1));
-- Decision: retain outliers — values are extreme but plausible for
-- senior data science roles in high-paying markets (e.g. US, CA).

-- ============================================================
-- STEP 8: FINAL VERIFICATION
-- ============================================================
SELECT * FROM salaries;

-- Data Quality Summary
-- Rows examined: 607
-- Duplicates found: 0
-- Null values found: 0
-- Negative salaries found: 0
-- Invalid remote ratios found: 0
-- Text standardized: Yes
-- Outliers reviewed: Yes
-- Dataset ready for EDA: Yes
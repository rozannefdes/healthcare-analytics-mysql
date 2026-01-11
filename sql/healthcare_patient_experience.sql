/* ============================================================
   Healthcare Analytics (State-Level Patient Experience) - MySQL

   PURPOSE
   1) Create database + staging table (raw import)
   2) Build star schema: dimensions + fact table
   3) Clean raw fields (percent + dates) into analysis-ready types
   4) Run analysis queries (Q1–Q20)

   REQUIREMENTS
   - MySQL 8.0+ (uses CTEs and window functions)

   STEPS
   ⁠ 0) DATABASE SETUP
	  1) STAGING TABLE
	  2) DIMENSIONS
	  3) FACT TABLE
	  4) LOAD DIMENSIONS
	  5) LOAD FACT
	  6) VALIDATION
	  7) Q1–Q20
   ============================================================ */

/* ============================================================
   STEP 0) DATABASE SETUP
   ============================================================ */

CREATE DATABASE healthcare_analytics;
USE healthcare_analytics;
SELECT DATABASE();

/* ============================================================
 STEP 1) STAGING TABLE 
   ============================================================ *

CREATE TABLE hcahps_state (
  state VARCHAR(10),
  measure_id VARCHAR(50),
  question TEXT,
  answer_description TEXT,
  answer_percent_raw VARCHAR(50),
  footnote TEXT,
  start_date VARCHAR(20),
  end_date VARCHAR(20)
);

-- After import, validate your load
SELECT COUNT(*) FROM ⁠ hcahps-state ⁠;

/* ============================================================
   STEP 2) STAR SCHEMA TABLES 
   ============================================================ */

CREATE TABLE dim_state (
  state_id INT AUTO_INCREMENT PRIMARY KEY,
  state_code VARCHAR(10) UNIQUE
);

CREATE TABLE dim_measure (
  measure_key INT AUTO_INCREMENT PRIMARY KEY,
  measure_id VARCHAR(50) UNIQUE,
  question TEXT
);

CREATE TABLE dim_answer (
  answer_key INT AUTO_INCREMENT PRIMARY KEY,
  answer_description VARCHAR(255) UNIQUE
);

/* ============================================================
   STEP 3) FACT TABLE  
   ============================================================ */

CREATE TABLE fact_hcahps_state (
  fact_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  measure_key INT NOT NULL,
  answer_key INT NOT NULL,

-- Cleaned survey metric (%). NULL indicates missing / Not Available

  answer_percent DECIMAL(5,2) NULL,
  footnote TEXT,
  start_date DATE,
  end_date DATE,
  FOREIGN KEY (state_id) REFERENCES dim_state(state_id),
  FOREIGN KEY (measure_key) REFERENCES dim_measure(measure_key),
  FOREIGN KEY (answer_key) REFERENCES dim_answer(answer_key)
);

/* ============================================================
   STEP 4) LOAD DIMENSIONS
   ============================================================ */

INSERT INTO dim_state (state_code)
SELECT DISTINCT state
FROM hcahps_state
WHERE state IS NOT NULL AND state <> '';

INSERT INTO dim_measure (measure_id, question)
SELECT DISTINCT measure_id, question
FROM hcahps_state
WHERE measure_id IS NOT NULL AND measure_id <> '';

INSERT INTO dim_answer (answer_description)
SELECT DISTINCT answer_description
FROM hcahps_state
WHERE answer_description IS NOT NULL AND answer_description <> '';

-- Data validation and sanity checks

SELECT COUNT(*) AS staging_rows
FROM ⁠ hcahps-state ⁠;

SHOW COLUMNS FROM ⁠ hcahps-state ⁠;

SELECT DISTINCT State
FROM ⁠ hcahps-state ⁠
WHERE State IS NOT NULL
LIMIT 10;

INSERT INTO dim_state (state_code)
SELECT DISTINCT State
FROM ⁠ hcahps-state ⁠
WHERE State IS NOT NULL AND State <> '';

INSERT INTO dim_measure (measure_id)
SELECT DISTINCT
  ⁠ HCAHPS Measure ID ⁠
FROM ⁠ hcahps-state ⁠
WHERE ⁠ HCAHPS Measure ID ⁠ IS NOT NULL
  AND ⁠ HCAHPS Measure ID ⁠ <> '';
  
INSERT INTO dim_answer (answer_description)
SELECT DISTINCT
  ⁠ HCAHPS Answer Description ⁠
FROM ⁠ hcahps-state ⁠
WHERE ⁠ HCAHPS Answer Description ⁠ IS NOT NULL
  AND ⁠ HCAHPS Answer Description ⁠ <> '';
  
SELECT COUNT(*) FROM dim_state;
SELECT COUNT(*) FROM dim_measure;
SELECT COUNT(*) FROM dim_answer;

/* ============================================================
   STEP 5) LOAD FACT TABLE (CLEANING + FOREIGN KEY MAPPING)
   ============================================================ */
  INSERT INTO fact_hcahps_state (
  state_id, measure_key, answer_key,
  answer_percent, footnote, start_date, end_date
)
SELECT
  s.state_id,
  m.measure_key,
  a.answer_key,
  CASE
    WHEN st.⁠ HCAHPS Answer Percent ⁠ IS NULL THEN NULL
    WHEN TRIM(st.⁠ HCAHPS Answer Percent ⁠) = 'Not Available' THEN NULL
    ELSE CAST(st.⁠ HCAHPS Answer Percent ⁠ AS DECIMAL(5,2))
  END AS answer_percent,
  st.footnote,
  STR_TO_DATE(st.⁠ Start Date ⁠, '%m/%d/%Y'),
  STR_TO_DATE(st.⁠ End Date ⁠, '%m/%d/%Y')
FROM ⁠ hcahps-state ⁠ st
JOIN dim_state s
  ON s.state_code = st.state
JOIN dim_measure m
  ON m.measure_id = st.⁠ HCAHPS Measure ID ⁠
JOIN dim_answer a
  ON a.answer_description = st.⁠ HCAHPS Answer Description ⁠;
  
SELECT COUNT(*) AS fact_rows FROM fact_hcahps_state;
SELECT COUNT(*) AS null_scores FROM fact_hcahps_state WHERE answer_percent IS NULL;
SELECT * FROM fact_hcahps_state LIMIT 10;

/* ============================================================
   STEP 6) DATA VALIDATION / EDA
   ============================================================ */
SELECT 'staging' AS t, COUNT(*) c FROM ⁠ hcahps-state ⁠
UNION ALL SELECT 'fact', COUNT(*) FROM fact_hcahps_state
UNION ALL SELECT 'states', COUNT(*) FROM dim_state
UNION ALL SELECT 'measures', COUNT(*) FROM dim_measure
UNION ALL SELECT 'answers', COUNT(*) FROM dim_answer;

/* ============================================================
   STEP 7) ANALYSIS QUERIES (Q1–Q20)
   ============================================================ */

-- Q1) Total records and numeric coverage

SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN answer_percent IS NULL THEN 1 ELSE 0 END) AS null_answer_percent,
  SUM(CASE WHEN answer_percent IS NOT NULL THEN 1 ELSE 0 END) AS numeric_answer_percent
FROM fact_hcahps_state;

-- Q2) Measures with most "Not Available"

SELECT
  m.measure_id,
  LEFT(m.question, 90) AS question_preview,
  COUNT(*) AS not_available_count
FROM fact_hcahps_state f
JOIN dim_measure m ON f.measure_key = m.measure_key
WHERE f.answer_percent IS NULL
GROUP BY m.measure_id, question_preview
ORDER BY not_available_count DESC;

-- Q3) States with most missing ("Not Available")

SELECT
  s.state_code,
  COUNT(*) AS not_available_count
FROM fact_hcahps_state f
JOIN dim_state s ON f.state_id = s.state_id
WHERE f.answer_percent IS NULL
GROUP BY s.state_code
ORDER BY not_available_count DESC;

-- Q4) Top 10 states by overall average score (numeric only)

SELECT
  s.state_code,
  ROUND(AVG(f.answer_percent), 2) AS avg_score,
  COUNT(f.answer_percent) AS numeric_points
FROM fact_hcahps_state f
JOIN dim_state s ON f.state_id = s.state_id
WHERE f.answer_percent IS NOT NULL
GROUP BY s.state_code
ORDER BY avg_score DESC
LIMIT 10;

-- Q5) Bottom 10 states by overall average score

SELECT
  s.state_code,
  ROUND(AVG(f.answer_percent), 2) AS avg_score,
  COUNT(f.answer_percent) AS numeric_points
FROM fact_hcahps_state f
JOIN dim_state s ON f.state_id = s.state_id
WHERE f.answer_percent IS NOT NULL
GROUP BY s.state_code
ORDER BY avg_score ASC
LIMIT 10;

-- Q6) National average by measure (top 10 best)

SELECT
  m.measure_id,
  LEFT(m.question, 90) AS question_preview,
  ROUND(AVG(f.answer_percent), 2) AS national_avg
FROM fact_hcahps_state f
JOIN dim_measure m ON f.measure_key = m.measure_key
WHERE f.answer_percent IS NOT NULL
GROUP BY m.measure_id, question_preview
ORDER BY national_avg DESC
LIMIT 10;

-- Q7) National average by measure (bottom 10 worst)

SELECT
  m.measure_id,
  LEFT(m.question, 90) AS question_preview,
  ROUND(AVG(f.answer_percent), 2) AS national_avg
FROM fact_hcahps_state f
JOIN dim_measure m ON f.measure_key = m.measure_key
WHERE f.answer_percent IS NOT NULL
GROUP BY m.measure_id, question_preview
ORDER BY national_avg ASC
LIMIT 10;

-- Q8) Rank states per measure (Top 3 states for each measure)

WITH state_measure AS (
  SELECT
    m.measure_id,
    s.state_code,
    AVG(f.answer_percent) AS avg_percent
  FROM fact_hcahps_state f
  JOIN dim_state s ON f.state_id = s.state_id
  JOIN dim_measure m ON f.measure_key = m.measure_key
  WHERE f.answer_percent IS NOT NULL
  GROUP BY m.measure_id, s.state_code
),
ranked AS (
  SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY measure_id ORDER BY avg_percent DESC) AS rnk
  FROM state_measure
)
SELECT measure_id, state_code, ROUND(avg_percent,2) AS avg_percent, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY measure_id, rnk, avg_percent DESC;

-- Q9) Rank states per measure (Bottom 3)

WITH state_measure AS (
  SELECT
    m.measure_id,
    s.state_code,
    AVG(f.answer_percent) AS avg_percent
  FROM fact_hcahps_state f
  JOIN dim_state s ON f.state_id = s.state_id
  JOIN dim_measure m ON f.measure_key = m.measure_key
  WHERE f.answer_percent IS NOT NULL
  GROUP BY m.measure_id, s.state_code
),
ranked AS (
  SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY measure_id ORDER BY avg_percent ASC) AS rnk
  FROM state_measure
)
SELECT measure_id, state_code, ROUND(avg_percent,2) AS avg_percent, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY measure_id, rnk, avg_percent ASC;

-- Q10) For each state, best performing measure

WITH state_measure AS (
  SELECT
    s.state_code,
    m.measure_id,
    LEFT(m.question, 90) AS question_preview,
    AVG(f.answer_percent) AS avg_percent
  FROM fact_hcahps_state f
  JOIN dim_state s ON f.state_id = s.state_id
  JOIN dim_measure m ON f.measure_key = m.measure_key
  WHERE f.answer_percent IS NOT NULL
  GROUP BY s.state_code, m.measure_id, question_preview
),
ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY state_code ORDER BY avg_percent DESC) AS rn
  FROM state_measure
)
SELECT state_code, measure_id, question_preview, ROUND(avg_percent,2) AS avg_percent
FROM ranked
WHERE rn = 1
ORDER BY avg_percent DESC;

-- Q11) For each state, worst performing measure

WITH state_measure AS (
  SELECT
    s.state_code,
    m.measure_id,
    LEFT(m.question, 90) AS question_preview,
    AVG(f.answer_percent) AS avg_percent
  FROM fact_hcahps_state f
  JOIN dim_state s ON f.state_id = s.state_id
  JOIN dim_measure m ON f.measure_key = m.measure_key
  WHERE f.answer_percent IS NOT NULL
  GROUP BY s.state_code, m.measure_id, question_preview
),
ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY state_code ORDER BY avg_percent ASC) AS rn
  FROM state_measure
)
SELECT state_code, measure_id, question_preview, ROUND(avg_percent,2) AS avg_percent
FROM ranked
WHERE rn = 1
ORDER BY avg_percent ASC;

-- Q12) Consistency check: Std dev per state (variation)

SELECT
  s.state_code,
  ROUND(AVG(f.answer_percent), 2) AS avg_score,
  ROUND(STDDEV_POP(f.answer_percent), 2) AS std_dev
FROM fact_hcahps_state f
JOIN dim_state s ON f.state_id = s.state_id
WHERE f.answer_percent IS NOT NULL
GROUP BY s.state_code
ORDER BY std_dev ASC;

-- Q13) Score distribution buckets

SELECT
  CASE
    WHEN answer_percent < 20 THEN '00-19'
    WHEN answer_percent < 40 THEN '20-39'
    WHEN answer_percent < 60 THEN '40-59'
    WHEN answer_percent < 80 THEN '60-79'
    ELSE '80-100'
  END AS bucket,
  COUNT(*) AS cnt
FROM fact_hcahps_state
WHERE answer_percent IS NOT NULL
GROUP BY bucket
ORDER BY bucket;

-- Q14) Measures with most responses (coverage)

SELECT
  m.measure_id,
  COUNT(f.answer_percent) AS numeric_points
FROM fact_hcahps_state f
JOIN dim_measure m ON f.measure_key = m.measure_key
WHERE f.answer_percent IS NOT NULL
GROUP BY m.measure_id
ORDER BY numeric_points DESC;

-- Q15) Compare two measures side-by-side (state gap)

WITH m1 AS (
  SELECT s.state_code, AVG(f.answer_percent) AS avg1
  FROM fact_hcahps_state f
  JOIN dim_state s ON f.state_id = s.state_id
  JOIN dim_measure m ON f.measure_key = m.measure_key
  WHERE f.answer_percent IS NOT NULL AND m.measure_id = 'H_COMP_1'
  GROUP BY s.state_code
),
m2 AS (
  SELECT s.state_code, AVG(f.answer_percent) AS avg2
  FROM fact_hcahps_state f
  JOIN dim_state s ON f.state_id = s.state_id
  JOIN dim_measure m ON f.measure_key = m.measure_key
  WHERE f.answer_percent IS NOT NULL AND m.measure_id = 'H_COMP_2'
  GROUP BY s.state_code
)
SELECT
  COALESCE(m1.state_code, m2.state_code) AS state_code,
  ROUND(m1.avg1,2) AS measure1_avg,
  ROUND(m2.avg2,2) AS measure2_avg,
  ROUND((m1.avg1 - m2.avg2),2) AS gap
FROM m1
JOIN m2 ON m1.state_code = m2.state_code
ORDER BY gap DESC;

-- Q16) Time range coverage (min/max)

SELECT
  MIN(start_date) AS min_start_date,
  MAX(end_date) AS max_end_date
FROM fact_hcahps_state;

-- Q17) Top answers by average percent (answer category performance)

SELECT
  a.answer_description,
  ROUND(AVG(f.answer_percent),2) AS avg_percent,
  COUNT(f.answer_percent) AS numeric_points
FROM fact_hcahps_state f
JOIN dim_answer a ON f.answer_key = a.answer_key
WHERE f.answer_percent IS NOT NULL
GROUP BY a.answer_description
ORDER BY avg_percent DESC;

-- Q18) States with strongest “high scores share” (>=80)

SELECT
  s.state_code,
  ROUND(100 * AVG(CASE WHEN f.answer_percent >= 80 THEN 1 ELSE 0 END), 2) AS pct_scores_80_plus
FROM fact_hcahps_state f
JOIN dim_state s ON f.state_id = s.state_id
WHERE f.answer_percent IS NOT NULL
GROUP BY s.state_code
ORDER BY pct_scores_80_plus DESC
LIMIT 10;

-- Q19) States with lowest share of high scores (>=80)

SELECT
  s.state_code,
  ROUND(100 * AVG(CASE WHEN f.answer_percent >= 80 THEN 1 ELSE 0 END), 2) AS pct_scores_80_plus
FROM fact_hcahps_state f
JOIN dim_state s ON f.state_id = s.state_id
WHERE f.answer_percent IS NOT NULL
GROUP BY s.state_code
ORDER BY pct_scores_80_plus ASC
LIMIT 10;

-- Q20) “Not Available” rate by measure (percentage)

SELECT
  m.measure_id,
  ROUND(100 * AVG(CASE WHEN f.answer_percent IS NULL THEN 1 ELSE 0 END), 2) AS not_available_rate_pct
FROM fact_hcahps_state f
JOIN dim_measure m ON f.measure_key = m.measure_key
GROUP BY m.measure_id
ORDER BY not_available_rate_pct DESC;

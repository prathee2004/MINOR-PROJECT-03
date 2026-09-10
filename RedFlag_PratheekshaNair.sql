-- =====================================================================
-- RedFlag — Fraud Detection Project
-- Name: Pratheeksha
-- =====================================================================

USE redflag;

-- =====================================================================
-- P1: VELOCITY FRAUD
-- Users with 30 or more transactions on the same calendar date
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS txn_date,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30;

-- =====================================================================
-- P2: ROUND-AMOUNT CLUSTERING
-- Users with 15 or more transactions using specified round amounts
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS round_amount_transactions
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15;

-- =====================================================================
-- P3: CARD TESTING
-- Users with 30 or more transactions under ₹10 in one day
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS txn_date,
    COUNT(*) AS small_transactions
FROM transactions
WHERE amount < 10
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30;

-- =====================================================================
-- P4: FAILED-THEN-SUCCEEDED
-- Users with 20 or more FAILED transactions
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS failed_transactions
FROM transactions
WHERE status = 'FAILED'
GROUP BY user_id
HAVING COUNT(*) >= 20;

-- =====================================================================
-- P5: ODD-HOUR CONCENTRATION
-- Users with at least 30 transactions and 80% or more between 2 AM–4 AM
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
    ) AS odd_hour_transactions,
    ROUND(
        SUM(
            CASE
                WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS odd_hour_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
   AND SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
   ) / COUNT(*) >= 0.80;
   
   -- =====================================================================
-- P6: MULE ACCOUNTS
-- Users with 8 or more CREDIT transactions
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS credit_transactions
FROM transactions
WHERE txn_type = 'CREDIT'
GROUP BY user_id
HAVING COUNT(*) >= 8;

-- =====================================================================
-- P7: REFUND ABUSE
-- Users with 20 or more transactions and refund ratio above 40%
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
    ) AS refund_transactions,
    ROUND(
        SUM(
            CASE
                WHEN txn_type = 'REFUND' THEN 1
                ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS refund_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
   AND SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
   ) / COUNT(*) > 0.40;
   
   -- =====================================================================
-- P8: MERCHANT COLLUSION
-- Top 5 users by transaction value account for more than 60%
-- of the merchant's total transaction value
-- Expected: exactly 15 merchants
-- =====================================================================

WITH user_merchant_totals AS (
    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_total_value
    FROM transactions
    GROUP BY merchant_id, user_id
),
ranked_users AS (
    SELECT
        merchant_id,
        user_id,
        user_total_value,
        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_total_value DESC
        ) AS user_rank
    FROM user_merchant_totals
),
merchant_totals AS (
    SELECT
        merchant_id,
        SUM(amount) AS merchant_total_value
    FROM transactions
    GROUP BY merchant_id
),
top_five_totals AS (
    SELECT
        merchant_id,
        SUM(user_total_value) AS top_five_value
    FROM ranked_users
    WHERE user_rank <= 5
    GROUP BY merchant_id
)
SELECT
    t.merchant_id,
    t.top_five_value,
    m.merchant_total_value,
    ROUND(
        t.top_five_value / m.merchant_total_value * 100,
        2
    ) AS top_five_percentage
FROM top_five_totals t
JOIN merchant_totals m
    ON t.merchant_id = m.merchant_id
WHERE t.top_five_value / m.merchant_total_value > 0.60
ORDER BY t.merchant_id;

-- =====================================================================
-- P9: JUST-UNDER-THRESHOLD
-- Users with 10 or more transactions exactly at ₹9,999
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS threshold_transactions
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10;

-- =====================================================================
-- P10: DORMANT-THEN-ACTIVE
-- Users with a 90+ day gap followed by 15+ transactions
-- =====================================================================

WITH transaction_gaps AS (
    SELECT
        user_id,
        txn_time,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
),
dormant_users AS (
    SELECT DISTINCT
        user_id,
        txn_time AS active_start
    FROM transaction_gaps
    WHERE previous_txn_time IS NOT NULL
      AND DATEDIFF(txn_time, previous_txn_time) >= 90
)
SELECT
    d.user_id,
    d.active_start,
    COUNT(t.user_id) AS transactions_after_gap
FROM dormant_users d
JOIN transactions t
    ON t.user_id = d.user_id
   AND t.txn_time > d.active_start
GROUP BY d.user_id, d.active_start
HAVING COUNT(t.user_id) >= 15;

-- =====================================================================
-- P11: VELOCITY SPIKE — FULL DIAGNOSTIC + MAIN QUERY
-- Run each section separately and record the output of each
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1: Sanity check the transactions table itself
-- ---------------------------------------------------------------------
SELECT
    COUNT(*) AS total_txns,
    COUNT(DISTINCT user_id) AS total_users,
    MIN(txn_time) AS earliest_txn,
    MAX(txn_time) AS latest_txn
FROM transactions;


-- ---------------------------------------------------------------------
-- STEP 2: Check the column type of txn_time
-- (Use whichever works for your engine — try the first, fall back to the second)
-- ---------------------------------------------------------------------
DESCRIBE transactions;

-- If DESCRIBE doesn't work on your engine, use this instead:
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'transactions';


-- ---------------------------------------------------------------------
-- STEP 3: Inspect one known seeded user's monthly transaction pattern
-- Replace '<SEEDED_USER_ID>' with an actual seeded user_id from your list
-- ---------------------------------------------------------------------
SELECT
    user_id,
    YEAR(txn_time) AS txn_year,
    MONTH(txn_time) AS txn_month,
    COUNT(*) AS monthly_count
FROM transactions
WHERE user_id = '<SEEDED_USER_ID>'
GROUP BY user_id, YEAR(txn_time), MONTH(txn_time)
ORDER BY txn_year, txn_month;


-- ---------------------------------------------------------------------
-- STEP 4: The main P11 query (unchanged — already logically correct)
-- ---------------------------------------------------------------------
WITH monthly_counts AS (
    SELECT
        user_id,
        YEAR(txn_time) AS txn_year,
        MONTH(txn_time) AS txn_month,
        COUNT(*) AS monthly_count
    FROM transactions
    GROUP BY
        user_id,
        YEAR(txn_time),
        MONTH(txn_time)
),

user_stats AS (
    SELECT
        user_id,
        AVG(monthly_count) AS avg_monthly_count,
        MAX(monthly_count) AS peak_monthly_count
    FROM monthly_counts
    GROUP BY user_id
)

SELECT
    user_id,
    peak_monthly_count AS peak_monthly_transactions,
    ROUND(avg_monthly_count, 2) AS average_monthly_transactions,
    ROUND(
        peak_monthly_count / NULLIF(avg_monthly_count, 0),
        2
    ) AS spike_ratio
FROM user_stats
WHERE peak_monthly_count >= 20
  AND peak_monthly_count >= 5 * avg_monthly_count
ORDER BY user_id;

 -- =====================================================================
-- P12: GEOGRAPHIC IMPOSSIBILITY
-- Consecutive transactions in different cities within 60 minutes
-- Expected: exactly 15 suspect users
-- =====================================================================

WITH transaction_sequence AS (
    SELECT
        user_id,
        txn_time,
        city,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time,
        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_city
    FROM transactions
),
suspicious_users AS (
    SELECT DISTINCT
        user_id
    FROM transaction_sequence
    WHERE previous_city IS NOT NULL
      AND city <> previous_city
      AND TIMESTAMPDIFF(
            MINUTE,
            previous_txn_time,
            txn_time
          ) <= 60
)
SELECT
    user_id
FROM suspicious_users
ORDER BY user_id;
      


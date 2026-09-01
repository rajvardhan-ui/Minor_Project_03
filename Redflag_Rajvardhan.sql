-- =====================================================================
-- RedFlag — Fraud Detection Submission
-- Student: <Your Name>  |  Batch: DA-DS-1
-- =====================================================================

USE redflag;

-- =====================================================================
-- PATTERN 1 · VELOCITY FRAUD
-- What I'm looking for: Users with 30 or more distinct transactions on any one calendar date.
-- Expected suspects: ~50
-- =====================================================================

SELECT 
    user_id,
    DATE(txn_time) AS txn_date,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30;

-- My findings: 50 suspect user-days flagged.
-- Top examples: User ID [XXXXX] on [YYYY-MM-DD].


-- =====================================================================
-- PATTERN 2 · ROUND-AMOUNT CLUSTERING
-- What I'm looking for: Users with 15+ transactions where amount is exactly round (100, 200, 500, etc.).
-- Expected suspects: 25
-- =====================================================================

SELECT 
    user_id,
    COUNT(*) AS round_amount_count
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15;

-- My findings: 25 suspects flagged.
-- Top examples: User ID [XXXXX].


-- =====================================================================
-- PATTERN 3 · CARD TESTING
-- What I'm looking for: Users hitting micro-amounts (< ₹10) at high frequency (30+ per day).
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS txn_date,
    COUNT(*) AS low_amount_count
FROM transactions
WHERE amount < 10
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30;

-- My findings: 20 suspects flagged.


-- =====================================================================
-- PATTERN 4 · FAILED-THEN-SUCCEEDED PAIRS
-- What I'm looking for: Users with an abnormally high frequency of failed transactions (>= 20).
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS failed_count
FROM redflag.transactions
WHERE status = 'FAILED'
GROUP BY user_id
HAVING COUNT(*) >= 20;

-- My findings: 25 suspects flagged.


-- =====================================================================
-- PATTERN 5 · ODD-HOUR CONCENTRATION
-- What I'm looking for: Users performing 80%+ of transactions during late odd hours (2 AM to 4 AM).
-- =====================================================================

SELECT
    user_id,
    SUM(CASE WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1 ELSE 0 END) / COUNT(*) AS odd_hour_ratio
FROM transactions
GROUP BY user_id
HAVING SUM(CASE WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1 ELSE 0 END) / COUNT(*) >= 0.80;

-- My findings: 20 suspects flagged.


-- =====================================================================
-- PATTERN 6 · MULE ACCOUNTS
-- What I'm looking for: Accounts experiencing immediate debit outflows within 30 minutes of a credit influx.
-- =====================================================================

SELECT t1.*
FROM redflag.transactions t1
WHERE t1.txn_type = 'CREDIT'
  AND EXISTS (
    SELECT 1 
    FROM redflag.transactions t2
    WHERE t2.user_id = t1.user_id
      AND t2.txn_type = 'DEBIT'
      AND t2.txn_time >= t1.txn_time 
      AND t2.txn_time <= t1.txn_time + INTERVAL 30 MINUTE
  );

-- My findings: 338 suspects flagged.


-- =====================================================================
-- PATTERN 7 · REFUND ABUSE
-- What I'm looking for: Users displaying an abnormally high ratio of refund transactions (> 40%).
-- =====================================================================

SELECT 
    user_id
FROM redflag.transactions
GROUP BY user_id
HAVING (SUM(CASE WHEN txn_type = 'REFUND' THEN 1 ELSE 0 END) / COUNT(*)) > 0.40;

-- My findings: 24 suspects flagged.


-- =====================================================================
-- PATTERN 8 · MERCHANT COLLUSION
-- What I'm looking for: Merchants who derive more than 60% of their processing volume from just their top 5 users.
-- =====================================================================

WITH MerchantTotal AS (
    SELECT merchant_id, SUM(amount) AS total_merchant_volume
    FROM redflag.transactions
    GROUP BY merchant_id
),
UserMerchantVolume AS (
    SELECT merchant_id, user_id, SUM(amount) AS user_volume,
           ROW_NUMBER() OVER (PARTITION BY merchant_id ORDER BY SUM(amount) DESC) AS user_rank
    FROM redflag.transactions
    GROUP BY merchant_id, user_id
),
Top5Volume AS (
    SELECT merchant_id, SUM(user_volume) AS top_5_volume
    FROM UserMerchantVolume
    WHERE user_rank <= 5
    GROUP BY merchant_id
)
SELECT 
    t5.merchant_id,
    t5.top_5_volume,
    mt.total_merchant_volume,
    (t5.top_5_volume / mt.total_merchant_volume) AS top_5_ratio
FROM Top5Volume t5
JOIN MerchantTotal mt ON t5.merchant_id = mt.merchant_id
WHERE (t5.top_5_volume / mt.total_merchant_volume) > 0.60;

-- My findings: 15 suspects flagged.


-- =====================================================================
-- PATTERN 9 · JUST-UNDER-THRESHOLD
-- What I'm looking for: Users splitting structured payments repeatedly at exactly ₹9,999 to bypass regulatory reporting limits.
-- =====================================================================

SELECT 
    user_id,
    COUNT(*) AS threshold_txn_count
FROM redflag.transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10;

-- My findings: 20 suspects flagged.


-- =====================================================================
-- PATTERN 10 · DORMANT-THEN-ACTIVE
-- What I'm looking for: Sudden transaction bursts occurring immediately after a 90+ day gap of user silence.
-- =====================================================================

WITH TxnGaps AS (
    SELECT user_id, txn_time,
           LAG(txn_time) OVER (PARTITION BY user_id ORDER BY txn_time) AS prev_txn_time
    FROM redflag.transactions
),
DormancyEnd AS (
    SELECT user_id, txn_time AS reactivation_time
    FROM TxnGaps
    WHERE DATEDIFF(txn_time, prev_txn_time) >= 90
)
SELECT 
    t.user_id,
    COUNT(*) AS subsequent_transaction_count
FROM redflag.transactions t
JOIN DormancyEnd d ON t.user_id = d.user_id
WHERE t.txn_time >= d.reactivation_time
GROUP BY t.user_id;

-- My findings: 174 suspects flagged.


-- =====================================================================
-- PATTERN 11 · VELOCITY SPIKE
-- What I'm looking for: Users whose absolute monthly peak transaction volume exceeds 3x their historical monthly average baseline.
-- =====================================================================

WITH MonthlyCounts AS (
    SELECT 
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m') AS txn_month,
        COUNT(*) AS monthly_count
    FROM redflag.transactions
    GROUP BY user_id, DATE_FORMAT(txn_time, '%Y-%m')
),
UserMetrics AS (
    SELECT 
        user_id,
        MAX(monthly_count) AS peak_month_volume,
        AVG(monthly_count) AS historical_average_volume
    FROM MonthlyCounts
    GROUP BY user_id
)
SELECT 
    user_id,
    peak_month_volume,
    ROUND(historical_average_volume, 2) AS avg_monthly_volume,
    ROUND(peak_month_volume / historical_average_volume, 2) AS spike_ratio
FROM UserMetrics
WHERE peak_month_volume > (historical_average_volume * 3);

-- My findings: 62 suspects flagged.


-- =====================================================================
-- PATTERN 12 · GEOGRAPHIC IMPOSSIBILITY
-- What I'm looking for: Users with sequential city changes occurring under a physically impossible travel window (<= 60 mins).
-- =====================================================================

WITH OrderedTxns AS (
    SELECT 
        user_id,
        txn_time,
        city,
        LAG(city) OVER (PARTITION BY user_id ORDER BY txn_time) AS prev_city,
        LAG(txn_time) OVER (PARTITION BY user_id ORDER BY txn_time) AS prev_time
    FROM redflag.transactions
)
SELECT 
    user_id,
    prev_time AS first_txn_time,
    prev_city AS first_city,
    txn_time AS second_txn_time,
    city AS second_city,
    TIMESTAMPDIFF(MINUTE, prev_time, txn_time) AS minutes_between_txns
FROM OrderedTxns
WHERE prev_city IS NOT NULL 
  AND city <> prev_city 
  AND TIMESTAMPDIFF(MINUTE, prev_time, txn_time) <= 60;

-- My findings: 80 suspects flagged.
-- Top examples: User ID 14741 transacting between Vadodara and Thiruvananthapuram.

-- ============================================================
-- MatMind x Customer Intelligence Project
-- Step 2: Customer Segmentation & Analysis (SQL)
-- Author: Akl
-- Target DB: SQLite / PostgreSQL / DuckDB compatible
--
-- HOW TO USE:
--   1. Import customers_enriched.csv as table "customers"
--   2. Run each query block in order
--   3. Each query has a business question it answers
-- ============================================================


-- ============================================================
-- SETUP: Create the table (SQLite syntax)
-- If using PostgreSQL, adjust column types accordingly
-- ============================================================

-- DROP TABLE IF EXISTS customers;
-- CREATE TABLE customers AS
--   SELECT * FROM read_csv_auto('customers_enriched.csv');   -- DuckDB
-- OR use your DB import tool for SQLite/PostgreSQL.


-- ============================================================
-- KEY QUESTION 1:
-- "Who are the genuinely loyal customers vs those who
--  only buy when there is a discount?"
-- ============================================================

-- Q1A: HEAD-TO-HEAD COMPARISON — Loyal vs Promo-Only
SELECT
    CASE
        WHEN is_loyal_value_sat = 1 AND promo_dependency_score < 50
            THEN 'Genuinely Loyal'
        WHEN is_loyal_value_sat = 0 AND promo_dependency_score = 100
            THEN 'Promo-Only Buyers'
        WHEN promo_dependency_score BETWEEN 50 AND 99
            THEN 'Promo-Influenced'
        ELSE 'Low-Engagement'
    END                                        AS buyer_type,

    COUNT(*)                                   AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)
                                               AS pct_of_base,
    ROUND(AVG(purchase_amount_usd), 2)         AS avg_spend,
    ROUND(AVG(previous_purchases), 1)          AS avg_prev_purchases,
    ROUND(AVG(review_rating), 2)               AS avg_rating,
    ROUND(AVG(estimated_annual_revenue), 2)    AS avg_annual_revenue,
    ROUND(AVG(value_score), 2)                 AS avg_value_score

FROM customers
GROUP BY buyer_type
ORDER BY avg_annual_revenue DESC;


-- Q1B: TOP 20% (Champions) vs BOTTOM 20% (At-Risk) — Full Profile
SELECT
    value_tier,
    COUNT(*)                                            AS n,
    ROUND(AVG(age), 1)                                  AS avg_age,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(previous_purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dependency,
    ROUND(AVG(review_rating), 2)                        AS avg_rating,
    ROUND(SUM(estimated_annual_revenue), 0)             AS total_annual_revenue,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_revenue,
    -- Revenue concentration
    ROUND(SUM(estimated_annual_revenue) * 100.0 /
          (SELECT SUM(estimated_annual_revenue) FROM customers), 1)
                                                        AS revenue_share_pct

FROM customers
WHERE value_tier IN ('Champions', 'At-Risk')
GROUP BY value_tier
ORDER BY avg_annual_revenue DESC;


-- Q1C: REPEAT PURCHASE BEHAVIOR — Which profiles show strongest repeat buying?
SELECT
    customer_segment,
    COUNT(*)                                            AS n,
    ROUND(AVG(previous_purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(purchase_frequency_per_year), 1)          AS avg_freq_per_year,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_revenue,
    -- What % of this segment buys weekly+
    ROUND(SUM(CASE WHEN purchase_frequency_per_year >= 26 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                        AS pct_high_frequency

FROM customers
GROUP BY customer_segment
ORDER BY avg_prev_purchases DESC;


-- ============================================================
-- KEY QUESTION 2:
-- "What behavioral patterns today predict high customer
--  value over time?"
-- ============================================================

-- Q2A: BEHAVIORAL PATTERNS OF HIGH-VALUE vs LOW-VALUE CUSTOMERS
SELECT
    value_tier,
    -- Spending behavior
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    MIN(purchase_amount_usd)                            AS min_spend,
    MAX(purchase_amount_usd)                            AS max_spend,
    -- Tenure
    ROUND(AVG(previous_purchases), 1)                   AS avg_prev_purchases,
    -- Frequency
    ROUND(AVG(purchase_frequency_per_year), 1)          AS avg_freq_per_year,
    -- Promo reliance
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    -- Satisfaction
    ROUND(AVG(satisfaction_flag) * 100, 1)              AS pct_satisfied,
    -- Subscription
    ROUND(AVG(subscription_status_flag) * 100, 1)       AS pct_subscribed,
    -- Premium shipping preference
    ROUND(SUM(CASE WHEN shipping_type IN ('Express','Next Day Air')
              THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_premium_shipping

FROM customers
GROUP BY value_tier
ORDER BY avg_spend DESC;


-- Q2B: EARLY SIGNALS OF FUTURE VALUE
--      Customers with low previous_purchases (new-ish) but high spend
--      → these are your "high potential" new customers to nurture
SELECT
    CASE
        WHEN previous_purchases <= 5  THEN 'New (0-5 prev)'
        WHEN previous_purchases <= 15 THEN 'Growing (6-15 prev)'
        WHEN previous_purchases <= 30 THEN 'Established (16-30 prev)'
        ELSE 'Veteran (31+ prev)'
    END                                                 AS tenure_band,

    COUNT(*)                                            AS n,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(review_rating), 2)                        AS avg_rating,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(satisfaction_flag) * 100, 1)              AS pct_satisfied,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_rev,

    -- High spend + low promo = organic value signal
    ROUND(SUM(CASE WHEN purchase_amount_usd >= 75
                    AND promo_dependency_score = 0
              THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_organic_highspend

FROM customers
GROUP BY tenure_band
ORDER BY avg_spend DESC;


-- ============================================================
-- KEY QUESTION 3:
-- "Which geographies and demographics are commercially
--  underlevered?"
-- ============================================================

-- Q3A: TOP 20 STATES BY ORGANIC DEMAND (high spend, low promo dependency)
SELECT
    location                                            AS state,
    COUNT(*)                                            AS customer_count,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_rev,
    ROUND(SUM(estimated_annual_revenue), 0)             AS total_annual_rev,
    ROUND(AVG(satisfaction_flag) * 100, 1)              AS pct_satisfied,

    -- Organic demand score = high spend + low promo + high satisfaction
    ROUND(
        (AVG(purchase_amount_usd) / 100.0 * 0.4)
        + ((100 - AVG(promo_dependency_score)) / 100.0 * 0.4)
        + (AVG(satisfaction_flag) * 0.2)
    , 3)                                                AS organic_demand_score,

    -- Underlevered flag: high organic demand but few customers
    CASE WHEN COUNT(*) < 80
         AND AVG(purchase_amount_usd) > 58
         THEN 'UNDERLEVERED'
         ELSE 'Normal'
    END                                                 AS opportunity_flag

FROM customers
GROUP BY location
ORDER BY organic_demand_score DESC
LIMIT 20;


-- Q3B: AGE BAND COMMERCIAL ANALYSIS
SELECT
    age_band,
    COUNT(*)                                            AS n,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(previous_purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_rev,
    ROUND(SUM(estimated_annual_revenue), 0)             AS total_annual_rev,
    ROUND(AVG(satisfaction_flag) * 100, 1)              AS pct_satisfied,
    -- Most common category for each age band
    (SELECT category FROM customers c2
     WHERE c2.age_band = c1.age_band
     GROUP BY category
     ORDER BY COUNT(*) DESC LIMIT 1)                    AS top_category

FROM customers c1
GROUP BY age_band
ORDER BY avg_annual_rev DESC;


-- Q3C: GENDER BREAKDOWN (quick check for targeting gaps)
SELECT
    gender,
    COUNT(*)                                            AS n,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_rev,
    ROUND(AVG(satisfaction_flag) * 100, 1)              AS pct_satisfied,
    ROUND(AVG(is_loyal_value_sat) * 100, 1)             AS pct_loyal

FROM customers
GROUP BY gender
ORDER BY avg_annual_rev DESC;


-- ============================================================
-- KEY QUESTION 4:
-- "How should the brand restructure its promotional strategy
--  to protect margins without losing volume?"
-- ============================================================

-- Q4A: PROMO REVENUE DEPENDENCY ANALYSIS
--      "What percentage of revenue came from promo-driven purchases?"
SELECT
    CASE
        WHEN promo_dependency_score = 100  THEN 'Full Promo (both discount+code)'
        WHEN promo_dependency_score = 50   THEN 'Partial Promo (one of two)'
        WHEN promo_dependency_score = 0    THEN 'No Promo (organic)'
    END                                                 AS promo_status,

    COUNT(*)                                            AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)  AS pct_of_customers,
    ROUND(SUM(estimated_annual_revenue), 0)             AS total_annual_rev,
    ROUND(SUM(estimated_annual_revenue) * 100.0 /
          (SELECT SUM(estimated_annual_revenue) FROM customers), 1)
                                                        AS pct_of_revenue,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(previous_purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(review_rating), 2)                        AS avg_rating

FROM customers
GROUP BY promo_status
ORDER BY total_annual_rev DESC;


-- Q4B: SAFE-TO-SUNSET PROMO SEGMENTS
--      Champions with low promo dependency → sunset discounts first
SELECT
    customer_segment,
    COUNT(*)                                            AS n,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(previous_purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_rev,

    -- Sunset readiness score: high value + low promo dep = safe to remove discounts
    ROUND(
        (AVG(value_score) / 100.0 * 0.6) +
        ((100 - AVG(promo_dependency_score)) / 100.0 * 0.4)
    * 100, 1)                                           AS sunset_readiness_score,

    CASE
        WHEN AVG(value_score) >= 57.78
         AND AVG(promo_dependency_score) < 50
        THEN 'SUNSET NOW'
        WHEN AVG(value_score) >= 44.69
         AND AVG(promo_dependency_score) < 75
        THEN 'SUNSET Q2'
        WHEN AVG(promo_dependency_score) = 100
         AND AVG(value_score) < 32.97
        THEN 'KEEP PROMO (retention risk)'
        ELSE 'MONITOR'
    END                                                 AS sunset_recommendation

FROM customers
GROUP BY customer_segment
ORDER BY sunset_readiness_score DESC;


-- Q4C: SEASON × PROMO INTERACTION
--      Does promo dependency spike in certain seasons?
SELECT
    season,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    COUNT(*)                                            AS n,
    ROUND(SUM(estimated_annual_revenue), 0)             AS total_rev,
    -- High-spend, low-promo = organic season
    CASE WHEN AVG(purchase_amount_usd) >
              (SELECT AVG(purchase_amount_usd) FROM customers)
         AND AVG(promo_dependency_score) <
              (SELECT AVG(promo_dependency_score) FROM customers)
         THEN 'Organic Strong Season'
         ELSE 'Promo-Driven Season'
    END                                                 AS season_type

FROM customers
GROUP BY season
ORDER BY avg_spend DESC;


-- ============================================================
-- KEY QUESTION 5:
-- "What does the brand's ideal customer profile look like?"
-- ============================================================

-- Q5A: IDEAL CUSTOMER PROFILE — Statistical Portrait of Champions
SELECT
    'Ideal Customer Profile'                            AS profile,
    ROUND(AVG(age), 0)                                  AS median_age,
    (SELECT gender FROM customers
     WHERE value_tier = 'Champions'
     GROUP BY gender ORDER BY COUNT(*) DESC LIMIT 1)   AS dominant_gender,
    (SELECT age_band FROM customers
     WHERE value_tier = 'Champions'
     GROUP BY age_band ORDER BY COUNT(*) DESC LIMIT 1) AS top_age_band,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(previous_purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(purchase_frequency_per_year), 1)          AS avg_freq_per_year,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(review_rating), 2)                        AS avg_rating,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_rev,
    (SELECT payment_method FROM customers
     WHERE value_tier = 'Champions'
     GROUP BY payment_method ORDER BY COUNT(*) DESC LIMIT 1)
                                                        AS top_payment_method,
    (SELECT shipping_type FROM customers
     WHERE value_tier = 'Champions'
     GROUP BY shipping_type ORDER BY COUNT(*) DESC LIMIT 1)
                                                        AS preferred_shipping,
    (SELECT category FROM customers
     WHERE value_tier = 'Champions'
     GROUP BY category ORDER BY COUNT(*) DESC LIMIT 1) AS top_category,
    (SELECT season FROM customers
     WHERE value_tier = 'Champions'
     GROUP BY season ORDER BY COUNT(*) DESC LIMIT 1)   AS peak_season

FROM customers
WHERE value_tier = 'Champions';


-- Q5B: CATEGORY FUNNEL — Entry-point vs Retention categories
--      "Which categories are associated with low vs high previous_purchases?"
SELECT
    category,
    COUNT(*)                                            AS n,
    ROUND(AVG(previous_purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(review_rating), 2)                        AS avg_rating,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_rev,

    -- Entry-point = low previous purchases (customers start here)
    -- Retention = high previous purchases (loyal customers stay here)
    CASE
        WHEN AVG(previous_purchases) <= (SELECT AVG(previous_purchases)*0.9
                                         FROM customers)
        THEN 'Entry-Point Category'
        WHEN AVG(previous_purchases) >= (SELECT AVG(previous_purchases)*1.1
                                         FROM customers)
        THEN 'Retention Category'
        ELSE 'Neutral'
    END                                                 AS category_role

FROM customers
GROUP BY category
ORDER BY avg_prev_purchases DESC;


-- Q5C: SEASON × CATEGORY — Which combinations drive high value for low-tenure?
SELECT
    season,
    category,
    COUNT(*)                                            AS n,
    ROUND(AVG(previous_purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(purchase_amount_usd), 2)                  AS avg_spend,
    ROUND(AVG(promo_dependency_score), 1)               AS avg_promo_dep,
    ROUND(AVG(estimated_annual_revenue), 0)             AS avg_annual_rev

FROM customers
GROUP BY season, category
ORDER BY avg_prev_purchases ASC, avg_spend DESC
LIMIT 16;


-- ============================================================
-- BONUS: EXECUTIVE OVERVIEW — Single-query business snapshot
-- ============================================================
SELECT
    -- Overall scale
    COUNT(*)                                             AS total_customers,
    ROUND(SUM(estimated_annual_revenue), 0)              AS total_est_annual_revenue,
    ROUND(AVG(purchase_amount_usd), 2)                   AS avg_basket_size,
    ROUND(AVG(previous_purchases), 1)                    AS avg_tenure_purchases,

    -- Loyalty health
    ROUND(SUM(is_loyal_value_sat) * 100.0 / COUNT(*), 1) AS pct_loyal,
    ROUND(SUM(CASE WHEN customer_segment = 'Organic Champions' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                         AS pct_organic_champions,

    -- Promo exposure
    ROUND(AVG(promo_dependency_score), 1)                AS avg_promo_dependency,
    ROUND(SUM(CASE WHEN promo_dependency_score = 100 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                         AS pct_fully_promo_dependent,
    ROUND(SUM(CASE WHEN promo_dependency_score = 0 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                         AS pct_fully_organic,

    -- Satisfaction
    ROUND(AVG(review_rating), 2)                         AS avg_review_rating,
    ROUND(AVG(satisfaction_flag) * 100, 1)               AS pct_satisfied,

    -- Champions revenue concentration
    ROUND(
        (SELECT SUM(estimated_annual_revenue) FROM customers WHERE value_tier='Champions')
        * 100.0 / SUM(estimated_annual_revenue), 1)      AS champions_rev_share_pct

FROM customers;

-- ============================================================
-- GAMING LIVEOPS ANALYSIS
-- Cohort Retention, Monetization, LTV and A/B Testing
-- Database: SQLite
-- ============================================================


-- ============================================================
-- CLEANUP (re-runnable script)
-- ============================================================

DROP VIEW IF EXISTS cohort_size;
DROP VIEW IF EXISTS cohort_activity;
DROP VIEW IF EXISTS retention_active_users;
DROP VIEW IF EXISTS retention_curve;

DROP VIEW IF EXISTS user_revenue;
DROP VIEW IF EXISTS cohort_ltv;
DROP VIEW IF EXISTS monetization_kpis;
DROP VIEW IF EXISTS ab_monetization;

DROP VIEW IF EXISTS ab_monetization_core;
DROP VIEW IF EXISTS ab_uplift;

DROP VIEW IF EXISTS user_lifecycle;
DROP VIEW IF EXISTS ltv_by_day;
DROP VIEW IF EXISTS ltv_curve;


-- ============================================================
-- PHASE 1 — COHORT & RETENTION ANALYSIS
-- ============================================================

-- Cohort size: number of users registered per day
CREATE VIEW cohort_size AS 
SELECT 
    reg_date AS cohort_date,
    COUNT(DISTINCT user_id) AS cohort_users
FROM users
GROUP BY reg_date;


-- User activity mapped to cohort and days since install
CREATE VIEW cohort_activity AS
SELECT 
    u.user_id,
    u.reg_date AS cohort_date,
    e.auth_date,
    CAST(JULIANDAY(e.auth_date) - JULIANDAY(u.reg_date) AS INTEGER) AS days_since_install
FROM users u
JOIN events e 
    ON u.user_id = e.user_id
WHERE CAST(JULIANDAY(e.auth_date) - JULIANDAY(u.reg_date) AS INTEGER) BETWEEN 0 AND 30;


-- Active users per cohort and day since install
CREATE VIEW retention_active_users AS 
SELECT 
    cohort_date,
    days_since_install,
    COUNT(DISTINCT user_id) AS active_users
FROM cohort_activity 
GROUP BY cohort_date, days_since_install;


-- Retention curve (percentage of cohort still active)
CREATE VIEW retention_curve AS
SELECT 
    r.cohort_date,
    r.days_since_install,
    r.active_users,
    c.cohort_users,
    ROUND(100.0 * r.active_users / c.cohort_users, 2) AS retention_rate
FROM retention_active_users r
JOIN cohort_size c 
    ON c.cohort_date = r.cohort_date;


-- ============================================================
-- PHASE 2 — MONETIZATION & LTV
-- ============================================================

-- Revenue mapped to users and cohorts
CREATE VIEW user_revenue AS
SELECT 
    u.user_id,
    u.reg_date AS cohort_date,
    IFNULL(r.revenue, 0) AS revenue,
    r.testgroup
FROM users u
LEFT JOIN revenue r
    ON u.user_id = r.user_id;


-- Cohort-level lifetime value (total and per user)
CREATE VIEW cohort_ltv AS
SELECT 
    cohort_date,
    COUNT(DISTINCT user_id) AS users,
    SUM(revenue) AS total_revenue,
    ROUND(1.0 * SUM(revenue) / COUNT(DISTINCT user_id), 2) AS ltv
FROM user_revenue
GROUP BY cohort_date;


-- Monetization KPIs by cohort
CREATE VIEW monetization_kpis AS
SELECT
    cohort_date,
    COUNT(DISTINCT user_id) AS users,
    COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END) AS payers,
    ROUND(
        1.0 * COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END)
        / COUNT(DISTINCT user_id), 
        3
    ) AS payer_rate,
    ROUND(
        1.0 * SUM(revenue)
        / COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END), 
        2
    ) AS arppu,
    ROUND(
        1.0 * SUM(revenue)
        / COUNT(DISTINCT user_id), 
        2
    ) AS arpu
FROM user_revenue
GROUP BY cohort_date;


-- Monetization by A/B test group
CREATE VIEW ab_monetization AS 
SELECT 
    COALESCE(testgroup, 'no_test') AS testgroup,
    COUNT(DISTINCT user_id) AS users,
    SUM(revenue) AS total_revenue,
    ROUND(1.0 * SUM(revenue) / COUNT(DISTINCT user_id), 2) AS arpu,
    ROUND(
        1.0 * COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END)
        / COUNT(DISTINCT user_id), 
        3
    ) AS payer_rate
FROM user_revenue
GROUP BY COALESCE(testgroup, 'no_test');


-- ============================================================
-- PHASE 3 — A/B TEST ANALYSIS
-- ============================================================

-- Core monetization metrics by test group
CREATE VIEW ab_monetization_core AS
SELECT
    testgroup,
    COUNT(DISTINCT user_id) AS users,
    COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END) AS payers,
    SUM(revenue) AS total_revenue,
    ROUND(1.0 * SUM(revenue) / COUNT(DISTINCT user_id), 2) AS arpu,
    ROUND(
        1.0 * COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END)
        / COUNT(DISTINCT user_id), 
        4
    ) AS payer_rate,
    ROUND(
        1.0 * SUM(revenue)
        / NULLIF(COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END), 0),
        2
    ) AS arppu
FROM user_revenue
WHERE testgroup IN ('a', 'b')
GROUP BY testgroup;


-- Uplift calculation: Variant B vs Variant A
CREATE VIEW ab_uplift AS
SELECT
    'B vs A' AS comparison,
    ROUND(100.0 * (b.arpu - a.arpu) / a.arpu, 2) AS arpu_uplift_pct,
    ROUND(100.0 * (b.payer_rate - a.payer_rate) / a.payer_rate, 2) AS payer_rate_uplift_pct,
    ROUND(100.0 * (b.arppu - a.arppu) / a.arppu, 2) AS arppu_uplift_pct
FROM ab_monetization_core a
JOIN ab_monetization_core b
    ON a.testgroup = 'a' AND b.testgroup = 'b';


-- ============================================================
-- PHASE 4 — RETENTION vs MONETIZATION
-- ============================================================

-- Combine lifecycle activity with revenue
CREATE VIEW user_lifecycle AS
SELECT
    ca.user_id,
    ca.cohort_date,
    ca.days_since_install,
    ur.revenue,
    ur.testgroup
FROM cohort_activity ca
JOIN user_revenue ur
    ON ca.user_id = ur.user_id;


-- Revenue accumulated by cohort and day
CREATE VIEW ltv_by_day AS
SELECT
    cohort_date,
    days_since_install,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT user_id) AS active_users
FROM user_lifecycle
GROUP BY cohort_date, days_since_install;


-- Normalized cumulative LTV curve
CREATE VIEW ltv_curve AS
SELECT
    l.cohort_date,
    l.days_since_install,
    ROUND(
        1.0 * l.total_revenue / c.cohort_users,
        2
    ) AS ltv
FROM ltv_by_day l
JOIN cohort_size c
    ON l.cohort_date = c.cohort_date;

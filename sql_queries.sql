-- =====================================================
-- Miron Korsun — SQL Portfolio for Product Analyst Intern
-- Skills demonstrated: JOINs, Window Functions, Aggregations, Subqueries
-- =====================================================

-- =====================================================
-- 1. Basic aggregation with JOIN
-- Task: Total sales amount per customer (only customers with >1000 total)
-- Tables: customers, orders, order_items
-- =====================================================

SELECT 
    c.customer_id,
    c.name,
    SUM(oi.price * oi.quantity) AS total_spent,
    COUNT(DISTINCT o.order_id) AS number_of_orders
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name
HAVING SUM(oi.price * oi.quantity) > 1000
ORDER BY total_spent DESC;


-- =====================================================
-- 2. Window function — Rolling 7-day average
-- Task: Show daily sales + moving average of last 7 days
-- Table: sales (sale_date, amount)
-- =====================================================

SELECT 
    sale_date,
    SUM(amount) AS daily_sales,
    AVG(SUM(amount)) OVER (
        ORDER BY sale_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7_day_avg
FROM sales
GROUP BY sale_date
ORDER BY sale_date;


-- =====================================================
-- 3. Window function — Rank users by activity
-- Task: Top 3 most active users (by login count) per region
-- Tables: users (user_id, region), user_logins (user_id, login_date)
-- =====================================================

WITH user_activity AS (
    SELECT 
        u.user_id,
        u.region,
        COUNT(l.login_date) AS login_count
    FROM users u
    LEFT JOIN user_logins l ON u.user_id = l.user_id
    GROUP BY u.user_id, u.region
)
SELECT 
    user_id,
    region,
    login_count,
    RANK() OVER (PARTITION BY region ORDER BY login_count DESC) AS rank_in_region
FROM user_activity
WHERE login_count > 0
ORDER BY region, rank_in_region;


-- =====================================================
-- 4. Compare current month vs previous month (LAG)
-- Task: Month-over-month growth in new users
-- Table: users (user_id, created_at)
-- =====================================================

WITH monthly_signups AS (
    SELECT 
        DATE_FORMAT(created_at, '%Y-%m-01') AS month,
        COUNT(user_id) AS new_users
    FROM users
    GROUP BY DATE_FORMAT(created_at, '%Y-%m-01')
)
SELECT 
    month,
    new_users,
    LAG(new_users, 1) OVER (ORDER BY month) AS previous_month_users,
    ROUND(
        (new_users - LAG(new_users, 1) OVER (ORDER BY month)) * 100.0 / 
        LAG(new_users, 1) OVER (ORDER BY month), 
        2
    ) AS growth_percent
FROM monthly_signups
ORDER BY month;


-- =====================================================
-- 5. Subquery — Find inactive users
-- Task: Users who haven't logged in for 30+ days
-- Tables: users (user_id, name, last_login_date)
-- =====================================================

SELECT 
    user_id,
    name,
    last_login_date,
    DATEDIFF(CURDATE(), last_login_date) AS days_inactive
FROM users
WHERE last_login_date < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY days_inactive DESC;


-- =====================================================
-- 6. Complex filtering — 80/20 analysis (Pareto)
-- Task: Find top 20% of products by revenue
-- Table: products (product_id, name), order_items (product_id, price, quantity)
-- =====================================================

WITH product_revenue AS (
    SELECT 
        p.product_id,
        p.name,
        SUM(oi.price * oi.quantity) AS total_revenue
    FROM products p
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.name
),
revenue_total AS (
    SELECT SUM(total_revenue) AS grand_total FROM product_revenue
)
SELECT 
    pr.product_id,
    pr.name,
    pr.total_revenue,
    ROUND(pr.total_revenue / rt.grand_total * 100, 2) AS revenue_percent,
    ROUND(
        SUM(pr.total_revenue) OVER (ORDER BY pr.total_revenue DESC) / rt.grand_total * 100, 
        2
    ) AS cumulative_percent
FROM product_revenue pr
CROSS JOIN revenue_total rt
ORDER BY pr.total_revenue DESC;


-- =====================================================
-- 7. Cohort retention — Monthly retention (simplified)
-- Task: First month of user activity + retention in month 1,2,3
-- Tables: user_activity (user_id, activity_date)
-- Note: This works for PostgreSQL / MySQL 8.0+
-- =====================================================

WITH first_activity AS (
    SELECT 
        user_id,
        DATE_FORMAT(MIN(activity_date), '%Y-%m-01') AS cohort_month
    FROM user_activity
    GROUP BY user_id
),
user_activity_with_cohort AS (
    SELECT 
        ua.user_id,
        fa.cohort_month,
        DATE_FORMAT(ua.activity_date, '%Y-%m-01') AS activity_month,
        TIMESTAMPDIFF(MONTH, fa.cohort_month, DATE_FORMAT(ua.activity_date, '%Y-%m-01')) AS month_number
    FROM user_activity ua
    INNER JOIN first_activity fa ON ua.user_id = fa.user_id
    GROUP BY ua.user_id, fa.cohort_month, activity_month
)
SELECT 
    cohort_month,
    COUNT(DISTINCT CASE WHEN month_number = 0 THEN user_id END) AS month0_users,
    COUNT(DISTINCT CASE WHEN month_number = 1 THEN user_id END) AS month1_users,
    COUNT(DISTINCT CASE WHEN month_number = 2 THEN user_id END) AS month2_users,
    ROUND(
        COUNT(DISTINCT CASE WHEN month_number = 1 THEN user_id END) * 100.0 / 
        COUNT(DISTINCT CASE WHEN month_number = 0 THEN user_id END), 
        1
    ) AS retention_percent_month1
FROM user_activity_with_cohort
GROUP BY cohort_month
ORDER BY cohort_month;

-- ============================================================
-- 04_business_reports.sql
-- Sample Analytical Queries / Reports
-- ============================================================

USE movie_rental_dw;

-- 1. Top 10 most rented films
SELECT
    f.title,
    f.category_name,
    SUM(r.rental_count) AS total_rentals
FROM fact_rental r
JOIN dim_film f ON r.film_key = f.film_key
GROUP BY f.title, f.category_name
ORDER BY total_rentals DESC
LIMIT 10;

-- 2. Top 10 films by revenue
SELECT
    f.title,
    f.category_name,
    SUM(p.payment_amount) AS total_revenue
FROM fact_payment p
JOIN dim_film f ON p.film_key = f.film_key
GROUP BY f.title, f.category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 3. Revenue by store
SELECT
    s.store_id,
    s.city,
    s.country,
    SUM(p.payment_amount) AS total_revenue,
    SUM(p.payment_count) AS total_payments
FROM fact_payment p
JOIN dim_store s ON p.store_key = s.store_key
GROUP BY s.store_id, s.city, s.country
ORDER BY total_revenue DESC;

-- 4. Monthly revenue trend
SELECT
    d.year_number,
    d.month_number,
    d.month_name,
    SUM(p.payment_amount) AS total_revenue
FROM fact_payment p
JOIN dim_date d ON p.payment_date_key = d.date_key
GROUP BY d.year_number, d.month_number, d.month_name
ORDER BY d.year_number, d.month_number;

-- 5. Monthly rental trend
SELECT
    d.year_number,
    d.month_number,
    d.month_name,
    SUM(r.rental_count) AS total_rentals
FROM fact_rental r
JOIN dim_date d ON r.rental_date_key = d.date_key
GROUP BY d.year_number, d.month_number, d.month_name
ORDER BY d.year_number, d.month_number;

-- 6. Most active customers by rentals and revenue
SELECT
    c.full_name,
    c.city,
    c.country,
    SUM(r.rental_count) AS total_rentals,
    COALESCE(SUM(p.payment_amount), 0) AS total_revenue
FROM dim_customer c
LEFT JOIN fact_rental r ON c.customer_key = r.customer_key
LEFT JOIN fact_payment p ON c.customer_key = p.customer_key
GROUP BY c.customer_key, c.full_name, c.city, c.country
ORDER BY total_rentals DESC, total_revenue DESC
LIMIT 10;

-- 7. Staff performance 
SELECT
    st.full_name AS staff_name,
    st.store_id,
    COALESCE(r.processed_rentals, 0) AS processed_rentals,
    COALESCE(p.processed_payments, 0) AS processed_payments,
    COALESCE(p.total_revenue, 0) AS total_revenue
FROM dim_staff st
LEFT JOIN (
    SELECT
        staff_key,
        COUNT(*) AS processed_rentals
    FROM fact_rental
    GROUP BY staff_key
) r ON st.staff_key = r.staff_key
LEFT JOIN (
    SELECT
        staff_key,
        COUNT(*) AS processed_payments,
        SUM(payment_amount) AS total_revenue
    FROM fact_payment
    GROUP BY staff_key
) p ON st.staff_key = p.staff_key
ORDER BY total_revenue DESC;

-- 8. Late returned films
SELECT
    f.title,
    f.category_name,
    SUM(CASE WHEN r.late_return_flag = 1 THEN 1 ELSE 0 END) AS late_returns,
    SUM(r.late_days) AS total_late_days,
    AVG(r.rental_duration_days) AS avg_rental_duration
FROM fact_rental r
JOIN dim_film f ON r.film_key = f.film_key
GROUP BY f.title, f.category_name
HAVING late_returns > 0
ORDER BY late_returns DESC, total_late_days DESC
LIMIT 10;





-- ============================================================
-- 02_load_dimensions.sql
-- ETL Step 1: Load Dimension Tables
-- Run this after importing the original Sakila OLTP database
-- and after running 01_create_dw_schema.sql
-- ============================================================

USE movie_rental_dw;

-- Unknown date row used for open rentals where return_date is NULL
INSERT INTO dim_date (
    date_key, full_date, day_number, month_number, month_name,
    quarter_number, year_number, day_of_week, is_unknown
)
VALUES (0, NULL, NULL, NULL, 'Unknown', NULL, NULL, 'Unknown', 1);

-- Load all dates from rental_date, return_date, payment_date, and current date for inventory snapshot
INSERT IGNORE INTO dim_date (
    date_key,
    full_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number,
    day_of_week,
    is_unknown
)
SELECT DISTINCT
    DATE_FORMAT(date_value, '%Y%m%d') AS date_key,
    DATE(date_value) AS full_date,
    DAY(date_value) AS day_number,
    MONTH(date_value) AS month_number,
    MONTHNAME(date_value) AS month_name,
    QUARTER(date_value) AS quarter_number,
    YEAR(date_value) AS year_number,
    DAYNAME(date_value) AS day_of_week,
    0 AS is_unknown
FROM (
    SELECT rental_date AS date_value FROM sakila.rental
    UNION
    SELECT return_date FROM sakila.rental WHERE return_date IS NOT NULL
    UNION
    SELECT payment_date FROM sakila.payment
    UNION
    SELECT CURDATE()
) d
WHERE date_value IS NOT NULL;

-- Load Customer Dimension
INSERT INTO dim_customer (
    customer_id,
    full_name,
    email,
    active,
    address,
    district,
    city,
    country,
    postal_code,
    phone,
    store_id,
    create_date
)
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.email,
    c.active,
    a.address,
    a.district,
    ci.city,
    co.country,
    a.postal_code,
    a.phone,
    c.store_id,
    c.create_date
FROM sakila.customer c
JOIN sakila.address a ON c.address_id = a.address_id
JOIN sakila.city ci ON a.city_id = ci.city_id
JOIN sakila.country co ON ci.country_id = co.country_id;

-- Load Film Dimension
-- Sakila usually has one category per film, but GROUP_CONCAT is used to stay safe.
INSERT INTO dim_film (
    film_id,
    title,
    description,
    release_year,
    rating,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    language_name,
    category_name
)
SELECT
    f.film_id,
    f.title,
    f.description,
    f.release_year,
    f.rating,
    f.rental_duration,
    f.rental_rate,
    f.length,
    f.replacement_cost,
    TRIM(l.name) AS language_name,
    GROUP_CONCAT(DISTINCT cat.name ORDER BY cat.name SEPARATOR ', ') AS category_name
FROM sakila.film f
JOIN sakila.language l ON f.language_id = l.language_id
LEFT JOIN sakila.film_category fc ON f.film_id = fc.film_id
LEFT JOIN sakila.category cat ON fc.category_id = cat.category_id
GROUP BY
    f.film_id, f.title, f.description, f.release_year, f.rating,
    f.rental_duration, f.rental_rate, f.length, f.replacement_cost, l.name;

-- Load Store Dimension
INSERT INTO dim_store (
    store_id,
    manager_staff_id,
    address,
    district,
    city,
    country,
    postal_code,
    phone
)
SELECT
    s.store_id,
    s.manager_staff_id,
    a.address,
    a.district,
    ci.city,
    co.country,
    a.postal_code,
    a.phone
FROM sakila.store s
JOIN sakila.address a ON s.address_id = a.address_id
JOIN sakila.city ci ON a.city_id = ci.city_id
JOIN sakila.country co ON ci.country_id = co.country_id;

-- Load Staff Dimension
INSERT INTO dim_staff (
    staff_id,
    full_name,
    email,
    username,
    active,
    store_id,
    address,
    city,
    country
)
SELECT
    st.staff_id,
    CONCAT(st.first_name, ' ', st.last_name) AS full_name,
    st.email,
    st.username,
    st.active,
    st.store_id,
    a.address,
    ci.city,
    co.country
FROM sakila.staff st
JOIN sakila.address a ON st.address_id = a.address_id
JOIN sakila.city ci ON a.city_id = ci.city_id
JOIN sakila.country co ON ci.country_id = co.country_id;

-- Load Actor Dimension
INSERT INTO dim_actor (
    actor_id,
    full_name
)
SELECT
    actor_id,
    CONCAT(first_name, ' ', last_name) AS full_name
FROM sakila.actor;

-- Load Film-Actor Bridge
INSERT INTO bridge_film_actor (
    film_key,
    actor_key
)
SELECT
    df.film_key,
    da.actor_key
FROM sakila.film_actor fa
JOIN dim_film df ON fa.film_id = df.film_id
JOIN dim_actor da ON fa.actor_id = da.actor_id;

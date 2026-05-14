-- ============================================================
-- 03_load_facts.sql
-- ETL Step 2: Load Fact Tables
-- Run this after 02_load_dimensions.sql
-- ============================================================

USE movie_rental_dw;

-- ============================================================
-- Load Rental Fact
-- Business process: Film rental transactions
-- Grain: One row per rental transaction
-- ============================================================

INSERT INTO fact_rental (
    rental_id,
    inventory_id,
    rental_date_key,
    return_date_key,
    customer_key,
    film_key,
    store_key,
    staff_key,
    rental_count,
    rental_duration_days,
    expected_rental_duration_days,
    late_return_flag,
    late_days
)
SELECT
    r.rental_id,
    r.inventory_id,

    CAST(DATE_FORMAT(r.rental_date, '%Y%m%d') AS UNSIGNED) AS rental_date_key,

    COALESCE(
        CAST(DATE_FORMAT(r.return_date, '%Y%m%d') AS UNSIGNED),
        0
    ) AS return_date_key,

    dc.customer_key,
    df.film_key,
    ds.store_key,
    dst.staff_key,

    1 AS rental_count,

    CASE
        WHEN r.return_date IS NULL THEN NULL
        ELSE DATEDIFF(r.return_date, r.rental_date)
    END AS rental_duration_days,

    df.rental_duration AS expected_rental_duration_days,

    CASE
        WHEN r.return_date IS NULL THEN NULL
        WHEN DATEDIFF(r.return_date, r.rental_date) > df.rental_duration THEN 1
        ELSE 0
    END AS late_return_flag,

    CASE
        WHEN r.return_date IS NULL THEN NULL
        WHEN DATEDIFF(r.return_date, r.rental_date) > df.rental_duration
            THEN DATEDIFF(r.return_date, r.rental_date) - CAST(df.rental_duration AS SIGNED)
        ELSE 0
    END AS late_days

FROM sakila.rental r
JOIN sakila.inventory i 
    ON r.inventory_id = i.inventory_id
JOIN dim_customer dc 
    ON r.customer_id = dc.customer_id
JOIN dim_film df 
    ON i.film_id = df.film_id
JOIN dim_store ds 
    ON i.store_id = ds.store_id
JOIN dim_staff dst 
    ON r.staff_id = dst.staff_id;


-- ============================================================
-- Load Payment Fact
-- Business process: Customer payment transactions
-- Grain: One row per payment transaction
-- ============================================================

INSERT INTO fact_payment (
    payment_id,
    rental_id,
    payment_date_key,
    customer_key,
    film_key,
    store_key,
    staff_key,
    payment_amount,
    payment_count
)
SELECT
    p.payment_id,
    p.rental_id,

    CAST(DATE_FORMAT(p.payment_date, '%Y%m%d') AS UNSIGNED) AS payment_date_key,

    dc.customer_key,
    df.film_key,
    ds.store_key,
    dst.staff_key,

    p.amount AS payment_amount,
    1 AS payment_count

FROM sakila.payment p
JOIN dim_customer dc 
    ON p.customer_id = dc.customer_id
JOIN dim_staff dst 
    ON p.staff_id = dst.staff_id
LEFT JOIN sakila.rental r 
    ON p.rental_id = r.rental_id
LEFT JOIN sakila.inventory i 
    ON r.inventory_id = i.inventory_id
LEFT JOIN dim_film df 
    ON i.film_id = df.film_id
LEFT JOIN dim_store ds 
    ON i.store_id = ds.store_id;


-- ============================================================
-- Load Inventory Snapshot Fact
-- Business process: Film inventory availability
-- Grain: One row per film per store per snapshot date
-- ============================================================

INSERT INTO fact_inventory_snapshot (
    snapshot_date_key,
    film_key,
    store_key,
    inventory_count,
    rented_count,
    available_count
)
SELECT
    CAST(DATE_FORMAT(CURDATE(), '%Y%m%d') AS UNSIGNED) AS snapshot_date_key,

    df.film_key,
    ds.store_key,

    COUNT(i.inventory_id) AS inventory_count,

    SUM(
        CASE 
            WHEN open_rentals.inventory_id IS NOT NULL THEN 1 
            ELSE 0 
        END
    ) AS rented_count,

    COUNT(i.inventory_id) -
    SUM(
        CASE 
            WHEN open_rentals.inventory_id IS NOT NULL THEN 1 
            ELSE 0 
        END
    ) AS available_count

FROM sakila.inventory i
JOIN dim_film df 
    ON i.film_id = df.film_id
JOIN dim_store ds 
    ON i.store_id = ds.store_id
LEFT JOIN (
    SELECT DISTINCT inventory_id
    FROM sakila.rental
    WHERE return_date IS NULL
) open_rentals 
    ON i.inventory_id = open_rentals.inventory_id

GROUP BY
    df.film_key,
    ds.store_key;
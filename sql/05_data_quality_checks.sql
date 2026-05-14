-- ============================================================
-- 05_data_quality_checks.sql
-- Data Quality Checks for the Warehouse
-- ============================================================

USE movie_rental_dw;

-- 1. Check duplicated rentals in FactRental
SELECT
    rental_id,
    COUNT(*) AS duplicate_count
FROM fact_rental
GROUP BY rental_id
HAVING COUNT(*) > 1;

-- 2. Check duplicated payments in FactPayment
SELECT
    payment_id,
    COUNT(*) AS duplicate_count
FROM fact_payment
GROUP BY payment_id
HAVING COUNT(*) > 1;

-- 3. Check invalid payment amounts
SELECT *
FROM fact_payment
WHERE payment_amount <= 0;

-- 4. Check return date before rental date using dates
SELECT
    fr.rental_id,
    rd.full_date AS rental_date,
    ret.full_date AS return_date
FROM fact_rental fr
JOIN dim_date rd ON fr.rental_date_key = rd.date_key
JOIN dim_date ret ON fr.return_date_key = ret.date_key
WHERE fr.return_date_key <> 0
  AND ret.full_date < rd.full_date;

-- 5. Check negative late days
SELECT *
FROM fact_rental
WHERE late_days < 0;

-- 6. Check fact rentals with missing dimension references
SELECT *
FROM fact_rental fr
LEFT JOIN dim_customer c ON fr.customer_key = c.customer_key
LEFT JOIN dim_film f ON fr.film_key = f.film_key
LEFT JOIN dim_store s ON fr.store_key = s.store_key
LEFT JOIN dim_staff st ON fr.staff_key = st.staff_key
WHERE c.customer_key IS NULL
   OR f.film_key IS NULL
   OR s.store_key IS NULL
   OR st.staff_key IS NULL;

-- 7. Count rows loaded into each warehouse table
SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM dim_date
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_film', COUNT(*) FROM dim_film
UNION ALL SELECT 'dim_store', COUNT(*) FROM dim_store
UNION ALL SELECT 'dim_staff', COUNT(*) FROM dim_staff
UNION ALL SELECT 'dim_actor', COUNT(*) FROM dim_actor
UNION ALL SELECT 'bridge_film_actor', COUNT(*) FROM bridge_film_actor
UNION ALL SELECT 'fact_rental', COUNT(*) FROM fact_rental
UNION ALL SELECT 'fact_payment', COUNT(*) FROM fact_payment
UNION ALL SELECT 'fact_inventory_snapshot', COUNT(*) FROM fact_inventory_snapshot;

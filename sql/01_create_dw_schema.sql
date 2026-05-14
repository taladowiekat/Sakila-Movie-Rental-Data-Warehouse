-- ============================================================
-- 01_create_dw_schema.sql
-- Movie Rental Data Warehouse Schema
-- Source OLTP database: sakila
-- Target DW database: movie_rental_dw
-- ============================================================

DROP DATABASE IF EXISTS movie_rental_dw;
CREATE DATABASE movie_rental_dw;
USE movie_rental_dw;

-- ============================================================
-- Dimension Tables
-- ============================================================

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE,
    day_number TINYINT,
    month_number TINYINT,
    month_name VARCHAR(20),
    quarter_number TINYINT,
    year_number SMALLINT,
    day_of_week VARCHAR(20),
    is_unknown TINYINT DEFAULT 0
);

CREATE TABLE dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id SMALLINT UNSIGNED NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    active TINYINT,
    address VARCHAR(100),
    district VARCHAR(50),
    city VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    phone VARCHAR(30),
    store_id TINYINT UNSIGNED,
    create_date DATETIME,
    UNIQUE KEY uq_dim_customer_customer_id (customer_id)
);

CREATE TABLE dim_film (
    film_key INT AUTO_INCREMENT PRIMARY KEY,
    film_id SMALLINT UNSIGNED NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    release_year YEAR,
    rating VARCHAR(10),
    rental_duration TINYINT UNSIGNED,
    rental_rate DECIMAL(6,2),
    length SMALLINT UNSIGNED,
    replacement_cost DECIMAL(8,2),
    language_name VARCHAR(50),
    category_name VARCHAR(50),
    UNIQUE KEY uq_dim_film_film_id (film_id)
);

CREATE TABLE dim_store (
    store_key INT AUTO_INCREMENT PRIMARY KEY,
    store_id TINYINT UNSIGNED NOT NULL,
    manager_staff_id TINYINT UNSIGNED,
    address VARCHAR(100),
    district VARCHAR(50),
    city VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    phone VARCHAR(30),
    UNIQUE KEY uq_dim_store_store_id (store_id)
);

CREATE TABLE dim_staff (
    staff_key INT AUTO_INCREMENT PRIMARY KEY,
    staff_id TINYINT UNSIGNED NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    username VARCHAR(50),
    active TINYINT,
    store_id TINYINT UNSIGNED,
    address VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    UNIQUE KEY uq_dim_staff_staff_id (staff_id)
);

CREATE TABLE dim_actor (
    actor_key INT AUTO_INCREMENT PRIMARY KEY,
    actor_id SMALLINT UNSIGNED NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    UNIQUE KEY uq_dim_actor_actor_id (actor_id)
);

-- Bridge table for many-to-many relationship between films and actors
CREATE TABLE bridge_film_actor (
    film_key INT NOT NULL,
    actor_key INT NOT NULL,
    PRIMARY KEY (film_key, actor_key),
    FOREIGN KEY (film_key) REFERENCES dim_film(film_key),
    FOREIGN KEY (actor_key) REFERENCES dim_actor(actor_key)
);

-- ============================================================
-- Fact Tables
-- ============================================================

CREATE TABLE fact_rental (
    rental_fact_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    rental_id INT NOT NULL,
    inventory_id MEDIUMINT UNSIGNED,
    rental_date_key INT NOT NULL,
    return_date_key INT NOT NULL,
    customer_key INT NOT NULL,
    film_key INT NOT NULL,
    store_key INT NOT NULL,
    staff_key INT NOT NULL,
    rental_count INT DEFAULT 1,
    rental_duration_days INT,
    expected_rental_duration_days INT,
    late_return_flag TINYINT,
    late_days INT,
    FOREIGN KEY (rental_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (return_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (film_key) REFERENCES dim_film(film_key),
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
    FOREIGN KEY (staff_key) REFERENCES dim_staff(staff_key),
    UNIQUE KEY uq_fact_rental_rental_id (rental_id)
);

CREATE TABLE fact_payment (
    payment_fact_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_id SMALLINT UNSIGNED NOT NULL,
    rental_id INT,
    payment_date_key INT NOT NULL,
    customer_key INT NOT NULL,
    film_key INT,
    store_key INT,
    staff_key INT NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    payment_count INT DEFAULT 1,
    FOREIGN KEY (payment_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (film_key) REFERENCES dim_film(film_key),
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
    FOREIGN KEY (staff_key) REFERENCES dim_staff(staff_key),
    UNIQUE KEY uq_fact_payment_payment_id (payment_id)
);

CREATE TABLE fact_inventory_snapshot (
    inventory_snapshot_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    snapshot_date_key INT NOT NULL,
    film_key INT NOT NULL,
    store_key INT NOT NULL,
    inventory_count INT NOT NULL,
    rented_count INT NOT NULL,
    available_count INT NOT NULL,
    FOREIGN KEY (snapshot_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (film_key) REFERENCES dim_film(film_key),
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
    UNIQUE KEY uq_inventory_snapshot (snapshot_date_key, film_key, store_key)
);

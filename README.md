# Movie Rental Data Warehouse

This project builds a data warehouse for the Sakila movie rental OLTP database.

## Tools
- MySQL Workbench
- MySQL
- GitHub

## Source Database
sakila

## Target Data Warehouse
movie_rental_dw
link : https://drive.google.com/file/d/1UxR65upm350BBJkEODJQ3h2LQKGrw5-L/view

## Run Order
1. Import the original Sakila SQL file.
2. Run sql/01_create_dw_schema.sql
3. Run sql/02_load_dimensions.sql
4. Run sql/03_load_facts.sql
5. Run sql/04_business_reports.sql
6. Run sql/05_data_quality_checks.sql

## Main Components
- Fact tables: fact_rental, fact_payment, fact_inventory_snapshot
- Dimension tables: dim_date, dim_customer, dim_film, dim_store, dim_staff, dim_actor
- Bridge table: bridge_film_actor
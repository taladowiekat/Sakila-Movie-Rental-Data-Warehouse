import os
import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine

DB_USER = "root"
DB_PASSWORD = "NewPassword123!"
DB_HOST = "localhost"
DB_PORT = "3306"
DB_NAME = "movie_rental_dw"

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

OUTPUT_DIR = "charts"
os.makedirs(OUTPUT_DIR, exist_ok=True)


def save_bar_chart(df, x_col, y_col, title, xlabel, ylabel, filename, rotation=45):
    plt.figure(figsize=(12, 6))
    plt.bar(df[x_col], df[y_col])
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.xticks(rotation=rotation, ha="right")
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, filename), dpi=300)
    plt.close()


def save_line_chart(df, x_col, y_col, title, xlabel, ylabel, filename):
    plt.figure(figsize=(10, 5))
    plt.plot(df[x_col], df[y_col], marker="o")
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.xticks(rotation=45, ha="right")
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, filename), dpi=300)
    plt.close()


# 1. Top 10 Most Rented Films
query = """
SELECT
    f.title,
    f.category_name,
    SUM(r.rental_count) AS total_rentals
FROM fact_rental r
JOIN dim_film f ON r.film_key = f.film_key
GROUP BY f.title, f.category_name
ORDER BY total_rentals DESC
LIMIT 10;
"""
df = pd.read_sql(query, engine)
save_bar_chart(df, "title", "total_rentals", "Top 10 Most Rented Films",
               "Film Title", "Total Rentals", "top_10_most_rented_films.png")


# 2. Top 10 Films by Revenue
query = """
SELECT
    f.title,
    f.category_name,
    SUM(p.payment_amount) AS total_revenue
FROM fact_payment p
JOIN dim_film f ON p.film_key = f.film_key
GROUP BY f.title, f.category_name
ORDER BY total_revenue DESC
LIMIT 10;
"""
df = pd.read_sql(query, engine)
save_bar_chart(df, "title", "total_revenue", "Top 10 Films by Revenue",
               "Film Title", "Total Revenue", "top_10_films_by_revenue.png")


# 3. Revenue by Store
query = """
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
"""
df = pd.read_sql(query, engine)
df["store_label"] = "Store " + df["store_id"].astype(str) + " - " + df["city"]
save_bar_chart(df, "store_label", "total_revenue", "Revenue by Store",
               "Store", "Total Revenue", "revenue_by_store.png", rotation=0)


# 4. Monthly Revenue Trend
query = """
SELECT
    d.year_number,
    d.month_number,
    d.month_name,
    SUM(p.payment_amount) AS total_revenue
FROM fact_payment p
JOIN dim_date d ON p.payment_date_key = d.date_key
GROUP BY d.year_number, d.month_number, d.month_name
ORDER BY d.year_number, d.month_number;
"""
df = pd.read_sql(query, engine)
df["month_label"] = df["month_name"] + " " + df["year_number"].astype(str)
save_line_chart(df, "month_label", "total_revenue", "Monthly Revenue Trend",
                "Month", "Total Revenue", "monthly_revenue_trend.png")


# 5. Monthly Rental Trend
query = """
SELECT
    d.year_number,
    d.month_number,
    d.month_name,
    SUM(r.rental_count) AS total_rentals
FROM fact_rental r
JOIN dim_date d ON r.rental_date_key = d.date_key
GROUP BY d.year_number, d.month_number, d.month_name
ORDER BY d.year_number, d.month_number;
"""
df = pd.read_sql(query, engine)
df["month_label"] = df["month_name"] + " " + df["year_number"].astype(str)
save_line_chart(df, "month_label", "total_rentals", "Monthly Rental Trend",
                "Month", "Total Rentals", "monthly_rental_trend.png")


# 6. Most Active Customers
query = """
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
"""
df = pd.read_sql(query, engine)
save_bar_chart(df, "full_name", "total_rentals", "Most Active Customers by Rentals",
               "Customer", "Total Rentals", "most_active_customers.png")


# 7. Staff Performance
query = """
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
"""
df = pd.read_sql(query, engine)
save_bar_chart(df, "staff_name", "total_revenue", "Staff Performance by Revenue",
               "Staff", "Total Revenue", "staff_performance.png", rotation=0)


# 8. Late Returned Films
query = """
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
"""
df = pd.read_sql(query, engine)
save_bar_chart(df, "title", "late_returns", "Late Returned Films",
               "Film Title", "Late Returns", "late_returned_films.png")


print("Done. Charts saved in the charts folder.")
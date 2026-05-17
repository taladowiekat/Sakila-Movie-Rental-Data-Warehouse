import os
import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine

# =========================
# Database Connection
# =========================

DB_USER = "root"
DB_PASSWORD = "root"
DB_HOST = "localhost"
DB_PORT = "3306"
DB_NAME = "movie_rental_dw"

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

OUTPUT_DIR = "charts"
os.makedirs(OUTPUT_DIR, exist_ok=True)


# =========================
# Helper Function
# =========================

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


# =========================
# 1. Top 10 Most Rented Films
# =========================

query_top_rented = """
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

df_top_rented = pd.read_sql(query_top_rented, engine)

save_bar_chart(
    df_top_rented,
    x_col="title",
    y_col="total_rentals",
    title="Top 10 Most Rented Films",
    xlabel="Film Title",
    ylabel="Total Rentals",
    filename="top_10_most_rented_films.png"
)


# =========================
# 2. Top 10 Films by Revenue
# =========================

query_top_revenue = """
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

df_top_revenue = pd.read_sql(query_top_revenue, engine)

save_bar_chart(
    df_top_revenue,
    x_col="title",
    y_col="total_revenue",
    title="Top 10 Films by Revenue",
    xlabel="Film Title",
    ylabel="Total Revenue",
    filename="top_10_films_by_revenue.png"
)


# =========================
# 3. Revenue by Store
# =========================

query_revenue_store = """
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

df_revenue_store = pd.read_sql(query_revenue_store, engine)
df_revenue_store["store_label"] = (
    "Store " + df_revenue_store["store_id"].astype(str) + " - " + df_revenue_store["city"]
)

save_bar_chart(
    df_revenue_store,
    x_col="store_label",
    y_col="total_revenue",
    title="Revenue by Store",
    xlabel="Store",
    ylabel="Total Revenue",
    filename="revenue_by_store.png",
    rotation=0
)


# =========================
# 4. Monthly Revenue Trend
# =========================

query_monthly_revenue = """
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

df_monthly_revenue = pd.read_sql(query_monthly_revenue, engine)
df_monthly_revenue["month_label"] = (
    df_monthly_revenue["month_name"] + " " + df_monthly_revenue["year_number"].astype(str)
)

save_line_chart(
    df_monthly_revenue,
    x_col="month_label",
    y_col="total_revenue",
    title="Monthly Revenue Trend",
    xlabel="Month",
    ylabel="Total Revenue",
    filename="monthly_revenue_trend.png"
)


# =========================
# 5. Monthly Rental Trend
# =========================

query_monthly_rentals = """
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

df_monthly_rentals = pd.read_sql(query_monthly_rentals, engine)
df_monthly_rentals["month_label"] = (
    df_monthly_rentals["month_name"] + " " + df_monthly_rentals["year_number"].astype(str)
)

save_line_chart(
    df_monthly_rentals,
    x_col="month_label",
    y_col="total_rentals",
    title="Monthly Rental Trend",
    xlabel="Month",
    ylabel="Total Rentals",
    filename="monthly_rental_trend.png"
)


# =========================
# 6. Most Active Customers
# =========================

query_customers = """
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

df_customers = pd.read_sql(query_customers, engine)

save_bar_chart(
    df_customers,
    x_col="full_name",
    y_col="total_rentals",
    title="Most Active Customers by Rentals",
    xlabel="Customer",
    ylabel="Total Rentals",
    filename="most_active_customers.png"
)


# =========================
# 7. Staff Performance
# =========================

query_staff = """
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

df_staff = pd.read_sql(query_staff, engine)

save_bar_chart(
    df_staff,
    x_col="staff_name",
    y_col="total_revenue",
    title="Staff Performance by Revenue",
    xlabel="Staff",
    ylabel="Total Revenue",
    filename="staff_performance.png",
    rotation=0
)


# =========================
# 8. Late Returned Films
# =========================

query_late = """
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

df_late = pd.read_sql(query_late, engine)

save_bar_chart(
    df_late,
    x_col="title",
    y_col="late_returns",
    title="Late Returned Films",
    xlabel="Film Title",
    ylabel="Late Returns",
    filename="late_returned_films.png"
)


print("Charts created successfully inside the 'charts' folder.")
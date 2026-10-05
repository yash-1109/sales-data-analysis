# sales-data-analysis
A deep -dive SQL analytics project evaluating multi-year retail sales data to identify profit-draining discounts, customers churn, delivery delays, and pareto distribution,
 Sales Data Analysis using SQL

## 📌 Project Overview
A deep-dive SQL analytics project evaluating multi-year retail sales data to solve critical business problems including profitability traps, product return rates, seasonality, customer churn, and Pareto principle distribution.

---

## 🛠️ Tech Stack & Concepts Applied
- *Database:* MySQL
- *SQL Concepts Used:* Window Functions (LAG, OVER), CTEs (Common Table Expressions), Aggregations, Joins, Date Functions (DATEDIFF, STR_TO_DATE), Conditional Logic (CASE WHEN).

---

## 🔑 Key Business Analyses & Findings
1. *Year-over-Year (YoY) Growth:* Tracked annual revenue and profit trends to evaluate growth trajectory.
2. *Seasonality & Weekend Effect:* Analyzed sales volume and return rates across days of the week.
3. *The Discount Trap:* Evaluated categories with high discounts causing net negative profit margins (e.g., Bookcases & Tables).
4. *Pareto Principle (80/20 Rule):* Identified that *~29.5% of total customers* generate *80% of total revenue*.
5. *Customer Churn Analysis:* Extracted customers active in 2015-2016 who made no purchases in 2017.
6. *30-Day Moving Average:* Calculated smoothed daily sales trends using window functions.
7. *Delivery & Logistics Delay:* Measured shipping delays by Ship_Mode and its direct impact on product return rates.

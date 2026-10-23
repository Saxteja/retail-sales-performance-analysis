# Retail Sales Data Analysis

## Project Overview

This project analyzes a fictional retail dataset to understand sales performance, order trends, product and category performance, and customer purchasing behavior. The workflow combines SQL-based analysis with a multi-page Power BI dashboard.

The dataset is synthetic. Findings describe the supplied dataset and should not be interpreted as results from a real retailer.

## Project Objectives

- Profile the source data and identify data-quality considerations.
- Analyze order status, sales performance, and trends over time.
- Compare product and category performance using delivered order items.
- Understand customer coverage, purchase frequency, repeat purchasing, and sales concentration.
- Present the results in a Power BI dashboard.

## Tools

- **SQLite** — data exploration, metric validation, and analytical queries.
- **Power BI** — data modeling, DAX measures, and dashboard visuals.
- **CSV** — source and processed table files.
- **Markdown / Word** — project documentation.

## Dataset

The dataset includes these core tables:

| Table | Rows | Purpose |
|---|---:|---|
| `customers` | 50,000 | Customer records |
| `orders` | 150,000 | Order-level details, status, dates, and order totals |
| `order_items` | 346,202 | Product lines, quantities, unit prices, and discounts |
| `products` | 5,000 | Product catalog and category information |
| `returns` | 11,934 | Return records |
| `promotions` | 200 | Promotion records |

The dataset covers orders from **January 1, 2023 through April 30, 2024**.

## Repository Structure

```text
retail_sales_data_analysis/
├── README.md
├── docs/
│   └── 01_initial_data_profiling_report.docx
├── raw/
│   └── Original CSV files
├── processed/
│   └── CSV files after whitespace checks/cleanup
├── sql/
│   ├── 01_data_profiling.sql
│   ├── 02_sales_analysis.sql
│   ├── 03_product_category_analysis.sql
│   └── 04_customer_analysis.sql
└── powerbi/
    └── Power BI project/dashboard file and screenshots
```

*Folder and filename examples above describe the intended organization. Keep the names aligned with the actual files in your repository; do not add empty folders or rename existing files solely to match this example.*

## Data Preparation

The source CSV files were retained separately from processed CSV files. The processed files were prepared with checks for leading/trailing whitespace and whitespace-related inconsistencies.

The project should document any additional transformations only if they were actually performed. The initial profiling report records the initial dataset review and its observations.

## SQL Analysis

The SQL scripts are organized by analytical stage:

### 1. Data Profiling
- Table sizes and key uniqueness
- Date coverage and order-status distribution
- Missing-value and data-quality checks
- Initial dataset assessment

### 2. Sales Analysis
- Order-level sales and order-status analysis
- Monthly sales and order trends
- Delivered order metrics and average order value
- Sales performance by relevant dimensions

### 3. Product and Category Analysis
- Units sold, gross item value, discount value, and net item value
- Category sales and contribution
- Top and bottom products by net item value
- Discount analysis by category
- Product price versus sales volume
- Products without delivered sales
- Reconciliation of order-level sales and item-level net value

### 4. Customer Analysis
- Customer coverage and customers without orders
- Repeat purchasing and purchase-frequency distribution
- Top 10 customers by delivered sales
- Monthly active customers and delivered sales
- Top-10% customer sales concentration
- Customer-level summary

The product/category and customer analysis scripts have been drafted for execution against the SQLite database. Their results should be validated before publishing final findings.

## Power BI Dashboard

The Power BI report contains four pages:

1. **Retail Sales Performance** — overview of sales, orders, categories, and status.
2. **Sales Trends & Growth** — monthly performance and growth indicators.
3. **Product & Category Performance** — item-level sales, category contribution, discounts, and product comparisons.
4. **Customer Analysis** — customer rankings, purchase frequency, sales concentration, customer trends, and monthly activity.

Add screenshots of the final report to the repository and link them here when available.

## Metric Definitions and Interpretation

The project uses different measures for different analytical purposes. They should not be treated as interchangeable.

- **Delivered order-level sales:** Sum of `orders.total_amount` for orders whose status is `delivered`.
- **Net item value:** Sum of `quantity × unit_price × (1 − discount_pct / 100)` for order items belonging to delivered orders.
- **Gross item value:** Sum of `quantity × unit_price` before discounts.
- **Discount value:** Sum of `quantity × unit_price × discount_pct / 100`.
- **Units sold:** Sum of item quantities associated with delivered orders.
- **Active customers by month:** Distinct customers with at least one delivered order in that month.
- **Repeat customers:** Customers with at least two orders; when stated as “repeat delivered customers,” the count uses delivered orders only.
- **Purchase frequency:** In the customer-frequency analysis, buckets use total orders across all order statuses.

Order-level sales and item-level net value are calculated from different fields and levels of detail. Small differences may occur, so each metric should retain its explicit definition.

## Validated Dataset Findings

The following figures were checked during the project’s SQLite analysis:

- Customers: **50,000**
- Orders: **150,000**
- Order items: **346,202**
- Products: **5,000**
- Return records: **11,934**
- Orders with status `delivered`: **97,540**
- Customers with at least one order: **35,854**
- Customers with at least one delivered order: **31,152**
- Customers with at least two delivered orders: **19,335**
- Delivered order-level sales: **$143,655,523.24**
- Delivered item-level net value: approximately **$143,655,523.16**
- Delivered units sold: **385,050**
- Weighted item discount rate: approximately **1.47%**
- Top 10% of customers’ share of delivered order-level sales: **42.64%**

These are dataset-specific results, not real-world business claims. Re-run the relevant SQL scripts if the source data or metric definitions change.

## Limitations

- The dataset is synthetic, so its patterns may not represent actual retail behavior.
- Sales and discount measures depend on the selected grain: order-level totals versus item-level calculations.
- The available dataset does not provide a complete finance model; sales analysis should not be described as profit or margin analysis.
- Customer frequency and repeat-customer metrics depend on whether all order statuses or delivered orders are used.
- SQL scripts and report outputs should be re-executed and checked against the current database before publication.

## How to Reproduce the Analysis

1. Load the supplied CSV tables into SQLite.
2. Run `sql/01_data_profiling.sql` to inspect the dataset.
3. Run `sql/02_sales_analysis.sql` for order-level sales analysis.
4. Run `sql/03_product_category_analysis.sql` for item-level product and category analysis.
5. Run `sql/04_customer_analysis.sql` for customer analysis.
6. Compare outputs with the documented metric definitions and validate important totals.
7. Open the Power BI report and refresh the model if the source data has changed.

The SQL scripts assume the table and column names documented in their comments. Adjust database paths or import steps to match your local setup.

## Project Status

- [x] Initial data profiling
- [x] Sales analysis
- [x] Four-page Power BI dashboard
- [x] Product/category SQL analysis script drafted
- [x] Customer SQL analysis script drafted
- [ ] Execute and validate all product/category SQL queries
- [ ] Execute and validate all customer SQL queries
- [ ] Add final dashboard screenshots
- [ ] Update documentation with final query outputs

## Author

Add your name, GitHub profile, and portfolio link here before publishing.

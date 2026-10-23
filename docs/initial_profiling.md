Initial Data Profiling Report

Retail Sales Performance Analysis | Fiction Retail

Purpose: document the first-pass structural profiling results before cleaning, data-quality remediation, metric design, or dashboard development.

1. Dataset overview

Source: Fiction Retail E-Commerce Dataset, supplied as fiction-retail.db (SQLite). The dataset is synthetic and contains interconnected retail order, customer, product, promotion, return, inventory, supplier, warehouse, and shipment data.

Table            Row count observed

customers        50,000

orders           150,000

order_items      346,202

products         5,000

returns          11,934

promotions       200

2. Order status distribution

The following counts and order-value sums were returned by the initial grouping query. The order-value sum is the sum of orders.total_amount for each status; it is not yet a validated net-sales or recognized-revenue measure.

Order status      Order count    Sum of total_amount (USD)

delivered         97,540         143,655,523.24

returned          11,934         17,864,351.65

in_transit        10,462         15,469,790.28

confirmed         7,535          11,318,688.73

fulfilling        7,347          11,091,600.43

canceled          6,069          9,039,603.90

pending           4,591          6,661,166.01

backordered       3,039          4,405,253.09

disputed          1,483          2,013,737.61

3. Date coverage

Earliest order date: 2023-01-01

Latest order date: 2024-04-30

Distinct dates with orders: 486

Interpretation: the period ends on April 30, 2024. Monthly comparisons should account for the dataset ending in April and should not imply coverage beyond that date.

4. Product category coverage

Category        Product count

apparel         998

electronics     794

home_goods      727

books           516

beauty          333

food            291

toys            286

sports          275

tools           244

automotive      184

jewelry         179

other           173

5. Initial observations (not final conclusions)

The six checked tables have row counts matching the dataset documentation.

The orders table contains nine observed statuses; the largest group is delivered (97,540 orders).

The returns count (11,934) equals the number of orders marked returned in the status output. This is worth validating, but it does not by itself prove a one-to-one relationship or explain return accounting.

The order-date range spans January 2023 through April 2024.

Apparel has the largest product count (998), followed by electronics (794) and home_goods (727). Product count is not the same as sales performance.

The grouped sum of orders.total_amount is a raw status-level total. Its business meaning and reconciliation to order-item values still need validation.

6. Distribution of discount_pct values in order_items

309,041 rows (about 89.3%) have discount_pct = 0.

The remaining 37,161 rows (about 10.7%) have non-zero discounts.

The observed non-zero values range from 5 to 30, which looks consistent with discounts expressed as whole-number percentages. We'll use that as a working hypothesis, not a confirmed definition.


7. Order-total reconciliation and record these findings:
- All 150,000 orders were included in the reconciliation query's result.
- All 150,000 compared orders had an absolute difference of at most $0.01 between orders.total_amount and the calculated order-item total.
- Zero compared orders exceeded the $0.01 tolerance.
- The maximum observed absolute difference was approximately $0.005.
- The calculation used quantity × unit_price × (1 − discount_pct / 100).
- This supports consistency between the order-level totals and the calculated discounted item totals for the compared orders. Orders without matching order items have not yet been independently ruled out.
- The order coverage check found 0 orders without matching order items, out of 150,000 orders.
- Combined with the reconciliation results, this means all 150,000 orders had matching line items, and every calculated item total was within $0.01 of orders.total_amount.


8. Primary-key uniqueness checks.

All six checked tables had equal row counts and distinct-ID counts.

No duplicate non-NULL identifiers were detected in the checked columns.

NULL identifiers have not yet been ruled out.

9. Missing-value checks — sales-critical columns.

All four checked columns in orders had zero NULL values: order_id, order_date, total_amount, and order_status.

All five checked columns in order_items had zero NULL values: order_id, product_id, quantity, unit_price, and discount_pct.

This check does not establish that other columns or tables are free of missing values.

10. Sales-value validity checks

No rows had quantity <= 0.

No rows had negative unit_price.

No rows had discount_pct outside the range 0–100.

No NULL unit_price values were found.

These checks cover only the listed conditions in order_items; other validity issues remain untested.


11.  Referential integrity checks:

No orphaned product references were found: every order_items.product_id matched products.product_id.

Other relationships have not yet been checked
No orphaned customer references were found; every orders.customer_id matched customers.customer_id.

Product and customer relationships have passed their respective reference checks.

Promotion and other relationships remain unchecked.

26,970 orders contained a non-NULL promotion ID.

Zero orphaned promotion references were found.

Orders without a promotion ID were excluded from this check and have not been classified as errors.


12. Quantity and price distribution

Metric	                Result	        Interpretation
Minimum quantity	    1	            Smallest observed line-item quantity
Maximum quantity	    5	            Largest observed line-item quantity
Average quantity	    1.71	        Average units per order-item row
Minimum unit price	    $3.15	        Lowest observed unit price
Maximum unit price	    $3,258.59	    Highest observed unit price
Average unit price	    $379.56	        Average recorded unit price across all line-item rows

The 10 highest-priced line items all belonged to jewelry products.

The maximum observed unit price was $3,258.59.

Some products appeared multiple times at different recorded unit prices.

These observations require further investigation; no pricing errors have been confirmed.

Four inspected jewelry products had maximum historical order prices above their current list prices.

The differences ranged from $262.47 to $295.86.

Historical prices and current list prices may represent different points in time; these differences are observations, not confirmed pricing errors.


13. covering the price variation and the limitation that its cause is unknown

Product investigated: Customer-focused discrete product.

Order-item rows: 103.

Observed unit-price range: $407.29–$496.18.

Average unit price: $449.33.

Current list price: $451.90.

Discount pattern: 94 of 103 rows had a 0% discount.

Within-day variation: 12 dates had multiple distinct recorded unit prices.

Limitation: The cause of the price variation is unknown. The current list price may not reflect historical prices, and the available evidence doesn't establish whether the differences are legitimate or erroneous.
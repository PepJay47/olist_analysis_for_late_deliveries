# Late Deliveries at Olist: The Cost and the Cause
 
**[View the interactive dashboard on Tableau Public](https://public.tableau.com/views/OlistVisuals/Dashboard1?:language=en-GB&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)**
 
I analysed 96,470 delivered orders from Olist, a Brazilian e-commerce marketplace, to answer one question: **how much do late deliveries hurt the business, and who causes them?**
 
**Tools USED:** PostgreSQL (pgAdmin) · Python (pandas, SciPy) in Google Colab · Tableau Public
 
---
 
## Key findings
 
1. **6.8% of delivered orders arrive late** (6,534 of 96,470).
2. **Late orders get far worse reviews.** On-time orders average 4.29 stars. Late orders average 2.27. One to three days late triples the share of 1–2 star reviews, and past a week, about 80% of reviews are bad.
3. **Couriers cause most of the delay.** In 78% of late orders, the seller handed the parcel over on time and the courier lost the days in transit.
4. **The north-east suffers most.** Orders to Alagoas (AL) arrive late 21.4% of the time, against 4.5% in São Paulo (SP). Rio de Janeiro (RJ) sits next to SP yet has the most courier-caused late orders of any state: 1,242.
5. **Late deliveries barely affect repeat purchases.** Customers with a late first order return at 2.47% versus 3.04%. The gap passes a significance test but amounts to about 35 customers. Around 97% of customers never order again, late or not.
## Recommendations
 
1. **Enforce seller hand-over deadlines.** Olist controls this directly, and it costs little. If late hand-overs performed like on-time ones, Olist would prevent about 1,150 late orders (18%).
2. **Review courier performance on the worst routes**, starting with the north-east and Rio. RJ alone accounts for 1,242 late orders where the seller met its deadline.
3. **Give north-east customers realistic delivery dates.** Olist already pads estimates for remote states like Amazonas (AM): customers there wait 23.5 days in transit, yet only 2.1% of orders arrive late. North-east customers get tighter promises, and Olist misses them.
4. **Treat retention as its own problem.** Faster delivery will lift review scores, but it won't bring customers back. Almost nobody returns, so Olist needs a separate retention strategy.
---
 
## The data
 
I used the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle: about 100,000 orders placed between 2016 and 2018, split across 9 linked tables (orders, customers, order items, payments, reviews, products, sellers, geolocation and category translations).
 
**Definition of "late":** an order counts as late when the customer received it on a later calendar day than Olist's estimated delivery date. I compared dates rather than timestamps, since customers think in days. An order arriving at 3pm on its due date counts as on time.
 
## Approach
 
### 1. Load and check (SQL)
 
I loaded the 9 CSVs into a `raw` schema in PostgreSQL and left those tables untouched. Before any analysis, I ran data-quality checks:
 
| Check | Result | How I handled it |
|---|---|---|
| Orders with more than one review | Some orders had several reviews | Averaged reviews per order before joining, to avoid double counting |
| Delivered orders with no review | 646 | Kept the orders; excluded them from review analysis only |
| Delivered orders with no courier hand-over date | 1 | Dropped in Python |
| Negative courier days (pickup recorded after delivery) | 20 | Blanked the bad value in Python; kept the orders |
| Products with no category | [ADD YOUR NUMBER] | Not used in this analysis |
 
### 2. Analyse (SQL)
 
I wrote each question as its own query file, building up from the overall late rate to the cause:
 
- Late rate overall, then by customer state and by seller
- Review scores across five lateness buckets
- Seller vs courier: did the seller miss its hand-over deadline, or did the courier lose time afterwards?
- Courier performance by state, using only orders the seller handed over on time
- Retention: a window function finds each customer's first order and checks whether they ordered again
Two findings came from questioning my own results. My first late-rate query compared timestamps and gave 8.1%. My bucket query compared dates and gave a lower count. I picked the date-based definition and used it everywhere, which brought the late rate to 6.8%. Later, I checked whether removing the 20 worst sellers would fix the problem. Those sellers account for only about 380 late orders (6% of the total), which pointed the analysis toward couriers.
 
I then built a view, `analysis.delivered_orders`, with one clean row per delivered order, and exported it for Python and Tableau.
 
### 3. Test (Python)
 
SQL showed the patterns. I used Python to check whether they could be chance.
 
| Question | Test | Result |
|---|---|---|
| Do late orders get worse reviews? | Mann–Whitney U | 2.27 vs 4.29 stars, **p < 0.001** |
| Do late first orders reduce repeat purchases? | Chi-square | 2.47% vs 3.04%, **p = 0.012** |
 
I chose Mann–Whitney over a t-test because review scores are 1–5 ratings, not continuous values with a normal distribution.
 
The retention result shows why significance alone can mislead: the effect is real but small. The business case for fixing delivery rests on reviews.
 
### 4. Visualise (Tableau)
 
The dashboard tells the story in three charts: the cost (bad reviews by lateness), the location (late rate by state) and the cause (seller vs courier), followed by the recommendations.
 
---
 
## Results in detail
 
**Review scores by lateness**
 
| Delivery | Orders | Avg review | Bad reviews (1–2 stars) |
|---|---|---|---|
| On time or early | 89,443 | 4.29 | 9.2% |
| 1–3 days late | 1,852 | 3.29 | 32.2% |
| 4–7 days late | 1,748 | 2.11 | 67.6% |
| 8–14 days late | 1,446 | 1.67 | 80.1% |
| 15+ days late | 1,335 | 1.73 | 78.2% |
 
**Seller vs courier**
 
| Seller hand-over | Orders | Late orders | Late rate |
|---|---|---|---|
| Late | 5,570 | 1,460 (22% of late orders) | 26.2% |
| On time | 90,899 | 5,073 (78% of late orders) | 5.6% |
 
A seller who misses the hand-over deadline makes a late delivery almost five times more likely. Late hand-overs are rare, though, so couriers still account for most late orders.
 
**Olist overpromises on time.** The median order has a 24-day estimate and arrives in 10. Most orders beat their promise by about two weeks, so a late order marks a real failure. Long estimates may also cost Olist sales at checkout, which this dataset can't measure.
 
---
 
## Limitations
 
- **The data ends in 2018.** Customers who first ordered near the end had less time to return, which lowers the measured return rate for both groups.
- **Small states.** Roraima (RR), Amapá (AP) and Acre (AC) each have fewer than 100 orders, so treat their late rates with caution. The SQL state analysis excludes them.
- **Multi-seller orders.** For orders with items from several sellers, I used the latest hand-over deadline.
- **The dashboard uses the SQL view directly**, so it still contains the 20 negative courier-day values I blanked in Python. They don't affect any chart shown.
---
 
## How to reproduce
 
1. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and unzip it.
2. Edit the folder path in the load script, then run it in psql or pgAdmin's PSQL Tool.
3. Run the analysis SQL files in numbered order in the pgAdmin Query Tool.
4. Export `SELECT * FROM analysis.delivered_orders;` as `delivered_orders.csv`.
5. Open the notebook in Google Colab and upload the CSV when prompted.
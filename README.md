# Customer Segmentation & Churn Risk Analysis (RFM + Predictive Modeling)

![SQL](https://img.shields.io/badge/SQL-4169E1) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791) ![Python](https://img.shields.io/badge/Python-3776AB) ![pandas](https://img.shields.io/badge/pandas-150458) ![scikit--learn](https://img.shields.io/badge/scikit--learn-F7931E) ![Power BI](https://img.shields.io/badge/Power%20BI-F2C811) ![DAX](https://img.shields.io/badge/DAX-FFB900)

![Logistic Regression](https://img.shields.io/badge/Model-Logistic%20Regression-9cf) ![Cohort Analysis](https://img.shields.io/badge/Analysis-Cohort-lightgrey) ![RFM Segmentation](https://img.shields.io/badge/Analysis-RFM%20Segmentation-lightgrey)

An analytics project that segments customers by value, flags churn risk, and puts a number on the revenue involved. Built using SQL, Python, and Power BI on the UCI Online Retail II dataset.

---

## Highlights

- Analyzed **~800,000 transaction records** spanning **2 years** to segment the customer base by value and behavior. The top 10% of customers generate **~64% of total revenue**, which shows exactly where retention spend has the highest return.
- Measured revenue at risk from disengaging customers two separate ways, a rule-based segmentation and a predictive model, and the two independently landed in the same range: **~£524,956 to £860,163**. Having both methods agree makes the number easier to trust and act on.
- **444 customers** currently sit in the At-Risk / Needs-Win-Back segments, together holding **~£860,163 in revenue, or 5.3% of total revenue**. That is the ceiling on what focused retention outreach to this group could protect.
- Built a **logistic regression churn model** on 2,410 active customers, covering feature engineering, threshold selection, and coefficient interpretation, and reached **76% accuracy** with **82% precision** in flagging churners. Recency (how long since a customer's last purchase) came out as the strongest predictor by a clear margin.
- Flagged **910 customers** whose most recent purchase gap has more than doubled versus their own historical average. This is a behavior-triggered list, not a generic "hasn't bought in a while" export, so it's ready to hand to a retention team as-is.
- Found that the **UK carries a higher at-risk revenue share (5.7%) than International (3.2%)**, despite being the larger, more established market. That runs counter to the usual assumption that overseas customers are the bigger churn risk, and it changes where retention focus should actually go.
- Caught a **label-leakage flaw** in the churn model before it shipped: the target variable had been built in a way that let the model see part of the answer in advance, which would have produced an accuracy score that looked good but meant nothing in practice.

---

## Business Problem

Not all customers are equal, but many retention strategies treat them that way. Without segmenting customers by value and risk, businesses end up spending retention effort inefficiently — chasing low-value customers while high-value ones quietly disengage, often without anyone noticing until the revenue loss shows up in the numbers.

This project addresses that gap by:
- Segmenting customers by purchase value and behavior (RFM analysis)
- Flagging customers at risk of churning, both by rule-based scoring and a predictive model
- Quantifying exactly how much revenue is at stake, and where

---

## Dataset

- **Source:** [UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii)
- **Timeframe:** December 2009 – December 2011
- **Scope:** ~800K invoice-level transaction rows for a UK-based online retailer, including international customers

---

## Skills Demonstrated

**SQL (PostgreSQL)**
- Window functions: `RANK()`, `NTILE()`, `FIRST_VALUE()`, `LAG()`
- CTEs and layered subqueries for multi-step business logic
- Self-joins for gap and cohort analysis
- Conditional aggregation (`FILTER`) for segmented metrics
- Views for reusable query logic across multiple downstream questions

**Python**
- Data cleaning and preprocessing with `pandas` (handling missing IDs, duplicates, cancellations)
- Feature engineering from raw transaction data (recency, frequency, monetary, purchase-gap features)
- Churn threshold selection using distribution analysis (median, percentiles)
- Logistic regression modeling, coefficient interpretation, and confusion-matrix-based error analysis
- Tested class-weighted training to address missed churners, found it made the problem worse rather than better, and kept the simpler default model since it was both more explainable and better on the error that matters most to the business

**Power BI**
- Data modeling from a live PostgreSQL connection (Import mode)
- Custom DAX measures and calculated columns for dynamic KPIs
- Multi-page interactive dashboard design with slicers and cross-filtering
- Dashboard QA, auditing visuals against source data to catch and fix accuracy bugs

**Analytical Thinking**
- Translating a vague business problem into a structured, testable analysis plan
- Recognizing and correcting a data-leakage bug in a predictive model
- Cross-validating findings using two independent methods (rule-based vs. model-based)
- Communicating technical findings as business recommendations

---

## Methodology

1. **Data Cleaning** — Removed rows missing Customer ID, handled cancellations/negative quantities, dropped duplicates and invalid price rows.
2. **RFM Segmentation** — Calculated Recency, Frequency, and Monetary scores per customer; built custom segments (High Value, Loyal, At Risk, Needs Win-Back, and others) based on score patterns.
3. **SQL Analysis (13 questions across 4 blocks)** — Segment validation, revenue-at-risk, cohort retention (using window functions and self-joins), and UK vs. International comparison.
4. **Churn Prediction Model** — Engineered features from purchase gaps, defined a churn threshold, and trained a logistic regression model in Python to predict churn probability and revenue at risk.
5. **Power BI Dashboard** — Built a 5-page interactive dashboard connecting all the above into a single, explorable view.

---

## Key Business Insights

**1. A small group of customers drives most of the revenue.**
The top-performing customer segment (High Value) accounts for roughly 70% of total revenue, with the next tier (Loyal customers) adding another 15%. Everything else contributes only a small share. Looked at another way, the top 10% of customers by spend generate nearly two-thirds of all revenue. This pattern holds true internationally as well, not just in the UK.

*What this means: retention efforts should focus mainly on this small, high-value group — keeping one of these customers is worth far more than keeping several low-spending ones.*

**2. A meaningful share of revenue is at risk of being lost.**
Using two different approaches gave consistent results: customers flagged as at-risk by their purchase behavior account for about £860,163 in revenue, while a predictive model estimates the figure at around £524,956 once individual churn likelihood is factored in. Separately, 910 customers have started buying noticeably less often than their usual pattern — this group is the clearest, most immediate list for follow-up.

One finding stood out: the UK, despite being the larger and more established market, has a *higher* share of at-risk revenue than international customers (5.7% vs 3.2%). The assumption that overseas customers are the bigger churn risk doesn't hold here.

*What this means: outreach shouldn't be limited to international markets — UK customers need equal attention.*

**3. The biggest warning sign is how recently someone last purchased — not how often or how much.**
Among the three factors studied, how recently a customer last bought something was by far the strongest predictor of churn. Total spend was the second most important factor, and it works in the opposite direction — higher spenders are less likely to leave. How frequently someone buys mattered the least.

Separately, looking at the earliest customer cohort (the only one with a full 12-month window of data), retention doesn't decline to zero over time — it drops sharply in the first month, then settles into a steady range and holds there. This suggests a stable base of repeat customers rather than one-time buyers.

*What this means: campaigns aimed at winning back customers should be triggered by how long it's been since their last purchase, not by how often they've historically shopped.*

**4. Recommendations**
- Prioritize retention spend on the top-value customer segment first.
- Use the list of 910 customers with unusual gaps in purchasing as an immediate action list.
- Don't treat the UK market as low-risk — it currently needs as much attention as international markets.
- Time win-back efforts around each customer's own purchase rhythm rather than generic frequency-based offers.
- When deciding how the churn model flags risky customers, lean toward catching more at-risk customers, even if it means a few false alarms — missing an actual churner is the costlier mistake.

---

## Dashboard Preview

**1. Overview**
Top-level KPIs (churn rate, total revenue, revenue-at-risk from both methods, total customers) alongside revenue-by-segment and churn distribution.

![Overview](images/overview.png)

**2. Segmentation**
Customer count and revenue by segment, plus an RFM bubble chart showing recency, frequency, and monetary value together.

![Segmentation](images/segmentation.png)

**3. Retention & Purchase Behaviour**
Cohort retention matrix by month, alongside the widened-purchase-gap customer list.

![Retention](images/retention.png)

**4. Regional Insights**
At-risk percentage and average order value compared across UK and International markets.

![Regional Insights](images/regional.png)

**5. Churn Prediction Model**
Model performance (precision, recall, accuracy, confusion matrix), feature coefficients, and the top 10 highest-revenue-at-risk customers.

![Churn Model](images/churn_model.png)

*(Place your exported screenshots in an `images/` folder alongside this README, named as above — or update the paths to match your filenames.)*

---

## Model Performance Summary

| Metric | Value |
|---|---|
| Accuracy | 76% |
| Precision (Churned) | 0.82 |
| Recall (Churned) | 0.78 |
| Strongest predictor | Recency (+1.59) |
| Protective factor | Monetary value (-1.35) |
| Revenue-at-risk (model-based) | ~£524,956 |
| Revenue-at-risk (rule-based) | ~£860,163 |

---

## Challenges & Fixes

Every analytics project runs into problems along the way — documenting them is part of showing the work, not just the result.

- **Recency-leakage in churn labeling.** In an early version, customers whose recency was already above the churn threshold at the cutoff date were automatically labeled as churned, regardless of what they actually did afterward. This meant the label was partly determined by the same variable being used to predict it, which would have inflated the model's apparent accuracy without it being real. The fix was to restrict the modeling population to customers who were still active at the cutoff, so the churn label reflected a genuine, testable outcome instead.

- **Widened-purchase-gap count discrepancy.** An early result showed only 9 customers with a significantly widened purchase gap. Rebuilding the same query with a proper `COUNT(*)` check, instead of reading a partial result set, showed the true figure was 975. A further refinement, filtering out cases where the gap ratio was distorted by extremely high-frequency customers, brought the final, verified figure to 910, which matched consistently across both SQL and the Power BI dashboard.

Both issues were caught by going back and re-verifying results rather than accepting the first output, a habit carried through the rest of the project.

---

## Repository Structure

```
├── rfm-sql-questions.sql          # All 13 SQL questions + churn model prep (PostgreSQL)
├── rfm-project.ipynb              # Data cleaning + RFM calculation
├── churn-model-rfm-project.ipynb  # Churn feature prep + logistic regression model
├── power-bi-rfm-project.pbix      # Power BI dashboard file
├── images/                        # Exported dashboard screenshots (for this README)
└── README.md
```

---

## How to Run This Project

1. Clone this repository.
2. Load the raw dataset into PostgreSQL and run the queries in `rfm-sql-questions.sql`.
3. Run `rfm-project.ipynb`, then `churn-model-rfm-project.ipynb`, in that order.
4. Open `power-bi-rfm-project.pbix` in Power BI Desktop and connect it to your PostgreSQL database (Import mode).
5. Refresh the dashboard to view the latest data.

---

## Future Improvements

- Test alternative churn models (e.g., random forest, XGBoost) to compare against the logistic regression baseline.
- Incorporate Customer Lifetime Value (CLV) alongside revenue-at-risk for a longer-term view.
- Automate the SQL-to-Power BI refresh pipeline for live/recurring reporting.

---

## Contact

*(Add your name, LinkedIn, and/or email here.)*

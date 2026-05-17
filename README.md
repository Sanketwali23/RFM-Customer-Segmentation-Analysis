# 🛒 RFM Customer Segmentation — Online Retail II

![SQL](https://img.shields.io/badge/SQL-Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-Dashboard-217346?style=for-the-badge&logo=microsoftexcel&logoColor=white)
![Dataset](https://img.shields.io/badge/UCI-Online%20Retail%20II-orange?style=for-the-badge)

> **1,067,371 transactions. 5,878 customers scored. One brutal truth: 22% of customers drive 72.2% of revenue.**

---

## 📐 What is RFM?

RFM ranks every customer on three axes — **Recency** (how recently they bought), **Frequency** (how often), and **Monetary** (how much). Each gets a 1–5 score via `NTILE(5)`, combined into a segment label. Simple model. Serious business impact.

---

## 🔢 Key Numbers

| Metric | Value |
|---|---|
| 🗄️ Raw rows ingested | 1,067,371 |
| ✅ Rows after cleaning | 805,549 *(75.5% retained)* |
| 👥 Unique customers scored | 5,878 |
| 💷 Total revenue analysed | £17,743,429 |
| 🏆 Champions (22% of customers) | **72.2% of revenue** |
| ⚠️ At-Risk revenue at stake | **£602,704** |
| ❌ Lost customers | 802 customers · avg **517 days** inactive |

---

## 🗂️ Segments at a Glance

| Segment | Customers | Strategy |
|---|---|---|
| 🏆 Champions | 1,293 | Reward & protect — they're your business |
| 💛 Loyal Customers | 847 | Upsell & keep warm |
| 🌱 Potential Loyalists | 712 | Nudge to commit with a loyalty incentive |
| 🆕 New Customers | 406 | Onboard well — first 90 days are critical |
| ⚠️ At Risk | 618 | Win-back campaign **now** — £602K on the line |
| 😴 Need Attention | 1,200 | Re-engage before they slip to Lost |
| ❌ Lost | 802 | One last automated campaign, then suppress |

---

## 🏗️ Stack & Files

| File | Description |
|---|---|
| `rfm_analysis_sqlserver.sql` | 10-step SQL pipeline — cleaning → scoring → segmentation |
| `RFM_Dashboard.xlsx` | 4-sheet Excel workbook with KPI cards, charts & cleaning log |
| `rfm_summary.csv` | Segment-level aggregates |
| `rfm_customers.csv` | All 5,878 customers with R/F/M scores and labels |

---

## 🚀 Reproduce It

```bash
# 1. Download Online Retail II from Kaggle
# 2. Import into SQL Server as table: retail
# 3. Run rfm_analysis_sqlserver.sql (Steps 1–10)
# 4. Export results → rfm_summary.csv & rfm_customers.csv
# 5. Open RFM_Dashboard.xlsx
```

---

<sub>Dataset: UCI Online Retail II · Reference date: 2011-12-10 · Scored via NTILE(5) quintiles</sub>

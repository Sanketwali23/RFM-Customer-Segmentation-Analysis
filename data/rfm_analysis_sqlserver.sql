-- =============================================================================
-- RFM Customer Segmentation Analysis
-- Dataset : Online Retail II UCI (Kaggle)
-- Tool    : Microsoft SQL Server
-- Author  : [Your Name]
-- Date    : 2024
-- =============================================================================
-- Reference date: 2011-12-10 (one day after the last transaction in the dataset)
-- Scoring: Quintile-based 1-5 scale using NTILE(5)
--   Recency  -> lower days since purchase = higher score (5 = best)
--   Frequency -> higher order count = higher score (5 = best)
--   Monetary  -> higher spend = higher score (5 = best)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- STEP 1: Verify the import
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS total_rows FROM retail;

SELECT TOP 5 * FROM retail;


-- -----------------------------------------------------------------------------
-- STEP 2: Explore data quality
-- -----------------------------------------------------------------------------
-- Count cancelled orders (Invoice starting with 'C')
SELECT COUNT(*) AS cancelled_orders
FROM retail
WHERE Invoice LIKE 'C%';

-- Count rows with missing Customer ID
SELECT COUNT(*) AS missing_customer_id
FROM retail
WHERE [Customer ID] IS NULL OR [Customer ID] = '';

-- Check price and quantity outliers
SELECT
    MIN(Price)    AS min_price,
    MAX(Price)    AS max_price,
    MIN(Quantity) AS min_qty,
    MAX(Quantity) AS max_qty
FROM retail;

-- Unique customers and countries
SELECT
    COUNT(DISTINCT [Customer ID]) AS unique_customers,
    COUNT(DISTINCT Country)       AS unique_countries
FROM retail
WHERE [Customer ID] IS NOT NULL;


-- -----------------------------------------------------------------------------
-- STEP 3: Calculate R, F, M per customer
-- (Using already-cleaned data; adjust table name if needed)
-- -----------------------------------------------------------------------------
SELECT
    [Customer ID],
    MAX(CAST(InvoiceDate AS DATE))                                                         AS last_purchase_date,
    DATEDIFF(DAY, MAX(CAST(InvoiceDate AS DATE)), '2011-12-10')                            AS Recency_Days,
    COUNT(DISTINCT Invoice)                                                                AS Frequency,
    ROUND(SUM(Quantity * Price), 2)                                                        AS Monetary
FROM retail
WHERE [Customer ID] IS NOT NULL
  AND [Customer ID] != ''
  AND Invoice NOT LIKE 'C%'
  AND Quantity > 0
  AND Price > 0
GROUP BY [Customer ID]
ORDER BY Monetary DESC;


-- -----------------------------------------------------------------------------
-- STEP 4: Create VIEW - RFM base scores (1-5 per dimension)
-- -----------------------------------------------------------------------------
IF OBJECT_ID('rfm_scores', 'V') IS NOT NULL
    DROP VIEW rfm_scores;
GO

CREATE VIEW rfm_scores AS
WITH rfm_base AS (
    SELECT
        [Customer ID],
        MAX(CAST(InvoiceDate AS DATE))                                              AS last_purchase_date,
        DATEDIFF(DAY, MAX(CAST(InvoiceDate AS DATE)), '2011-12-10')                 AS Recency,
        COUNT(DISTINCT Invoice)                                                     AS Frequency,
        ROUND(SUM(Quantity * Price), 2)                                             AS Monetary
    FROM retail
    WHERE [Customer ID] IS NOT NULL
      AND [Customer ID] != ''
      AND Invoice NOT LIKE 'C%'
      AND Quantity > 0
      AND Price > 0
    GROUP BY [Customer ID]
)
SELECT
    [Customer ID],
    last_purchase_date,
    Recency,
    Frequency,
    Monetary,
    NTILE(5) OVER (ORDER BY Recency ASC)     AS R_Score,   -- lower days = higher score
    NTILE(5) OVER (ORDER BY Frequency DESC)  AS F_Score,   -- more orders = higher score
    NTILE(5) OVER (ORDER BY Monetary DESC)   AS M_Score    -- more spend = higher score
FROM rfm_base;
GO

-- Verify
SELECT TOP 10 * FROM rfm_scores;


-- -----------------------------------------------------------------------------
-- STEP 5: Create VIEW - Segment labels
-- -----------------------------------------------------------------------------
IF OBJECT_ID('rfm_segments', 'V') IS NOT NULL
    DROP VIEW rfm_segments;
GO

CREATE VIEW rfm_segments AS
SELECT
    [Customer ID],
    last_purchase_date,
    Recency,
    Frequency,
    Monetary,
    R_Score,
    F_Score,
    M_Score,
    (R_Score + F_Score + M_Score)                                                     AS RFM_Total,
    (CAST(R_Score AS VARCHAR) + CAST(F_Score AS VARCHAR) + CAST(M_Score AS VARCHAR))  AS RFM_Code,
    CASE
        WHEN (R_Score + F_Score + M_Score) >= 13                  THEN 'Champions'
        WHEN (R_Score + F_Score + M_Score) >= 10                  THEN 'Loyal Customers'
        WHEN (R_Score + F_Score + M_Score) >= 7 AND R_Score >= 3  THEN 'Potential Loyalists'
        WHEN R_Score >= 4 AND F_Score <= 2                         THEN 'New Customers'
        WHEN R_Score <= 2 AND F_Score >= 3                         THEN 'At Risk'
        WHEN (R_Score + F_Score + M_Score) <= 4                   THEN 'Lost'
        ELSE                                                            'Need Attention'
    END AS Segment
FROM rfm_scores;
GO

-- Verify
SELECT TOP 10 * FROM rfm_segments ORDER BY RFM_Total DESC;


-- -----------------------------------------------------------------------------
-- STEP 6: Segment summary table (export this as rfm_summary.csv)
-- -----------------------------------------------------------------------------
SELECT
    Segment,
    COUNT([Customer ID])                                                                    AS Customer_Count,
    ROUND(AVG(CAST(Recency AS FLOAT)), 1)                                                   AS Avg_Recency_Days,
    ROUND(AVG(CAST(Frequency AS FLOAT)), 1)                                                 AS Avg_Orders,
    ROUND(AVG(Monetary), 2)                                                                 AS Avg_Revenue_Per_Customer,
    ROUND(SUM(Monetary), 2)                                                                 AS Total_Revenue,
    ROUND(100.0 * COUNT([Customer ID]) / (SELECT COUNT(*) FROM rfm_segments), 1)            AS Pct_Customers,
    ROUND(100.0 * SUM(Monetary) / (SELECT SUM(Monetary) FROM rfm_segments), 1)              AS Pct_Revenue
FROM rfm_segments
GROUP BY Segment
ORDER BY Total_Revenue DESC;


-- -----------------------------------------------------------------------------
-- STEP 7: Top 20 highest-value customers
-- -----------------------------------------------------------------------------
SELECT TOP 20
    [Customer ID],
    Segment,
    Recency,
    Frequency,
    Monetary,
    RFM_Total,
    RFM_Code
FROM rfm_segments
ORDER BY Monetary DESC;


-- -----------------------------------------------------------------------------
-- STEP 8: At-Risk deep dive - who to target for win-back
-- -----------------------------------------------------------------------------
SELECT
    [Customer ID],
    last_purchase_date,
    Recency    AS days_since_last_purchase,
    Frequency  AS total_orders,
    Monetary   AS total_spend,
    RFM_Code
FROM rfm_segments
WHERE Segment = 'At Risk'
ORDER BY Monetary DESC;


-- -----------------------------------------------------------------------------
-- STEP 9: Champions profile
-- -----------------------------------------------------------------------------
SELECT
    COUNT([Customer ID])             AS champion_count,
    ROUND(AVG(CAST(Recency AS FLOAT)), 1)   AS avg_days_since_last_purchase,
    ROUND(AVG(CAST(Frequency AS FLOAT)), 1) AS avg_orders,
    ROUND(AVG(Monetary), 2)          AS avg_spend,
    ROUND(SUM(Monetary), 2)          AS total_revenue,
    MIN(Monetary)                    AS min_spend,
    MAX(Monetary)                    AS max_spend
FROM rfm_segments
WHERE Segment = 'Champions';


-- -----------------------------------------------------------------------------
-- STEP 10: Revenue concentration check (top 20% of customers = what % of revenue?)
-- -----------------------------------------------------------------------------
WITH ranked AS (
    SELECT
        [Customer ID],
        Monetary,
        NTILE(5) OVER (ORDER BY Monetary DESC) AS revenue_quintile
    FROM rfm_segments
)
SELECT
    revenue_quintile,
    COUNT(*)                  AS customer_count,
    ROUND(SUM(Monetary), 2)   AS total_revenue,
    ROUND(100.0 * SUM(Monetary) / (SELECT SUM(Monetary) FROM rfm_segments), 1) AS pct_revenue
FROM ranked
GROUP BY revenue_quintile
ORDER BY revenue_quintile;

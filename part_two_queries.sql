-- Bullets 1, 2. "How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for previous month?"

WITH RecentItemPurchases_CTE AS (
    SELECT
        *,
        FROM_UNIXTIME(dateScanned, '%Y-%m') as purchase_month
    FROM
        ItemPurchases
),
RecentReceipts_CTE AS (
    SELECT
        *,
        FROM_UNIXTIME(dateScanned, '%Y-%m') as purchase_month
    FROM
        Receipts
),
BrandPurchases AS (
    SELECT 
        rr.purchase_month,
        b.name as brand_name,
        SUM(rip.quantityPurchased) as purchase_count,
        DENSE_RANK() OVER (PARTITION BY rr.purchase_month ORDER BY SUM(rip.quantityPurchased) DESC) as brand_rank
    FROM
        RecentItemPurchases_CTE rip
        INNER JOIN RecentReceipts_CTE rr ON rip.receiptId = rr._id
        INNER JOIN Products p ON rip.barcode = p.barcode
        INNER JOIN Brands b ON p.brandCode = b.brandCode
    GROUP BY 
        rr.purchase_month, b.name
)

SELECT 
    purchase_month,
    brand_name,
    purchase_count
FROM
    BrandPurchases
WHERE
    brand_rank <= 5
ORDER BY 
    purchase_month DESC,
    purchase_count DESC

;

-- Bullets 3, 4. "When considering average spend and total items purchased from receipts with 'rewardsReceiptStatus' of 'Accepted' or 'Rejected', which is greater?"

SELECT
    rewardsReceiptStatus,
    AVG(totalSpent) as average_spend,
    SUM(totalItems) as total_items
FROM
    Receipts
WHERE
    rewardsReceiptStatus IN ('Accepted', 'Rejected')
GROUP BY
    rewardsReceiptStatus

;

-- Bullets 5, 6. "Which brands have the most spend and transactions among users who were created within the past 6 months?"

WITH RecentUsers_CTE AS (
    SELECT
        *
    FROM
        Users
    WHERE
        createdDate >= NOW() - INTERVAL 6 MONTH
)

SELECT
    b.name,
    SUM(rr.totalSpent) as total_spend,
    COUNT(*) as transaction_count
FROM
    RecentItemPurchases_CTE rip
    INNER JOIN RecentReceipts_CTE rr ON rip.receiptId = rr._id
    INNER JOIN Products p ON rip.barcode = p.barcode
    INNER JOIN Brands b ON p.brandCode = b.brandCode
    INNER JOIN RecentUsers_CTE u ON rr.userId = u._id
GROUP BY
    b.name
ORDER BY
    total_spend DESC, transaction_count DESC

;

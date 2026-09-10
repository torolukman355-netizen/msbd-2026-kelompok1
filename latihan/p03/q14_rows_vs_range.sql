WITH
    Q13_Versi_Rows AS (
        SELECT
            DATE (payment_date) AS tanggal,
            SUM(SUM(amount)) OVER (
                ORDER BY
                    DATE (payment_date) ROWS BETWEEN UNBOUNDED PRECEDING
                    AND CURRENT ROW
            ) AS kumulatif,
            AVG(SUM(amount)) OVER (
                ORDER BY
                    DATE (payment_date) ROWS BETWEEN 6 PRECEDING
                    AND CURRENT ROW
            ) AS rerata
        FROM
            payment
        GROUP BY
            DATE (payment_date)
    ),
    Q14_Versi_Range AS (
        SELECT
            DATE (payment_date) AS tanggal,
            SUM(SUM(amount)) OVER (
                ORDER BY
                    DATE (payment_date)
            ) AS kumulatif,
            AVG(SUM(amount)) OVER (
                ORDER BY
                    DATE (payment_date)
            ) AS rerata
        FROM
            payment
        GROUP BY
            DATE (payment_date)
    )
SELECT
    r.tanggal,
    r.kumulatif AS kumulatif_rows,
    g.kumulatif AS kumulatif_range,
    r.rerata AS rerata_rows,
    g.rerata AS rerata_range
FROM
    Q13_Versi_Rows r
    JOIN Q14_Versi_Range g ON r.tanggal = g.tanggal
WHERE
    r.kumulatif IS DISTINCT
FROM
    g.kumulatif
    OR r.rerata IS DISTINCT
FROM
    g.rerata
ORDER BY
    r.tanggal;
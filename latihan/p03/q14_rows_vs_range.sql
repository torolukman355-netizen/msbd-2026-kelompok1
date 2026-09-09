-- Diminta: Menjalankan ulang Q13 tanpa klausa frame dan mencari tanggal yang hasilnya berbeda.
-- Dipilih: Operator EXCEPT karena sangat efisien mengidentifikasi baris yang tidak memiliki kecocokan identik di query pembanding.
-- Alternatif: FULL OUTER JOIN; tidak dipilih karena penulisan kondisinya terlalu panjang (harus mengecek NULL di kedua sisi).

WITH Q13_Versi_Rows AS (
    SELECT
        DATE(payment_date) AS tanggal,
        SUM(SUM(amount)) OVER (ORDER BY DATE(payment_date) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS kumulatif,
        AVG(SUM(amount)) OVER (ORDER BY DATE(payment_date) ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rerata
    FROM payment
    GROUP BY DATE(payment_date)
),
Q14_Versi_Range AS (
    SELECT
        DATE(payment_date) AS tanggal,
        SUM(SUM(amount)) OVER (ORDER BY DATE(payment_date)) AS kumulatif,
        AVG(SUM(amount)) OVER (ORDER BY DATE(payment_date)) AS rerata
    FROM payment
    GROUP BY DATE(payment_date)
)
SELECT tanggal FROM Q13_Versi_Rows
EXCEPT
SELECT tanggal FROM Q14_Versi_Range;

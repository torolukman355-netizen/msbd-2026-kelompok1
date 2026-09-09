-- Diminta: Menampilkan omzet harian, total kumulatif dari hari pertama, dan rata-rata bergerak 7 hari.
-- Dipilih: Window function dengan klausa ROWS karena dapat membatasi rentang baris spesifik untuk kalkulasi.
-- Alternatif: Correlated subquery; tidak dipilih karena lambat dan memakan banyak memori akibat eksekusi berulang.

WITH OmzetHarian AS (
    SELECT
        DATE(payment_date) AS tanggal,
        SUM(amount) AS omzet_hari_ini
    FROM payment
    GROUP BY DATE(payment_date)
)
SELECT
    tanggal,
    omzet_hari_ini,
    SUM(omzet_hari_ini) OVER (ORDER BY tanggal ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS kumulatif_total,
    AVG(omzet_hari_ini) OVER (ORDER BY tanggal ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rerata_7_hari
FROM OmzetHarian;
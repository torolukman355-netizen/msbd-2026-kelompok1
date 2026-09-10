-- Diminta: Menampilkan urutan pembayaran, jarak hari dari pembayaran sebelumnya,
-- dan total belanja per pelanggan.
-- Dipilih: Window function (ROW_NUMBER, LAG, dan SUM) dengan PARTITION BY
-- customer_id agar kalkulasi terisolasi per pelanggan.
-- Alternatif: Subquery skalar pada klausa SELECT; tidak dipilih karena
-- mengeksekusi subquery berulang kali per baris.
WITH
    riwayat_pembayaran AS (
        SELECT
            customer_id,
            payment_date,
            amount,
            ROW_NUMBER() OVER (
                PARTITION BY
                    customer_id
                ORDER BY
                    payment_date
            ) AS urutan_pembayaran,
            LAG (payment_date) OVER (
                PARTITION BY
                    customer_id
                ORDER BY
                    payment_date
            ) AS pembayaran_sebelumnya
        FROM
            payment
    )
SELECT
    customer_id,
    payment_date,
    urutan_pembayaran,
    EXTRACT(
        DAY
        FROM
            (payment_date - pembayaran_sebelumnya)
    ) AS jarak_hari,
    SUM(amount) OVER (
        PARTITION BY
            customer_id
    ) AS total_belanja
FROM
    riwayat_pembayaran
ORDER BY
    customer_id,
    payment_date;
-- Diminta: Menampilkan urutan pembayaran, jarak hari dari pembayaran sebelumnya, dan total belanja per pelanggan.
-- Dipilih: Window function (ROW_NUMBER, LAG, dan SUM) dengan PARTITION BY customer_id agar kalkulasi terisolasi per pelanggan.
-- Alternatif: Subquery skalar pada klausa SELECT; tidak dipilih karena mengeksekusi subquery berulang kali per baris membebani memori.

SELECT
    customer_id,
    payment_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date) AS urutan_pembayaran,
    DATEDIFF(payment_date, LAG(payment_date) OVER (PARTITION BY customer_id ORDER BY payment_date)) AS jarak_hari,
    SUM(amount) OVER (PARTITION BY customer_id) AS total_belanja
FROM payment
ORDER BY customer_id, payment_date;
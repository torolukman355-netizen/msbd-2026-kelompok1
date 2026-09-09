-- Diminta: mencari judul film yang tarif sewanya di atas rata-rata tarif seluruh film, diurutkan menurun, beserta rata-rata dan selisihnya.
-- Dipilih: subquery skalar di WHERE dan SELECT karena tiap subquery menghasilkan satu nilai (rata-rata keseluruhan) yang dipakai berulang.
-- Alternatif: CTE untuk menyimpan rata-rata sekali di awal; tidak dipilih karena soal secara eksplisit minta bentuk subquery skalar.

SELECT
    title,
    rental_rate,
    (SELECT AVG(rental_rate) FROM film) AS rata_rata,
    rental_rate - (SELECT AVG(rental_rate) FROM film) AS selisih
FROM film
WHERE rental_rate > (SELECT AVG(rental_rate) FROM film)
ORDER BY rental_rate DESC;
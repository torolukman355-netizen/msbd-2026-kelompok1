-- Diminta: untuk setiap toko, judul film dengan tarif sewa tertinggi di toko tersebut, tanpa window function.
-- Dipilih: subquery berkorelasi dengan MAX karena perlu membandingkan tarif tiap film dengan nilai maksimum khusus di tokonya masing-masing.
-- Alternatif: window function (RANK/MAX OVER PARTITION BY store_id); tidak dipilih karena soal secara eksplisit meminta penyelesaian tanpa window function.

SELECT DISTINCT
    s.store_id,
    f.title,
    f.rental_rate
FROM film f
JOIN inventory i ON i.film_id = f.film_id
JOIN store s ON s.store_id = i.store_id
WHERE f.rental_rate = (
    SELECT MAX(f2.rental_rate)
    FROM film f2
    JOIN inventory i2 ON i2.film_id = f2.film_id
    WHERE i2.store_id = s.store_id
)
ORDER BY s.store_id;
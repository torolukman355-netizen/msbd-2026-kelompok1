-- Diminta: per kategori, tampilkan jumlah film total, jumlah film rating G, jumlah film rating PG-13, dan rata-rata durasi film lebih dari 90 menit dalam satu baris.
-- Dipilih: dua versi (klausa FILTER dan CASE WHEN) untuk membandingkan cara penulisan agregasi bersyarat dan pengaruh perhitungannya.
-- Alternatif: GROUP BY biasa tanpa agregasi bersyarat / conditional aggregation; tidak dipilih karena tidak bisa menampilkan metrik dengan filter berbeda dalam satu baris per kategori.

-- Menggunakan Klausa FILTER
SELECT
    c.name AS kategori,
    COUNT(f.film_id) AS total_film,
    COUNT(f.film_id) FILTER (WHERE f.rating = 'G') AS film_g,
    COUNT(f.film_id) FILTER (WHERE f.rating = 'PG-13') AS film_pg13,
    AVG(f.length) FILTER (WHERE f.length > 90) AS avg_durasi_diatas_90
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
GROUP BY c.name
ORDER BY c.name;

-- Menggunakan Konstruksi CASE WHEN

SELECT
    c.name AS kategori,
    COUNT(f.film_id) AS total_film,
    COUNT(CASE WHEN f.rating = 'G' THEN 1 END) AS film_g,
    COUNT(CASE WHEN f.rating = 'PG-13' THEN 1 END) AS film_pg13,
    AVG(CASE WHEN f.length > 90 THEN f.length END) AS avg_durasi_diatas_90
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
GROUP BY c.name
ORDER BY c.name;


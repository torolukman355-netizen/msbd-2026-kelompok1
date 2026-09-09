-- Diminta: nama kategori beserta jumlah filmnya, hanya kategori yang punya lebih dari 60 film.
-- Dipilih: HAVING karena filter dilakukan langsung setelah agregasi GROUP BY, lebih ringkas untuk kasus sederhana ini.
-- Alternatif: derived table di FROM; tidak dipilih sebagai versi utama karena menambah lapisan subquery yang tidak diperlukan di kasus ini (tetap disertakan untuk perbandingan keterbacaan).


-- Versi 1: pakai HAVING
SELECT
    c.name AS kategori,
    COUNT(fc.film_id) AS jumlah_film
FROM category c
JOIN film_category fc ON fc.category_id = c.category_id
GROUP BY c.name
HAVING COUNT(fc.film_id) > 60;


-- Versi 2: pakai derived table di FROM
SELECT kategori, jumlah_film
FROM (
    SELECT
        c.name AS kategori,
        COUNT(fc.film_id) AS jumlah_film
    FROM category c
    JOIN film_category fc ON fc.category_id = c.category_id
    GROUP BY c.name
) AS kategori_count
WHERE jumlah_film > 60;

-- ============================================
-- Perbandingan keterbacaan:
-- Versi HAVING lebih ringkas (satu query, tanpa nested)
-- karena HAVING memang dirancang buat filter setelah GROUP BY.
-- Versi derived table lebih panjang dan butuh subquery + alias,
-- tapi lebih fleksibel kalau nanti filter-nya makin kompleks
-- (misal butuh filter tambahan yang bukan hasil agregasi,
-- atau mau reuse hasil agregasi itu di beberapa tempat).
-- Untuk kasus sederhana seperti ini, HAVING lebih terbaca.
-- ============================================
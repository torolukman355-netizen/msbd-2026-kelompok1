-- ============================================
-- Q2: Kategori dengan lebih dari 60 film
-- ============================================

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
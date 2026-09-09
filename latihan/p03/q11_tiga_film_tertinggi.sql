-- Diminta: Menampilkan tiga film dengan tarif sewa tertinggi di setiap kategori.
-- Dipilih: CTE (Common Table Expression) karena window function baru dievaluasi setelah klausa WHERE.
-- Alternatif: Subquery di klausa FROM; tidak dipilih karena CTE lebih rapi dan mudah dibaca alur logikanya.

WITH PeringkatFilm AS (
    SELECT
        f.title AS judul,
        c.name AS kategori,
        f.rental_rate AS tarif_sewa,
        DENSE_RANK() OVER (PARTITION BY c.name ORDER BY f.rental_rate DESC) AS peringkat
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
)
SELECT judul, kategori, tarif_sewa
FROM PeringkatFilm
WHERE peringkat <= 3;
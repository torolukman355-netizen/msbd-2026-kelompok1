-- Diminta: Menampilkan nama kategori, jumlah film (> 60 film), dan rata-rata tarif sewa per kategori.
-- Dipilih: Dua CTE berurutan (kategori_besar dan rata_rata_kategori) karena membuat alur logika pemrosesan modular dan mudah dibaca.
-- Alternatif: GROUP BY biasa dengan HAVING dan agregatAVG; tidak dipilih karena soal meminta latihan manipulasi rantai CTE.

WITH kategori_besar AS (
    SELECT 
        c.category_id,
        c.name AS nama_kategori,
        COUNT(fc.film_id) AS jumlah_film
    FROM category c
    JOIN film_category fc ON c.category_id = fc.category_id
    GROUP BY c.category_id, c.name
    HAVING COUNT(fc.film_id) > 60
),
rata_rata_kategori AS (
    SELECT 
        kb.nama_kategori,
        kb.jumlah_film,
        ROUND(AVG(f.rental_rate), 2) AS rerata_tarif
    FROM kategori_besar kb
    JOIN film_category fc ON kb.category_id = fc.category_id
    JOIN film f ON fc.film_id = f.film_id
    GROUP BY kb.nama_kategori, kb.jumlah_film
)
SELECT 
    nama_kategori,
    jumlah_film,
    rerata_tarif
FROM rata_rata_kategori
ORDER BY jumlah_film DESC;
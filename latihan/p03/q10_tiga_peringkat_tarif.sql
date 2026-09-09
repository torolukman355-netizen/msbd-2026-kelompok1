--Diminta : Menampilkan judul, kategori, tarif sewa dan 3 jenis peringkat tarif perkategori
--Dipilih : Window Function dengan satu deklarasi WINDOW di akhir karena memperpendek query dan mencegah repitisi
-- Alternatif: Menulis klausa OVER (PARTITION BY ...) utuh pada tiap kolom; tidak dipilih karena kode menjadi redundan.

WITH PeringkatFilm AS (
   SELECT 
      f.title AS judul,
      c.name AS kategori,
      f.rental_rate AS tarif_sewa,
      DENSE_RANK() OVER (PARTITION BY c.name ORDER BY f.rental_rate DESC) AS peringkat
   FROM film f 
   JOIN film_category fc ON f.film_id = fc.film_id
   JOIN category c ON fc ON category_id = c.category_id
)
SELECT judul, kategori, tarif_sewa
FROM PeringkatFilm
WHERE peringkat <= 3;
-- Diminta: menghasilkan jumlah film dan rata-rata tarif untuk setiap pasangan kategori–rating, subtotal per kategori, dan grand total dalam satu hasil.
-- Dipilih: klausa ROLLUP dan fungsi GROUPING() karena lebih efisien dan ringkas untuk menghasilkan subtotal secara hierarkis.
-- Alternatif: Menggunakan UNION ALL dari beberapa query GROUP BY; tidak dipilih karena membuat query menjadi sangat panjang, redundan, dan lebih lambat dieksekusi.

SELECT
    CASE WHEN GROUPING(c.name) = 1 THEN 'SEMUA' ELSE c.name END AS kategori,
    CASE WHEN GROUPING(f.rating) = 1 THEN 'SEMUA' ELSE f.rating::text END AS rating,
    COUNT(f.film_id) AS jumlah_film,
    AVG(f.rental_rate) AS rata_rata_tarif
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
GROUP BY ROLLUP (c.name, f.rating)
ORDER BY c.name, f.rating;

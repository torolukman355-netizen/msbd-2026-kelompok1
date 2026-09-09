-- Diminta: menampilkan film_id yang ada di inventory tetapi tidak pernah muncul melalui rental, dan arah sebaliknya, dalam satu hasil dengan kolom penanda arah.
-- Dipilih: kombinasi set operation (A EXCEPT B) UNION ALL (B EXCEPT A) karena secara langsung mengidentifikasi perbedaan simetris dua himpunan dengan penanda arah yang jelas.
-- Alternatif: FULL OUTER JOIN dengan pengecekan IS NULL; tidak dipilih karena membutuhkan logika CASE WHEN tambahan untuk memisahkan arah rekonsiliasi dan alur operasinya kurang deklaratif dibanding operasi himpunan (EXCEPT).

(
    SELECT 
        i.film_id,
        'Di Inventory, Tidak Pernah Dirental' AS keterangan
    FROM inventory i
    EXCEPT
    SELECT 
        i.film_id,
        'Di Inventory, Tidak Pernah Dirental' AS keterangan
    FROM inventory i
    JOIN rental r ON i.inventory_id = r.inventory_id
)
UNION ALL
(
    SELECT 
        i.film_id,
        'Dirental, Tidak Ada Di Inventory' AS keterangan
    FROM inventory i
    JOIN rental r ON i.inventory_id = r.inventory_id
    EXCEPT
    SELECT 
        i.film_id,
        'Dirental, Tidak Ada Di Inventory' AS keterangan
    FROM inventory i
)
ORDER BY film_id, keterangan;

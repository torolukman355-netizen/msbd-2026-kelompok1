-- Diminta: melakukan backfill bertahap dari rental_rate lama ke tabel harga_film.
-- Dipilih: potongan 1000 film per batch dengan NOT EXISTS agar data tidak duplikat dan mudah diverifikasi.
-- Alternatif: satu INSERT besar untuk seluruh 1000 film; tidak dipilih karena tugas menekankan backfill bertahap.
DO $$
DECLARE
    awal integer := 1;
    akhir integer;
    batas_akhir integer;
BEGIN
    SELECT COALESCE(MAX(film_id), 0) INTO batas_akhir FROM lab4.film;

    WHILE awal <= batas_akhir LOOP
        akhir := awal + 999;

        INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
        SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
        FROM lab4.film f
        WHERE f.film_id BETWEEN awal AND akhir
          AND NOT EXISTS (
              SELECT 1
              FROM lab4.harga_film h
              WHERE h.film_id = f.film_id
                AND h.wilayah = 'ID'
          );

        awal := akhir + 1;
    END LOOP;
END;
$$;

SELECT count(*) AS film_belum_backfill
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1
    FROM lab4.harga_film h
    WHERE h.film_id = f.film_id
      AND h.wilayah = 'ID'
);

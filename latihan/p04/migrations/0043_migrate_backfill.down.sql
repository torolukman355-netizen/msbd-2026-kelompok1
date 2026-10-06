DELETE FROM lab4.harga_film h
WHERE h.wilayah = 'ID'
  AND h.berlaku = daterange('2026-01-01', NULL)
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film older
      WHERE older.film_id = h.film_id
        AND older.wilayah = h.wilayah
        AND older.harga_film_id <> h.harga_film_id
  );

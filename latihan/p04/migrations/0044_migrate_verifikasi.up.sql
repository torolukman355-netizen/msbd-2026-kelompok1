DO $$
DECLARE
    belum_backfill bigint;
BEGIN
    SELECT count(*) INTO belum_backfill
    FROM lab4.film f
    WHERE NOT EXISTS (
        SELECT 1 FROM lab4.harga_film h
        WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
    );

    IF belum_backfill <> 0 THEN
        RAISE EXCEPTION 'Backfill belum lengkap: % film', belum_backfill;
    END IF;
END;
$$;

SELECT count(*) AS film_belum_backfill
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1 FROM lab4.harga_film h
    WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
);

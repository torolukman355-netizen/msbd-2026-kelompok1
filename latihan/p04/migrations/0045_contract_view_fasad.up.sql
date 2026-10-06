DROP TRIGGER IF EXISTS film_tulis_ganda_harga ON lab4.film;
DROP FUNCTION IF EXISTS lab4.sinkronisasi_harga_film();

ALTER TABLE lab4.film RENAME TO film_data;

CREATE VIEW lab4.film AS
SELECT f.film_id,
       f.title,
       f.description,
       f.release_year,
       f.language_id,
       f.rental_duration,
       h.harga AS rental_rate,
       f.length,
       f.replacement_cost,
       f.rating,
       f.last_update,
       f.special_features,
       f.fulltext
FROM lab4.film_data f
LEFT JOIN LATERAL (
    SELECT h1.harga
    FROM lab4.harga_film h1
    WHERE h1.film_id = f.film_id
      AND h1.wilayah = 'ID'
      AND h1.berlaku @> CURRENT_DATE
    ORDER BY lower(h1.berlaku) DESC
    LIMIT 1
) h ON true;

DROP VIEW IF EXISTS lab4.film_murah;

CREATE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99;

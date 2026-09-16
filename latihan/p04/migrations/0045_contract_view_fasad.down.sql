DROP VIEW IF EXISTS lab4.film_murah;
DROP VIEW IF EXISTS lab4.film;
ALTER TABLE lab4.film_data RENAME TO film;

CREATE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99;

CREATE OR REPLACE FUNCTION lab4.sinkronisasi_harga_film()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE lab4.harga_film
    SET harga = NEW.rental_rate
    WHERE film_id = NEW.film_id
      AND wilayah = 'ID'
      AND upper_inf(berlaku);

    IF NOT FOUND THEN
        INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
        VALUES (NEW.film_id, 'ID', NEW.rental_rate, daterange('2026-01-01', NULL));
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER film_tulis_ganda_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.sinkronisasi_harga_film();

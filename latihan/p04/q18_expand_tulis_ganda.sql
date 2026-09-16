-- Diminta: menyiapkan struktur baru harga_film dan menjaga sinkronisasi harga lama ke bentuk baru.
-- Dipilih: membuat tabel harga_film dengan EXCLUDE dan trigger AFTER UPDATE OF rental_rate
-- agar perubahan pada bentuk lama tetap tercermin ke bentuk baru saat aplikasi lama masih berjalan.
-- Alternatif: mengubah aplikasi langsung ke bentuk baru sebelum memastikan pembaca lama aman; tidak dipilih
-- karena akan memutus kompatibilitas aplikasi lama pada tahap expand.

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    EXCLUDE USING gist (film_id WITH =, wilayah WITH =, berlaku WITH &&)
);

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

DROP TRIGGER IF EXISTS film_tulis_ganda_harga ON lab4.film;

CREATE TRIGGER film_tulis_ganda_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.sinkronisasi_harga_film();

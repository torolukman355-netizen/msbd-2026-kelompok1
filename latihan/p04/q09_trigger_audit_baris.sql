-- Diminta: Membuat tabel audit_harga, fungsi trigger, dan trigger level baris yang mencatat perubahan rental_rate (nilai lama, nilai baru, pengguna, waktu) pada lab4.film.
-- Dipilih: AFTER UPDATE OF rental_rate ON lab4.film FOR EACH ROW dengan kondisi WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate) untuk memastikan hanya perubahan riil yang dicatat.
-- Alternatif: AFTER UPDATE tanpa spesifikasi kolom 'OF rental_rate' dan tanpa kondisi WHEN; tidak dipilih karena akan mencatat baris audit palsu (misal saat UPDATE hanya mengubah kolom title atau meng-update ke nilai yang sama).

CREATE TABLE IF NOT EXISTS lab4.audit_harga (
    audit_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    harga_lama numeric(5,2),
    harga_baru numeric(5,2),
    diubah_oleh text NOT NULL DEFAULT current_user,
    diubah_pada timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION lab4.catat_audit_harga_baris()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO lab4.audit_harga (film_id, harga_lama, harga_baru, diubah_oleh, diubah_pada)
    VALUES (OLD.film_id, OLD.rental_rate, NEW.rental_rate, CURRENT_USER, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS film_audit_harga ON lab4.film;

CREATE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga_baris();
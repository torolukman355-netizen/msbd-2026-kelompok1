-- Diminta: Membuat fungsi dan trigger level pernyataan (FOR EACH STATEMENT) memanfaatkan Transition Tables (OLD TABLE / NEW TABLE) untuk mencatat audit massal dalam 1 operasi INSERT.
-- Dipilih: AFTER UPDATE ON lab4.film REFERENCING OLD TABLE AS lama NEW TABLE AS baru FOR EACH STATEMENT dengan query INSERT INTO ... SELECT bergabung (JOIN).
-- Alternatif: Menggunakan trigger FOR EACH STATEMENT tanpa Transition Tables; tidak dipilih karena tanpa transition table, trigger level statement tidak bisa mengakses baris data mana saja yang mengalami perubahan.

CREATE OR REPLACE FUNCTION lab4.catat_audit_massal()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO lab4.audit_harga (film_id, harga_lama, harga_baru, diubah_oleh, diubah_pada)
    SELECT 
        b.film_id, 
        l.rental_rate AS harga_lama, 
        b.rental_rate AS harga_baru, 
        CURRENT_USER, 
        NOW()
    FROM baru b
    JOIN lama l ON b.film_id = l.film_id
    WHERE l.rental_rate IS DISTINCT FROM b.rental_rate;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Matikan trigger level baris agar tidak bertabrakan saat pengujian
ALTER TABLE lab4.film DISABLE TRIGGER film_audit_harga;

DROP TRIGGER IF EXISTS film_audit_harga_massal ON lab4.film;

CREATE TRIGGER film_audit_harga_massal
AFTER UPDATE ON lab4.film
REFERENCING OLD TABLE AS lama NEW TABLE AS baru
FOR EACH STATEMENT
EXECUTE FUNCTION lab4.catat_audit_massal();

\timing on

-- Uji UPDATE massal dengan Trigger Statement
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;

\timing off
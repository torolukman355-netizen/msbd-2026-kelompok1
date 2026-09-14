-- Diminta: Mengukur overhead performa dari trigger level baris (FOR EACH ROW) saat melakukan UPDATE massal seluruh baris pada tabel lab4.film.
-- Dipilih: Mengaktifkan \timing, mengeksekusi UPDATE dengan trigger aktif, mematikan trigger via ALTER TABLE, lalu mengeksekusi UPDATE lagi untuk membandingkan durasinya.
-- Alternatif: Menghapus (DROP) trigger lalu membuat ulang; tidak dipilih karena DISABLE/ENABLE TRIGGER jauh lebih aman, bersih, dan idiomatik dalam PostgreSQL.

-- Kembalikan trigger ke definisi aman (IS DISTINCT FROM)
CREATE OR REPLACE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga_baris();

\timing on

-- Uji 1: UPDATE Massal dengan Trigger Baris AKTIF
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;

-- Uji 2: UPDATE Massal dengan Trigger Baris NONAKTIF
ALTER TABLE lab4.film DISABLE TRIGGER film_audit_harga;

UPDATE lab4.film SET rental_rate = rental_rate + 0.01;

ALTER TABLE lab4.film ENABLE TRIGGER film_audit_harga;

\timing off

-- CATATAN UNTUK LAPORAN.MD:
-- Salin output waktu eksekusi (Time: XXX.XXX ms) dari kedua query di atas ke dalam tabel Ringkasan Waktu di laporan.md.
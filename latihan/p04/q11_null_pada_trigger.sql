-- Diminta: Mengganti kondisi IS DISTINCT FROM menjadi <> pada trigger, lalu menguji perubahan harga ke NULL dan sebaliknya serta menjelaskan akibatnya dari logika NULL.
-- Dipilih: Mengubah trigger menggunakan kondisi WHEN (OLD.rental_rate <> NEW.rental_rate) dan menguji transaksi UPDATE dari/ke NULL.
-- Alternatif: Tetap menggunakan IS DISTINCT FROM; tidak dipilih karena latihan ini bertujuan membuktikan kelemahan operator komparasi standar (<>) terhadap nilai NULL.

CREATE OR REPLACE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate <> NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga_baris();

TRUNCATE TABLE lab4.audit_harga;

-- Uji 1: Nilai biasa ke NULL
UPDATE lab4.film SET rental_rate = NULL WHERE film_id = 2;

-- Uji 2: NULL ke Nilai biasa
UPDATE lab4.film SET rental_rate = 4.99 WHERE film_id = 2;

-- Uji 3: NULL ke NULL
UPDATE lab4.film SET rental_rate = NULL WHERE film_id = 2;

SELECT audit_id, film_id, harga_lama, harga_baru 
FROM lab4.audit_harga;

/*
AKIBAT DAN ANALISIS LOGIKA NULL:
Dalam SQL, ekspresi yang melibatkan perbandingan dengan NULL (seperti `val <> NULL` atau `NULL <> val`) tidak pernah menghasilkan TRUE atau FALSE, melainkan UNKNOWN (Ternary Logic).
- Klausa WHEN pada trigger membutuhkan ekspresi boolean yang bernilai TRUE agar trigger berjalan.
- Karena `OLD <> NEW` bernilai UNKNOWN saat salah satu atau kedua operand bernilai NULL, maka trigger TIDAK AKAN PERNAH TERPICU saat ada perubahan dari/ke NULL.
- Akibatnya, perubahan data krusial yang melibatkan NULL luput dari catatan audit. Operator `IS DISTINCT FROM` menangani NULL secara khusus sebagai nilai yang dapat dibandingkan (NULL vs 4.99 dianggap DISTINCT/berbeda), sehingga aman untuk audit log.
*/
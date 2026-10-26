-- Persiapan: jalankan SEKALI sebelum Sesi A dan Sesi B dimulai.
UPDATE lab9.rekening
SET saldo = 1000000.00
WHERE rekening_id = 1;


BEGIN ISOLATION LEVEL READ COMMITTED;

-- Pembacaan pertama: hasil yang diharapkan adalah 1000000.00.
SELECT rekening_id, pemilik, saldo
FROM lab9.rekening
WHERE rekening_id = 1;


-- Pembacaan kedua: hasil yang diharapkan adalah 900000.00.
SELECT rekening_id, pemilik, saldo
FROM lab9.rekening
WHERE rekening_id = 1;

COMMIT;

-- Jalankan blok ini setelah pembacaan pertama pada Sesi A.
BEGIN;

UPDATE lab9.rekening
SET saldo = 900000.00
WHERE rekening_id = 1;

COMMIT;

-- Pengamatan:
-- Pada READ COMMITTED, setiap perintah SELECT memakai snapshot baru.
-- Karena Sesi B sudah COMMIT, SELECT kedua di Sesi A berubah dari
-- 1000000.00 menjadi 900000.00. Ini adalah non-repeatable read.

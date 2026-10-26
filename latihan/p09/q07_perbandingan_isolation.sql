-- Persiapan: jalankan SEKALI sebelum kedua sesi dimulai.
UPDATE lab9.rekening
SET saldo = 1000000.00
WHERE rekening_id = 1;

-- sesi A
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- Pembacaan pertama: hasil yang diharapkan adalah 1000000.00.
SELECT rekening_id, pemilik, saldo
FROM lab9.rekening
WHERE rekening_id = 1;

-- Pembacaan kedua: tetap 1000000.00.
SELECT rekening_id, pemilik, saldo
FROM lab9.rekening
WHERE rekening_id = 1;

COMMIT;

-- sesi B
BEGIN;

UPDATE lab9.rekening
SET saldo = 900000.00
WHERE rekening_id = 1;

COMMIT;

-- Pengamatan:
-- READ COMMITTED pada Q6 menampilkan 900000.00 pada SELECT kedua karena
-- snapshot dibuat ulang setiap statement. REPEATABLE READ menahan snapshot
-- transaksi Sesi A, sehingga SELECT kedua tetap menampilkan 1000000.00,
-- meskipun perubahan Sesi B telah di-COMMIT.

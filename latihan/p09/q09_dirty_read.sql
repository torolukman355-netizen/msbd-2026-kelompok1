UPDATE lab9.rekening
SET saldo = 1000000.00
WHERE rekening_id = 1;

BEGIN;

UPDATE lab9.rekening
SET saldo = 777000.00
WHERE rekening_id = 1;

ROLLBACK;

BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- Hasil yang diamati tetap 1000000.00, bukan 777000.00.
SELECT rekening_id, pemilik, saldo
FROM lab9.rekening
WHERE rekening_id = 1;

COMMIT;

-- Pengamatan:
-- PostgreSQL menerima sintaks READ UNCOMMITTED, tetapi memperlakukannya
-- seperti READ COMMITTED. Model MVCC PostgreSQL tidak memperlihatkan tuple
-- yang belum di-COMMIT kepada transaksi lain; karena itu dirty read tidak
-- terjadi. Setelah ROLLBACK Sesi A, nilai yang tersimpan tetap 1000000.00.

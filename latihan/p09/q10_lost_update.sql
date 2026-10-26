UPDATE lab9.rekening
SET saldo = 1000000.00
WHERE rekening_id = 1;

-- sesi A
BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT rekening_id, saldo
FROM lab9.rekening
WHERE rekening_id = 1;

UPDATE lab9.rekening
SET saldo = 900000.00
WHERE rekening_id = 1;

COMMIT;

-- sesi B
BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT rekening_id, saldo
FROM lab9.rekening
WHERE rekening_id = 1;

UPDATE lab9.rekening
SET saldo = 800000.00
WHERE rekening_id = 1;

COMMIT;

SELECT rekening_id, pemilik, saldo
FROM lab9.rekening
WHERE rekening_id = 1;

-- Cara menangani lost update:
-- 1. Gunakan operasi atomik bila hanya menambah/mengurangi nilai:
--    UPDATE lab9.rekening SET saldo = saldo - 100000.00 WHERE rekening_id = 1;
-- 2. Kunci baris sebelum menghitung di aplikasi:
--    SELECT saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- 3. Terapkan optimistic locking, misalnya sertakan nilai awal pada WHERE:
--    UPDATE lab9.rekening
--    SET saldo = 800000.00
--    WHERE rekening_id = 1 AND saldo = 1000000.00;
--    Jika jumlah baris terbarui 0, baca ulang data lalu hitung dan coba lagi.

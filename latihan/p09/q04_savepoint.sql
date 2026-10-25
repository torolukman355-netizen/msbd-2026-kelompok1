-- Sesi 1
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 2;
SAVEPOINT titik_aman;
UPDATE lab9.rekening SET saldo = saldo - 300000 WHERE rekening_id = 2;
ROLLBACK TO SAVEPOINT titik_aman;
COMMIT;
SELECT * FROM lab9.rekening;
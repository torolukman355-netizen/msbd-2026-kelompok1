-- Sesi 1 
ROLLBACK;
SELECT * FROM lab9.rekening;

BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 200000 WHERE rekening_id = 1;
COMMIT;
SELECT * FROM lab9.rekening;
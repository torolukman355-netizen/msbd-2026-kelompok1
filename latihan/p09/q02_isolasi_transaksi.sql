-- Sesi 1 
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1;
SELECT * FROM lab9.rekening;

-- Sesi 2 
SELECT * FROM lab9.rekening;
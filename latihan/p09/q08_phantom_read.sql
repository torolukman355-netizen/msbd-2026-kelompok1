CREATE TABLE IF NOT EXISTS lab9.rekening_eksperimen (
    rekening_id INT PRIMARY KEY,
    pemilik TEXT NOT NULL,
    saldo NUMERIC(12,2) NOT NULL CHECK (saldo >= 0)
);

-- Reset data: jalankan SEKALI sebelum Sesi A dan Sesi B untuk skenario ini.
TRUNCATE TABLE lab9.rekening_eksperimen;
INSERT INTO lab9.rekening_eksperimen (rekening_id, pemilik, saldo) VALUES
    (101, 'Andi', 450000.00),
    (102, 'Bella', 600000.00),
    (103, 'Citra', 800000.00);

BEGIN ISOLATION LEVEL READ COMMITTED;

-- Hasil pertama: 2 baris (Bella dan Citra).
SELECT COUNT(*) AS jumlah_saldo_di_atas_500000
FROM lab9.rekening_eksperimen
WHERE saldo > 500000.00;

-- Hasil kedua: 3 baris; baris Deni adalah phantom.
SELECT COUNT(*) AS jumlah_saldo_di_atas_500000
FROM lab9.rekening_eksperimen
WHERE saldo > 500000.00;

COMMIT;

-- Jalankan setelah SELECT pertama Sesi A.
BEGIN;

INSERT INTO lab9.rekening_eksperimen (rekening_id, pemilik, saldo)
VALUES (104, 'Deni', 700000.00);

COMMIT;

-- Jalankan reset ini hanya setelah COMMIT Sesi A pada skenario 1.
TRUNCATE TABLE lab9.rekening_eksperimen;
INSERT INTO lab9.rekening_eksperimen (rekening_id, pemilik, saldo) VALUES
    (101, 'Andi', 450000.00),
    (102, 'Bella', 600000.00),
    (103, 'Citra', 800000.00);

BEGIN ISOLATION LEVEL REPEATABLE READ;

-- Hasil pertama: 2 baris.
SELECT COUNT(*) AS jumlah_saldo_di_atas_500000
FROM lab9.rekening_eksperimen
WHERE saldo > 500000.00;

SELECT COUNT(*) AS jumlah_saldo_di_atas_500000
FROM lab9.rekening_eksperimen
WHERE saldo > 500000.00;

COMMIT;

BEGIN;

INSERT INTO lab9.rekening_eksperimen (rekening_id, pemilik, saldo)
VALUES (104, 'Deni', 700000.00);

COMMIT;

-- Pengamatan:
-- READ COMMITTED menghasilkan hitungan 2 lalu 3. REPEATABLE READ menghasilkan
-- 2 lalu 2 dalam transaksi yang sama, karena PostgreSQL memakai snapshot yang
-- konsisten untuk transaksi tersebut.

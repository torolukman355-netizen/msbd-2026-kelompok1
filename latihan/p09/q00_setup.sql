-- Latihan P09 -- jalankan sekali sebelum membuka dua sesi percobaan.
-- Aman dijalankan ulang: seluruh data lab9 dikembalikan ke kondisi awal.

CREATE SCHEMA IF NOT EXISTS lab9;

CREATE TABLE IF NOT EXISTS lab9.rekening (
    rekening_id INTEGER PRIMARY KEY,
    pemilik TEXT NOT NULL,
    saldo NUMERIC(12,2) NOT NULL CHECK (saldo >= 0),
    version_no INTEGER NOT NULL DEFAULT 0
);

-- Kompatibel dengan setup versi awal yang belum memiliki kolom version_no.
ALTER TABLE lab9.rekening
    ADD COLUMN IF NOT EXISTS version_no INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS lab9.rekening_eksperimen (
    rekening_id INTEGER PRIMARY KEY,
    pemilik TEXT NOT NULL,
    saldo NUMERIC(12,2) NOT NULL CHECK (saldo >= 0)
);

CREATE TABLE IF NOT EXISTS lab9.antrean_pekerjaan (
    id INTEGER PRIMARY KEY,
    status TEXT NOT NULL CHECK (status IN ('siap', 'diproses', 'selesai'))
);

CREATE TABLE IF NOT EXISTS lab9.dokter_jaga (
    dokter_id INTEGER PRIMARY KEY,
    nama TEXT NOT NULL,
    aktif BOOLEAN NOT NULL
);

TRUNCATE TABLE
    lab9.rekening,
    lab9.rekening_eksperimen,
    lab9.antrean_pekerjaan,
    lab9.dokter_jaga;

INSERT INTO lab9.rekening (rekening_id, pemilik, saldo, version_no) VALUES
    (1, 'Ani', 1000000.00, 0),
    (2, 'Budi', 1000000.00, 0);

INSERT INTO lab9.rekening_eksperimen (rekening_id, pemilik, saldo) VALUES
    (101, 'Andi', 450000.00),
    (102, 'Bella', 600000.00),
    (103, 'Citra', 800000.00);

INSERT INTO lab9.antrean_pekerjaan (id, status) VALUES
    (1, 'siap'),
    (2, 'siap'),
    (3, 'selesai');

INSERT INTO lab9.dokter_jaga (dokter_id, nama, aktif) VALUES
    (1, 'dr. Andi', TRUE),
    (2, 'dr. Bunga', TRUE);

\echo '=== Kondisi awal lab9 ==='
SELECT rekening_id, pemilik, saldo, version_no
FROM lab9.rekening
ORDER BY rekening_id;
SELECT COUNT(*) AS jumlah_rekening, SUM(saldo) AS total_saldo
FROM lab9.rekening;

\echo '=== Kondisi uji (salin keluaran ke laporan.md) ==='
SELECT version();
SHOW transaction_isolation;
SHOW deadlock_timeout;
SHOW lock_timeout;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;

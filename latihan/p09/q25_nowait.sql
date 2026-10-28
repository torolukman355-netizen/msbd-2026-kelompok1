/*
 * Q25: NOWAIT pada row lock.
 *
 * Jalankan bagian persiapan sekali saja. Setelah itu jalankan Sesi A dan
 * Sesi B pada koneksi terpisah; Sesi A harus tetap belum COMMIT saat Sesi B
 * menjalankan SELECT.
 */

CREATE SCHEMA IF NOT EXISTS lab9;

CREATE TABLE IF NOT EXISTS lab9.antrean_pekerjaan (
    id INTEGER PRIMARY KEY,
    status TEXT NOT NULL CHECK (status IN ('siap', 'diproses', 'selesai'))
);

-- Persiapan: jalankan ketika tidak ada transaksi yang memakai tabel ini.
TRUNCATE TABLE lab9.antrean_pekerjaan;
INSERT INTO lab9.antrean_pekerjaan (id, status) VALUES
    (1, 'siap'),
    (2, 'siap');

-- =======================
-- SESI A
-- =======================
BEGIN;

SELECT id, status
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE;
-- Sesi A kini memegang lock pada id = 1 dan belum COMMIT.


-- =======================
-- SESI B (jalankan saat Sesi A masih terbuka)
-- =======================
BEGIN;

SELECT id, status
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE NOWAIT;
-- Hasil yang diharapkan, tanpa menunggu:
-- ERROR:  could not obtain lock on row in relation "antrean_pekerjaan"
-- SQLSTATE: 55P03 (lock_not_available)
-- Setelah error, transaksi Sesi B berstatus aborted sehingga harus di-ROLLBACK.

ROLLBACK;


-- =======================
-- KEMBALI KE SESI A
-- =======================
COMMIT;

-- NOWAIT berguna bila aplikasi lebih memilih gagal cepat dan memutuskan sendiri
-- untuk retry, menampilkan konflik, atau memilih pekerjaan lain. Berbeda dengan
-- SKIP LOCKED, NOWAIT tidak mencari baris alternatif.

/*
 * Q27: Mencegah write skew dengan SERIALIZABLE.
 *
 * Jalankan bagian persiapan sekali. Kedua SELECT harus selesai sebelum salah
 * satu sesi menjalankan UPDATE atau COMMIT, agar terbentuk pola konflik yang
 * sama seperti Q26.
 */

CREATE SCHEMA IF NOT EXISTS lab9;

CREATE TABLE IF NOT EXISTS lab9.dokter_jaga (
    dokter_id INTEGER PRIMARY KEY,
    nama TEXT NOT NULL,
    aktif BOOLEAN NOT NULL
);

-- Persiapan: jalankan ketika tidak ada transaksi eksperimen yang aktif.
TRUNCATE TABLE lab9.dokter_jaga;
INSERT INTO lab9.dokter_jaga (dokter_id, nama, aktif) VALUES
    (1, 'dr. Andi', TRUE),
    (2, 'dr. Bunga', TRUE);

-- =======================
-- SESI A
-- =======================
BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif;
-- Hasil: 2.


-- =======================
-- SESI B (jalankan sebelum Sesi A UPDATE/COMMIT)
-- =======================
BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif;
-- Hasil: 2.


-- =======================
-- KEMBALI KE SESI A
-- =======================
UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 1;

COMMIT;


-- =======================
-- KEMBALI KE SESI B
-- =======================
UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 2;

COMMIT;
-- Salah satu transaksi (umumnya Sesi B pada urutan ini) dibatalkan dengan
-- SQLSTATE 40001: could not serialize access due to read/write dependencies
-- among transactions. Bergantung urutan dan rencana query, error dapat muncul
-- saat UPDATE atau saat COMMIT. Jika error muncul sebelum COMMIT, jalankan
-- ROLLBACK pada sesi yang gagal.


-- Setelah satu transaksi dibatalkan, aturan bisnis tetap terjaga.
SELECT dokter_id, nama, aktif
FROM lab9.dokter_jaga
ORDER BY dokter_id;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif;
-- Hasil yang diharapkan: dokter_aktif = 1. Transaksi yang mendapat 40001
-- harus diulang dari BEGIN oleh aplikasi, bukan hanya mengulangi UPDATE-nya.

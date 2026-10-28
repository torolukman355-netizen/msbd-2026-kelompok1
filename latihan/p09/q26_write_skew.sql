/*
 * Q26: Write skew pada REPEATABLE READ.
 *
 * Aturan bisnis: setidaknya satu dokter harus tetap aktif.
 * Aturan ini sengaja diperiksa oleh aplikasi (bukan CHECK per-baris), karena
 * eksperimen ini menunjukkan bahwa dua transaksi dapat bersama-sama melanggarnya.
 * Jalankan SELECT hitung di kedua sesi sebelum UPDATE/COMMIT di sesi mana pun.
 */

CREATE SCHEMA IF NOT EXISTS lab9;

CREATE TABLE IF NOT EXISTS lab9.dokter_jaga (
    dokter_id INTEGER PRIMARY KEY,
    nama TEXT NOT NULL,
    aktif BOOLEAN NOT NULL
);

-- Persiapan: jalankan sekali ketika tidak ada transaksi eksperimen yang aktif.
TRUNCATE TABLE lab9.dokter_jaga;
INSERT INTO lab9.dokter_jaga (dokter_id, nama, aktif) VALUES
    (1, 'dr. Andi', TRUE),
    (2, 'dr. Bunga', TRUE);

-- =======================
-- SESI A
-- =======================
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif;
-- Hasil: 2. Aplikasi menganggap dokter 1 aman untuk dinonaktifkan.


-- =======================
-- SESI B (jalankan sebelum Sesi A UPDATE/COMMIT)
-- =======================
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif;
-- Hasil: 2. Snapshot Sesi B juga menganggap dokter 2 aman dinonaktifkan.


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
-- Kedua COMMIT berhasil karena masing-masing transaksi mengubah baris berbeda.


-- Jalankan setelah kedua COMMIT, dari salah satu sesi.
SELECT dokter_id, nama, aktif
FROM lab9.dokter_jaga
ORDER BY dokter_id;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif;
-- Hasil akhir: dokter_aktif = 0. Ini adalah write skew: snapshot konsisten
-- mencegah konflik tulis pada baris yang sama, tetapi tidak menjaga aturan
-- lintas-baris yang dibaca dan kemudian diubah oleh transaksi berbeda.

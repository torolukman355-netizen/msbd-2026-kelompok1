/*
 * Q24: SKIP LOCKED pada antrean pekerjaan.
 *
 * Jalankan bagian persiapan sekali saja, lalu ikuti blok Sesi A dan Sesi B
 * pada dua koneksi psql/DBeaver yang berbeda. Jangan COMMIT Sesi A sebelum
 * SELECT di Sesi B selesai.
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
    (2, 'siap'),
    (3, 'selesai');

-- =======================
-- SESI A
-- =======================
BEGIN;

-- Sesi A mengunci pekerjaan pertama dan sengaja menahan transaksinya.
SELECT id, status
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE;
-- Hasil: id = 1, status = siap.


-- =======================
-- SESI B (jalankan saat Sesi A masih terbuka)
-- =======================
BEGIN;

SELECT id, status
FROM lab9.antrean_pekerjaan
WHERE status = 'siap'
ORDER BY id
LIMIT 1
FOR UPDATE SKIP LOCKED;
-- Hasil: id = 2, status = siap.
-- id = 1 dilewati karena sedang dikunci Sesi A; Sesi B tidak menunggu.

-- Dalam worker sungguhan, tandai pekerjaan yang berhasil diklaim sebelum COMMIT.
UPDATE lab9.antrean_pekerjaan
SET status = 'diproses'
WHERE id = 2;

COMMIT;


-- =======================
-- KEMBALI KE SESI A
-- =======================
COMMIT;

-- SKIP LOCKED cocok untuk banyak worker yang mengambil pekerjaan paralel:
-- setiap worker melewati pekerjaan yang sudah diklaim worker lain, sehingga
-- tidak membentuk antrean tunggu. Konsekuensinya, pekerjaan yang terus-menerus
-- terkunci dapat tertunda; aplikasi perlu mekanisme pemulihan/retry pekerjaan.

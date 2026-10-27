/* 
 * Q19: Simulasi Row Lock & Blocking
 * Skenario pengujian eksekusi query secara bergantian antara Sesi A dan Sesi B.
 */

-- =======================
-- EKSEKUSI SESI A
-- =======================
BEGIN;

-- Sesi A mengunci baris rekening 1 secara eksklusif
SELECT * FROM lab9.rekening 
WHERE rekening_id = 1 
FOR UPDATE;


-- =======================
-- EKSEKUSI SESI B
-- =======================
BEGIN;

-- Sesi B mencoba mengunci baris yang sama (rekening 1).
-- HASIL PENGAMATAN: Saat dieksekusi, query pada Sesi B berstatus 'executing' (menunggu) 
-- dan tidak langsung mengembalikan hasil. Hal ini terjadi karena Sesi B terhalang (blocked) 
-- dan masuk ke dalam antrean tunggu akibat lock eksklusif yang masih dipegang oleh Sesi A.
SELECT * FROM lab9.rekening 
WHERE rekening_id = 1 
FOR UPDATE;


-- =======================
-- KEMBALI KE SESI A
-- =======================
-- Sesi A menyelesaikan transaksi untuk melepaskan lock
COMMIT;


-- =======================
-- PENGAMATAN PADA SESI B
-- =======================
-- HASIL PENGAMATAN: Segera setelah Sesi A menjalankan COMMIT, antrean lock terlepas. 
-- Query pada Sesi B yang sebelumnya tertahan langsung selesai dieksekusi dan menampilkan 
-- data rekening 1. Lock eksklusif sekarang berhasil didapatkan oleh Sesi B.

-- Sesi B menyelesaikan transaksi agar lock terlepas sepenuhnya
COMMIT;
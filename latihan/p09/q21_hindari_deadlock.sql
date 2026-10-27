/* 
 * Q21: Menghindari Deadlock dengan Urutan Penguncian Konsisten
 * Skenario pengujian eksekusi query di mana semua sesi mengunci baris 
 * berdasarkan urutan rekening_id dari nilai terkecil ke terbesar.
 */

-- =======================
-- LANGKAH 1: EKSEKUSI SESI A
-- =======================
BEGIN;

-- Sesi A berhasil mengunci baris rekening 1
SELECT * FROM lab9.rekening 
WHERE rekening_id = 1 FOR UPDATE;


-- =======================
-- LANGKAH 2: EKSEKUSI SESI B
-- =======================
BEGIN;

-- Sesi B mencoba mengunci baris rekening 1.
-- HASIL PENGAMATAN: Query pada Sesi B berstatus 'executing' (menunggu).
-- Sesi B masuk ke antrean tunggu karena lock eksklusif masih dipegang Sesi A.
SELECT * FROM lab9.rekening 
WHERE rekening_id = 1 FOR UPDATE;


-- =======================
-- LANGKAH 3: KEMBALI KE SESI A
-- =======================
-- Sesi A lanjut mengunci baris rekening 2.
-- HASIL PENGAMATAN: Query langsung berhasil dieksekusi. Tidak terjadi deadlock 
-- karena Sesi B belum memegang lock pada rekening 2 (Sesi B masih tertahan di rekening 1).
SELECT * FROM lab9.rekening 
WHERE rekening_id = 2 FOR UPDATE;

-- Sesi A menyelesaikan transaksi, melepaskan lock untuk rekening 1 dan 2.
COMMIT;


-- =======================
-- LANGKAH 4: PENGAMATAN PADA SESI B
-- =======================
-- HASIL PENGAMATAN: Segera setelah Sesi A menjalankan COMMIT, antrean lock terlepas.
-- Query Sesi B (dari Langkah 2) langsung selesai dieksekusi dan berhasil mengunci rekening 1.

-- Sesi B sekarang lanjut mengunci baris rekening 2.
-- HASIL PENGAMATAN: Berhasil dieksekusi tanpa hambatan karena Sesi A sudah melepaskan lock.
SELECT * FROM lab9.rekening 
WHERE rekening_id = 2 FOR UPDATE;

-- KESIMPULAN: Deadlock (SQLSTATE 40P01) dapat dihindari jika semua transaksi 
-- meminta lock dengan urutan yang konsisten (misalnya, selalu dari ID terkecil ke terbesar).
-- Hal ini mencegah terjadinya circular wait (saling tunggu yang melingkar).

-- Sesi B menyelesaikan transaksi
COMMIT;
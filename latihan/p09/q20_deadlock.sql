/* 
 * Q20: Simulasi Deadlock (Saling Tunggu)
 * Skenario pengujian eksekusi query secara bergantian antara Sesi A dan Sesi B 
 * untuk memicu kondisi kebuntuan (circular wait).
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

-- Sesi B berhasil mengunci baris rekening 2
SELECT * FROM lab9.rekening 
WHERE rekening_id = 2 FOR UPDATE;


-- =======================
-- LANGKAH 3: KEMBALI KE SESI A
-- =======================
-- Sesi A mencoba mengunci baris rekening 2 yang saat ini sedang dipegang oleh Sesi B.
-- HASIL PENGAMATAN: Query pada Sesi A berstatus 'executing' (menunggu).
-- Sesi A kini masuk ke antrean lock, menunggu Sesi B melepaskan baris rekening 2.
SELECT * FROM lab9.rekening 
WHERE rekening_id = 2 FOR UPDATE;


-- =======================
-- LANGKAH 4: KEMBALI KE SESI B
-- =======================
-- Sesi B mencoba mengunci baris rekening 1 yang saat ini sedang dipegang oleh Sesi A.
-- HASIL PENGAMATAN: Terjadi kondisi saling tunggu secara melingkar (circular wait). 
-- Sesi A menunggu Sesi B, dan Sesi B menunggu Sesi A. 
-- Dalam waktu sekitar 1 detik (sesuai konfigurasi deadlock_timeout), PostgreSQL 
-- secara otomatis mengintervensi, mendeteksi kebuntuan, dan membatalkan transaksi Sesi B.
-- Pesan Error yang muncul di Sesi B: ERROR: deadlock detected (SQLSTATE 40P01).
SELECT * FROM lab9.rekening 
WHERE rekening_id = 1 FOR UPDATE;


-- =======================
-- LANGKAH 5: PENGAMATAN AKHIR & PEMBERSIHAN
-- =======================
-- HASIL PENGAMATAN LANJUTAN: Karena transaksi Sesi B dibatalkan paksa oleh sistem 
-- akibat deadlock, lock pada rekening 2 yang dipegang Sesi B ikut terlepas. 
-- Akibatnya, query Sesi A (dari Langkah 3) yang tadinya tertahan, kini langsung selesai 
-- dieksekusi dan Sesi A berhasil mendapatkan lock kedua baris tersebut.

-- Bersihkan tabel dari lock agar tidak mengganggu eksperimen selanjutnya
-- Eksekusi di Sesi A:
ROLLBACK;

-- Eksekusi di Sesi B (untuk mereset status transaksi yang aborted):
ROLLBACK;
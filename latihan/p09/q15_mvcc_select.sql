/*
Q15: Mengamati perilaku SELECT biasa dengan MVCC.

Tujuan:
Menjelaskan bagaimana pembaca dapat melihat snapshot tanpa selalu
menunggu transaksi penulis.
 */
-- ==========================================
-- SESI 1: Koneksi pertama
-- ==========================================
BEGIN;

UPDATE lab9.rekening
SET
    saldo = saldo - 10000
WHERE
    rekening_id = 1
    AND saldo >= 10000;

-- Jangan COMMIT dahulu.
-- Perubahan belum di-commit.
-- ==========================================
-- SESI 2: Koneksi kedua
-- ==========================================
-- Jalankan ketika transaksi sesi 1 masih terbuka.
-- SELECT rekening_id, saldo
-- FROM lab9.rekening
-- WHERE rekening_id = 1;
-- SELECT biasa umumnya tidak menunggu.
-- Sesi 2 melihat versi terakhir yang sudah di-commit,
-- bukan perubahan yang belum di-commit pada sesi 1.
-- ==========================================
-- KEMBALI KE SESI 1
-- ==========================================
-- COMMIT;
-- Setelah sesi 1 COMMIT, jalankan SELECT kembali di sesi 2.
-- Pada READ COMMITTED, SELECT baru memperoleh snapshot baru
-- dan dapat melihat saldo yang sudah diperbarui.
/*
Penjelasan:
MVCC (Multi-Version Concurrency Control) memungkinkan PostgreSQL
mempertahankan beberapa versi baris sehingga pembaca dapat melihat
data sesuai snapshot transaksinya.

SELECT biasa tidak selalu menunggu penulis karena pembaca dapat
membaca versi data yang sudah di-commit tanpa mengambil kunci
pembaruan.

Pada READ COMMITTED, setiap pernyataan memperoleh snapshot baru.
Pada REPEATABLE READ, transaksi mempertahankan snapshot yang sama
selama transaksi berlangsung.
 */
-- ============================================================
-- Q14: COVERING INDEX + VACUUM
-- ============================================================
-- Tujuan:
--   Melihat bagaimana VACUUM menurunkan Heap Fetches pada
--   Index Only Scan, walaupun definisi index tidak berubah.
--
-- Apa itu Covering Index?
--   Index yang MENYIMPAN SEMUA KOLOM yang dibutuhkan query,
--   sehingga PostgreSQL tidak perlu baca tabel heap sama sekali.
--   Ini disebut INDEX ONLY SCAN.
--
--   Query butuh: customer_id, terjadi_pada, jumlah.
--   Index ev_cover_idx punya key customer_id +
--   INCLUDE (terjadi_pada, jumlah). Ketiga kolom ada di index.
--
-- Apa itu Heap Fetches?
--   Meskipun namanya "Index Only Scan", PostgreSQL tetap harus
--   cek heap SEKALI untuk memastikan baris masih visible
--   (belum dihapus/diupdate). Proses cek ini = Heap Fetch.
--
-- Peran VACUUM:
--   - Setelah UPDATE/DELETE, baris lama masih ada di heap.
--   - VACUUM membersihkan baris mati dan MENGUPDATE Visibility Map
--     -> menandai halaman yang semua barisnya "all-visible".
--   - Kalau halaman sudah "all-visible", PostgreSQL TIDAK PERLU
--     Heap Fetch -> Heap Fetches turun ke 0.
--
-- Hasil yang diharapkan:
--   | Skenario       | Heap Fetches        |
--   |----------------|---------------------|
--   | Sebelum VACUUM | Tinggi (misal 17)   |
--   | Sesudah VACUUM | 0 atau sangat rendah|
--
-- Untuk laporan:
--   Catat Heap Fetches sebelum & sesudah, jelaskan kenapa beda.
-- ============================================================

DROP INDEX IF EXISTS lab6.ev_cover_idx;

-- Covering index: key customer_id, INCLUDE (terjadi_pada, jumlah)
CREATE INDEX ev_cover_idx 
ON lab6.event_log (customer_id) 
INCLUDE (terjadi_pada, jumlah);

-- ===== SEBELUM VACUUM =====
-- Perhatikan angka "Heap Fetches" di output
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, terjadi_pada, jumlah
FROM lab6.event_log
WHERE customer_id = 4211;

-- Jalankan VACUUM untuk update Visibility Map
VACUUM (ANALYZE) lab6.event_log;

-- ===== SESUDAH VACUUM =====
-- Bandingkan angka "Heap Fetches" dengan sebelum VACUUM
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, terjadi_pada, jumlah
FROM lab6.event_log
WHERE customer_id = 4211;
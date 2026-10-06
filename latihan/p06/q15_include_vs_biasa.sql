-- ============================================================
-- Q15: INCLUDE vs INDEX TIGA KOLOM BIASA
-- ============================================================
-- Tujuan:
--   Membandingkan ukuran dan rencana eksekusi antara:
--   1. Index dengan INCLUDE
--   2. Index tiga kolom biasa (semua jadi key)
--
-- Perbedaan INCLUDE vs index biasa:
--   | Aspek                    | INCLUDE        | 3 Kolom Biasa |
--   |--------------------------|----------------|---------------|
--   | Kolom jadi key           | Hanya cust_id  | Ketiganya     |
--   | Kolom INCLUDE            | Di daun saja   | Jadi key      |
--   | Bisa untuk filter/order? | Tidak          | Ya            |
--   | Ukuran                   | Lebih kecil    | Lebih besar   |
--   | Index Only Scan?         | Ya             | Ya            |
--
-- Kenapa INCLUDE lebih kecil?
--   - Kolom INCLUDE tidak ikut dalam proses pengurutan B-Tree
--     -> struktur lebih sederhana.
--   - Kolom INCLUDE tidak disimpan di level internal
--     (hanya di daun) -> lebih hemat.
--
-- Kenapa pakai INCLUDE?
--   Ketika kamu hanya butuh kolom tambahan untuk MEMBACA
--   (bukan filter/order). Kalau butuh filter/order di kolom
--   tambahan, pakai index biasa.
--
-- Hasil yang diharapkan:
--   - Keduanya bisa Index Only Scan
--   - ev_cover_idx LEBIH KECIL dari ev_tiga_kolom_idx
-- ============================================================

DROP INDEX IF EXISTS lab6.ev_cover_idx;
DROP INDEX IF EXISTS lab6.ev_tiga_kolom_idx;

-- Index dengan INCLUDE
CREATE INDEX ev_cover_idx 
ON lab6.event_log (customer_id) 
INCLUDE (terjadi_pada, jumlah);

-- Index tiga kolom biasa (semua jadi key)
CREATE INDEX ev_tiga_kolom_idx 
ON lab6.event_log (customer_id, terjadi_pada, jumlah);

-- Bandingkan ukuran
SELECT
  indexrelname AS nama_index,
  pg_size_pretty(pg_relation_size(indexrelid)) AS ukuran,
  pg_relation_size(indexrelid) AS ukuran_bytes
FROM pg_stat_user_indexes
WHERE indexrelname IN ('ev_cover_idx', 'ev_tiga_kolom_idx')
ORDER BY indexrelname;

-- Bandingkan rencana eksekusi
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, terjadi_pada, jumlah
FROM lab6.event_log
WHERE customer_id = 4211;
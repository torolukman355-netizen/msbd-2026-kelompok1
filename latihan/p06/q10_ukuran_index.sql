-- ============================================================
-- Q10: UKURAN INDEX (Salah vs Benar)
-- ============================================================
-- Tujuan:
--   Membuktikan bahwa urutan kolom memengaruhi UKURAN FISIK index,
--   meskipun jumlah kolomnya sama (dua kolom).
--
-- Kenapa bisa berbeda padahal isinya sama-sama 2 kolom?
--   B-Tree menyimpan entry berisi:
--     1. Key (kolom yang di-index)
--     2. TID (pointer ke baris heap, 6 byte)
--
--   Pada ev_salah_idx (terjadi_pada, customer_id):
--     - Key pertama = terjadi_pada (timestamp, 8 byte)
--     - Timestamp hampir selalu unik -> kompresi prefix kurang efektif
--     - Entry lebih besar
--
--   Pada ev_benar_idx (customer_id, terjadi_pada DESC):
--     - Key pertama = customer_id (integer, 4 byte)
--     - customer_id sering berulang -> kompresi prefix lebih efektif
--     - Entry lebih kecil
--
--   Hasil: ev_benar_idx biasanya LEBIH KECIL dari ev_salah_idx.
--
-- Untuk laporan:
--   - Catat kedua ukuran
--   - Hitung selisih / persentase
--   - Jelaskan alasan kompresi prefix di atas
-- ============================================================

-- Pastikan kedua index ada (buat ulang kalau Q9 sudah drop)
DROP INDEX IF EXISTS lab6.ev_salah_idx;
DROP INDEX IF EXISTS lab6.ev_benar_idx;

CREATE INDEX ev_salah_idx ON lab6.event_log (terjadi_pada, customer_id);
CREATE INDEX ev_benar_idx ON lab6.event_log (customer_id, terjadi_pada DESC);

-- Ukur ukuran kedua index
--   pg_relation_size(indexrelid) -> ukuran byte
--   pg_size_pretty()             -> format enak dibaca (MB/KB)
SELECT
  indexrelname AS nama_index,
  pg_size_pretty(pg_relation_size(indexrelid)) AS ukuran,
  pg_relation_size(indexrelid) AS ukuran_bytes
FROM pg_stat_user_indexes
WHERE indexrelname IN ('ev_salah_idx', 'ev_benar_idx')
ORDER BY indexrelname;
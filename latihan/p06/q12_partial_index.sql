-- ============================================================
-- Q12: PARTIAL INDEX (Index Sebagian)
-- ============================================================
-- Tujuan:
--   Membandingkan ukuran index penuh vs partial index
--   (index yang hanya mencakup sebagian baris).
--
-- Apa itu Partial Index?
--   Index yang hanya meng-index baris yang memenuhi kondisi WHERE
--   di definisi index. Di sini hanya baris status='GAGAL'.
--
-- Kapan dipakai?
--   Ketika query SELALU memfilter dengan kondisi yang sama, misal:
--     SELECT * FROM event_log WHERE status='GAGAL' AND ...
--   Query ini bisa pakai ev_gagal_idx (kecil, cepat),
--   sementara ev_full_idx (besar, lambat) tidak perlu.
--
-- Kenapa lebih kecil?
--   Dari 2 juta baris, mungkin hanya 5-10% yang status='GAGAL'.
--   Jadi index-nya cuma menyimpan 5-10% baris -> jauh lebih kecil.
--
-- Untuk laporan:
--   - Catat ukuran ev_gagal_idx dan ev_full_idx
--   - Hitung penghematan: (full - gagal) / full * 100%
--   - Contoh: full=60MB, gagal=4MB -> hemat 93%
--
-- Catatan:
--   Partial index HANYA berguna kalau query PERSIS memakai
--   kondisi WHERE status='GAGAL'. Kalau query tidak menyebut
--   status, index ini tidak akan dipakai.
-- ============================================================

DROP INDEX IF EXISTS lab6.ev_gagal_idx;
DROP INDEX IF EXISTS lab6.ev_full_idx;

-- Partial index: hanya index baris dengan status='GAGAL'
CREATE INDEX ev_gagal_idx 
ON lab6.event_log (terjadi_pada DESC) 
WHERE status='GAGAL';

-- Index penuh: index semua baris
CREATE INDEX ev_full_idx 
ON lab6.event_log (terjadi_pada DESC);

-- Bandingkan ukuran
SELECT
  indexrelname AS nama_index,
  pg_size_pretty(pg_relation_size(indexrelid)) AS ukuran,
  pg_relation_size(indexrelid) AS ukuran_bytes
FROM pg_stat_user_indexes
WHERE indexrelname IN ('ev_gagal_idx', 'ev_full_idx')
ORDER BY indexrelname;
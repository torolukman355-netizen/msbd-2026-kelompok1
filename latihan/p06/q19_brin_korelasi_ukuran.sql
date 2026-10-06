-- ============================================================
-- Q19: KORELASI KOLOM WAKTU DAN UKURAN INDEX
-- ============================================================
-- Nilai korelasi mendekati +1 atau -1 berarti urutan fisik heap
-- selaras dengan urutan nilai kolom; BRIN biasanya paling efektif
-- ketika korelasi absolut tinggi.

ANALYZE lab6.event_log;

SELECT schemaname, tablename, attname, correlation
FROM pg_stats
WHERE schemaname = 'lab6'
  AND tablename = 'event_log'
  AND attname = 'terjadi_pada';

-- Bandingkan BRIN 128 halaman per range dengan B-Tree pada kolom sama.
DROP INDEX IF EXISTS lab6.ev_terjadi_pada_brin_idx;
DROP INDEX IF EXISTS lab6.ev_terjadi_pada_btree_idx;

CREATE INDEX ev_terjadi_pada_brin_idx
  ON lab6.event_log USING brin (terjadi_pada)
  WITH (pages_per_range = 128);

CREATE INDEX ev_terjadi_pada_btree_idx
  ON lab6.event_log (terjadi_pada);

SELECT c.relname AS nama_index,
       pg_size_pretty(pg_relation_size(c.oid)) AS ukuran,
       pg_relation_size(c.oid) AS ukuran_bytes
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'lab6'
  AND c.relname IN ('ev_terjadi_pada_brin_idx', 'ev_terjadi_pada_btree_idx')
ORDER BY c.relname;

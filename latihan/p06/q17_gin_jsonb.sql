-- ============================================================
-- Q17: GIN UNTUK JSONB
-- ============================================================
-- Uji containment JSONB dengan operator @>. Operator class
-- jsonb_path_ops mendukung pola containment seperti query ini.

DROP INDEX IF EXISTS lab6.ev_payload_gin_idx;
CREATE INDEX ev_payload_gin_idx
  ON lab6.event_log USING gin (payload jsonb_path_ops);

ANALYZE lab6.event_log;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id
FROM lab6.event_log
WHERE payload @> '{"promo": true}'::jsonb;

-- Bandingkan ukuran index GIN dengan heap tabel (belum termasuk index lain).
WITH ukuran AS (
  SELECT pg_relation_size('lab6.event_log') AS heap_bytes,
         pg_relation_size('lab6.ev_payload_gin_idx') AS gin_bytes
)
SELECT pg_size_pretty(heap_bytes) AS ukuran_heap,
       pg_size_pretty(gin_bytes) AS ukuran_gin,
       round(gin_bytes * 100.0 / NULLIF(heap_bytes, 0), 2) AS gin_persen_dari_heap,
       round(heap_bytes * 1.0 / NULLIF(gin_bytes, 0), 2) AS heap_kali_ukuran_gin
FROM ukuran;

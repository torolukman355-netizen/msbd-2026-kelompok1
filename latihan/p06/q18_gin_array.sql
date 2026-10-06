-- ============================================================
-- Q18: GIN UNTUK ARRAY tags
-- ============================================================
-- Predicate @> berarti array tags mengandung semua elemen di sisi kanan.
-- Nilai berikut memang ada di data q00_setup.sql.

-- Baseline: jalankan rencana saat index GIN belum ada.
DROP INDEX IF EXISTS lab6.ev_tags_gin_idx;
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id
FROM lab6.event_log
WHERE tags @> ARRAY['kanal:1', 'sumber:1']::text[];

-- Bandingkan dengan rencana setelah GIN tersedia.
CREATE INDEX ev_tags_gin_idx
  ON lab6.event_log USING gin (tags);

ANALYZE lab6.event_log;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id
FROM lab6.event_log
WHERE tags @> ARRAY['kanal:1', 'sumber:1']::text[];
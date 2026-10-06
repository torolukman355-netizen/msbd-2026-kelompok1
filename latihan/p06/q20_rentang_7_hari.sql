-- ============================================================
-- Q20: RENTANG TUJUH HARI DENGAN BRIN DAN B-TREE
-- ============================================================
-- Jalankan kedua EXPLAIN dengan kondisi dan kolom keluaran yang sama.
-- Index yang tidak sedang diuji dihapus agar plan tidak memilihnya.
-- Setelah pengukuran, kedua index dibiarkan tersedia kembali.


DROP INDEX IF EXISTS lab6.ev_terjadi_pada_btree_idx;
CREATE INDEX IF NOT EXISTS ev_terjadi_pada_brin_idx
  ON lab6.event_log USING brin (terjadi_pada)
  WITH (pages_per_range = 128);


EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00:00+07';

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00:00+07';


DROP INDEX IF EXISTS lab6.ev_terjadi_pada_brin_idx;
CREATE INDEX ev_terjadi_pada_btree_idx
  ON lab6.event_log (terjadi_pada);


EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00:00+07';

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00:00+07';

CREATE INDEX ev_terjadi_pada_brin_idx
  ON lab6.event_log USING brin (terjadi_pada)
  WITH (pages_per_range = 128);

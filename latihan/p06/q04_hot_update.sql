\timing on

DROP TABLE IF EXISTS lab6.hot_penuh CASCADE;
DROP TABLE IF EXISTS lab6.hot_longgar CASCADE;

CREATE TABLE lab6.hot_penuh (
  id int PRIMARY KEY,
  catatan text,
  val int
) WITH (fillfactor = 100);

CREATE TABLE lab6.hot_longgar (
  id int PRIMARY KEY,
  catatan text,
  val int
) WITH (fillfactor = 80);

CREATE INDEX idx_penuh_val ON lab6.hot_penuh(val);
CREATE INDEX idx_longgar_val ON lab6.hot_longgar(val);

INSERT INTO lab6.hot_penuh SELECT g, 'catatan awal ' || g, g FROM generate_series(1, 10000) g;
INSERT INTO lab6.hot_longgar SELECT g, 'catatan awal ' || g, g FROM generate_series(1, 10000) g;

-- Update kolom 'catatan' (kolom tidak terindeks)
UPDATE lab6.hot_penuh SET catatan = 'catatan baru ' || id;
UPDATE lab6.hot_longgar SET catatan = 'catatan baru ' || id;

ANALYZE lab6.hot_penuh;
ANALYZE lab6.hot_longgar;

-- Paksa PostgreSQL memperbarui statistik aktivitas pengaksesan tabel
SELECT pg_stat_force_next_flush();

-- Cek statistik HOT Update
SELECT 
  relname AS nama_tabel,
  n_tup_upd AS total_update,
  n_tup_hot_upd AS total_hot_update,
  round((n_tup_hot_upd::numeric / NULLIF(n_tup_upd, 0)) * 100, 2) AS persen_hot_update
FROM pg_stat_user_tables
WHERE schemaname = 'lab6' AND relname IN ('hot_penuh', 'hot_longgar');
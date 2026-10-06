\timing on

-- Lakukan UPDATE pada kolom 'val' (kolom yang TERINDEKS) di tabel hot_longgar
UPDATE lab6.hot_longgar SET val = val + 1;

-- Paksa flush statistik
SELECT pg_stat_force_next_flush();

-- Ambil statistik HOT Update terbaru setelah UPDATE kolom terindeks
SELECT 
  relname AS nama_tabel,
  n_tup_upd AS total_update,
  n_tup_hot_upd AS total_hot_update,
  round((n_tup_hot_upd::numeric / NULLIF(n_tup_upd, 0)) * 100, 2) AS persen_hot_update
FROM pg_stat_user_tables
WHERE schemaname = 'lab6' AND relname = 'hot_longgar';
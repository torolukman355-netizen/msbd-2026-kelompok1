\timing on

-- Mengukur ukuran tabel dan index setelah proses UPDATE
SELECT 
  relname AS nama_tabel,
  pg_size_pretty(pg_relation_size(schemaname || '.' || relname)) AS ukuran_tabel_heap,
  pg_size_pretty(pg_indexes_size(schemaname || '.' || relname)) AS ukuran_total_index,
  pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) AS total_ukuran
FROM pg_stat_user_tables
WHERE schemaname = 'lab6' AND relname IN ('hot_penuh', 'hot_longgar')
ORDER BY relname;
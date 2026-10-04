\timing on

-- A. Ukuran Fisik Tabel Heap dan Total (+ Index Primary Key)
SELECT 
  pg_size_pretty(pg_relation_size('lab6.event_log')) AS ukuran_heap_tabel,
  pg_size_pretty(pg_total_relation_size('lab6.event_log')) AS total_ukuran_dengan_pk;

-- B. Menghitung Rata-Rata Byte per Baris Secara Nyata
SELECT 
  reltuples AS estimasi_jumlah_baris,
  relpages AS jumlah_halaman_8kb,
  pg_relation_size('lab6.event_log') / reltuples AS avg_bytes_per_row
FROM pg_class 
WHERE relname = 'event_log' 
  AND relnamespace = 'lab6'::regnamespace;
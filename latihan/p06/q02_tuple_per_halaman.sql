\timing on

-- 1. Mengambil sampel jumlah tuple pada 10 halaman pertama lewat ctid
SELECT 
  (ctid::text::point)[0] AS nomor_halaman,
  COUNT(*) AS jumlah_tuple
FROM lab6.event_log
GROUP BY nomor_halaman
ORDER BY nomor_halaman
LIMIT 10;

-- 2. Menghitung rata-rata, maksimum, dan minimum tuple per halaman secara keseluruhan
SELECT 
  AVG(tuple_count)::numeric(10,2) AS avg_tuple_per_halaman,
  MAX(tuple_count) AS max_tuple_per_halaman,
  MIN(tuple_count) AS min_tuple_per_halaman
FROM (
  SELECT COUNT(*) AS tuple_count
  FROM lab6.event_log
  GROUP BY (ctid::text::point)[0]
) s;
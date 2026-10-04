\timing on

-- Memeriksa strategi penyimpanan (attstorage) untuk setiap kolom di lab6.event_log
SELECT 
  attname AS nama_kolom,
  format_type(atttypid, atttypmod) AS tipe_data,
  attstorage AS kode_storage,
  CASE attstorage
    WHEN 'p' THEN 'plain (harus inline, tanpa kompresi)'
    WHEN 'e' THEN 'external (bisa TOAST, tanpa kompresi)'
    WHEN 'm' THEN 'main (inline dulu, kompresi sebelum TOAST)'
    WHEN 'x' THEN 'extended (kompresi inline + TOAST jika perlu)'
  END AS keterangan_storage
FROM pg_attribute
WHERE attrelid = 'lab6.event_log'::regclass
  AND attnum > 0
  AND NOT attisdropped
ORDER BY attnum;
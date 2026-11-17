-- CONTOH BURUK 
-- SET app.tenant = '1'; 

-- CONTOH AMAN (Menggunakan SET LOCAL yang otomatis bersih saat transaksi selesai)
BEGIN;
SET LOCAL app.tenant = '1';
SELECT * FROM lab11.pelanggan;
COMMIT;

-- ATAU menggunakan fungsi set_config dengan parameter is_local = true
-- SELECT set_config('app.tenant', '1', true);
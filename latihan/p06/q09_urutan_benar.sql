-- ============================================================
-- Q9: URUTAN BENAR (Index Scan yang Efisien)
-- ============================================================
-- Tujuan:
--   Membandingkan index salah di Q8 (terjadi_pada, customer_id)
--   dengan index benar (customer_id, terjadi_pada DESC).
--
-- Kenapa urutan kolom penting?
--   Index ibarat buku telepon. Kalau mau cari "semua transaksi
--   customer 4211, urut dari terbaru", maka:
--   - Index salah (terjadi_pada, customer_id):
--       Buku diurut by tanggal. Untuk cari customer 4211, harus
--       baca dari halaman terbaru, lompat-lompat cek satu per satu.
--   - Index benar (customer_id, terjadi_pada DESC):
--       Buku diurut by customer_id dulu. Langsung lompat ke bagian
--       "customer 4211", baca dari atas (terbaru) ke bawah. Cepat!
--
-- Yang diharapkan di output:
--   - "Index Scan using ev_benar_idx" (bukan Seq Scan)
--   - TIDAK ada node "Sort" karena index sudah terurut
--   - Buffers jauh lebih kecil dari Q8 (~3829)
--   - Execution Time lebih cepat dari Q8 (31.984 ms)
-- ============================================================

-- Hapus index lama biar bersih
DROP INDEX IF EXISTS lab6.ev_salah_idx;
DROP INDEX IF EXISTS lab6.ev_benar_idx;

-- Buat index dengan urutan yang BENAR:
-- customer_id dulu (untuk filter equality),
-- baru terjadi_pada DESC (untuk ORDER BY)
CREATE INDEX ev_benar_idx 
ON lab6.event_log (customer_id, terjadi_pada DESC);

-- Jalankan EXPLAIN untuk lihat rencana eksekusi
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;
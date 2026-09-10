-- Q19 · q19_notifikasi_lunas.sql
-- Tampilkan notifikasi berstatus lunas,
-- nomor transaksi, kota pelanggan, dan jumlah sebagai angka.

-- Membuat indeks GIN pada payload JSONB
CREATE INDEX IF NOT EXISTS idx_notifikasi_payload_gin
ON notifikasi
USING GIN (payload);

-- Menampilkan notifikasi berstatus lunas
SELECT
    payload->>'nomor_transaksi' AS nomor_transaksi,
    payload->'pelanggan'->>'kota' AS kota,
    (payload->>'jumlah')::numeric AS jumlah
FROM notifikasi
WHERE payload @> '{"status": "lunas"}'::jsonb;

-- Tampilkan definisi tabel dan indeks
\d notifikasi
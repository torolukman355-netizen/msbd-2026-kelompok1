-- Q20 · q20_bentangkan_kontak.sql
-- Bentangkan array kontak menjadi satu baris per kontak.
-- Notifikasi tanpa kontak tetap ditampilkan.

SELECT
    n.payload->>'nomor_transaksi' AS nomor_transaksi,
    kontak->>'jenis' AS jenis_kontak,
    kontak->>'nomor' AS nomor_kontak
FROM notifikasi AS n
LEFT JOIN LATERAL jsonb_array_elements(
    COALESCE(n.payload->'kontak', '[]'::jsonb)
) AS kontak ON true;
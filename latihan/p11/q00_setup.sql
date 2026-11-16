-- Diminta: memverifikasi jumlah baris keempat tabel skema lab11 dan distribusi data per penyewa setelah setup kontainer tertutup.
-- Dipilih: query agregasi count(*) pada tabel tenant, pelanggan, akun, dan transaksi untuk memastikan dataset deterministik termuat utuh.
-- Alternatif: memeriksa ukuran tabel (pg_total_relation_size); tidak dipilih karena soal mensyaratkan verifikasi eksak jumlah baris.

SELECT (SELECT count(*) FROM lab11.tenant)     AS tenant,
       (SELECT count(*) FROM lab11.pelanggan)  AS pelanggan,
       (SELECT count(*) FROM lab11.akun)       AS akun,
       (SELECT count(*) FROM lab11.transaksi)  AS transaksi;

SELECT tenant_id, count(*) AS jumlah_pelanggan
FROM lab11.pelanggan
GROUP BY 1
ORDER BY 1;
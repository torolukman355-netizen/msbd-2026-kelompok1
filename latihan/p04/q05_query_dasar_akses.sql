-- Diminta: Menjalankan query agregasi dasar dan mencatat waktu eksekusinya.
-- Dipilih: Query SELECT dengan GROUP BY dan ORDER BY sesuai instruksi soal.
-- Alternatif: Subquery; tidak dipilih karena penggunaan GROUP BY langsung jauh lebih efisien.

SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2;
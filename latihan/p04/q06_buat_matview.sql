-- Diminta: Membuat materialized view dari Q5 dengan WITH NO DATA, mencatat galat, dan waktu refresh biasa.
-- Dipilih: CREATE MATERIALIZED VIEW ... WITH NO DATA karena instruksi meminta kerangka kosong di awal.
-- Alternatif: CREATE TABLE biasa; tidak dipilih karena tabel tidak memiliki fitur REFRESH sinkronisasi otomatis.

CREATE MATERIALIZED VIEW lab4.ringkasan_akses AS
SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2
WITH NO DATA;
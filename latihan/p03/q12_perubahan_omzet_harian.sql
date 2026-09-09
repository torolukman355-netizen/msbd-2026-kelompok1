-- Diminta: Menampilkan omzet harian, omzet kemarin, selisih, dan persentase perubahannya.
-- Dipilih: Window function LAG dengan nilai default 0 karena efisien mengambil nilai baris sebelumnya tanpa join.
-- Alternatif: Self-join pada tabel; tidak dipilih karena rumit dan rawan salah jika ada tanggal yang terlewat.

WITH OmzetHarian AS (
    SELECT
        DATE(payment_date) AS tanggal,
        SUM(amount) AS omzet_hari_ini
    FROM payment
    GROUP BY DATE(payment_date)
),
PerubahanOmzet AS (
    SELECT
        tanggal,
        omzet_hari_ini,
        LAG(omzet_hari_ini, 1, 0) OVER (ORDER BY tanggal) AS omzet_kemarin
    FROM OmzetHarian
)
SELECT
    tanggal,
    omzet_hari_ini,
    omzet_kemarin,
    (omzet_hari_ini - omzet_kemarin) AS selisih,
    CASE
        WHEN omzet_kemarin = 0 THEN NULL -- Menangani division by zero sesuai petunjuk
        ELSE ((omzet_hari_ini - omzet_kemarin) / omzet_kemarin) * 100
    END AS persentase_perubahan
FROM PerubahanOmzet;
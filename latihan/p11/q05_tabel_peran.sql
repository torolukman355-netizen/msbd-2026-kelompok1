-- Diminta: memetakan seluruh tujuh peran pada skema lab11 beserta kapabilitas, status login, dan alasan arsitektural pemisahan pemilik objek.
-- Dipilih: query katalog sistem pg_roles untuk memverifikasi atribut rolcanlogin dan rolsuper dari ketujuh peran di basis data.
-- Alternatif: membuat daftar statis tanpa kueri katalog; tidak dipilih karena bukti harus bersumber dari keluaran nyata basis data.

SELECT rolname AS nama_peran,
       rolcanlogin AS dapat_login,
       rolsuper AS superuser
FROM pg_roles
WHERE rolname IN (
    'skema_owner', 'app_read', 'app_write',
    'app_portal', 'app_laporan', 'app_analitik', 'app_migrasi'
)
ORDER BY rolcanlogin, rolname;

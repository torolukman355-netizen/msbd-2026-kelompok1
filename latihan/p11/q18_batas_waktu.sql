-- =========================================================
-- Q18: STATEMENT TIMEOUT
-- =========================================================
-- Membatasi waktu eksekusi setiap perintah SQL
-- untuk koneksi baru dengan role app_portal menjadi 5 detik.
ALTER ROLE app_portal
SET
    statement_timeout = '5s';

-- Memeriksa konfigurasi role app_portal.
SELECT
    rolname,
    rolconfig
FROM
    pg_roles
WHERE
    rolname = 'app_portal';

-- Hasil yang diharapkan:
-- rolconfig memuat statement_timeout=5s
--
-- Analisis:
-- statement_timeout membatasi durasi eksekusi query.
-- Jika query berjalan melebihi 5 detik, PostgreSQL
-- akan membatalkan query tersebut secara otomatis.
--
-- Hal ini membatasi dampak query yang berjalan terlalu lama,
-- termasuk query yang melibatkan fungsi penundaan pg_sleep.
--
-- SQLSTATE: 57014 (query_canceled)
--
-- Batas waktu tidak menghilangkan SQL Injection,
-- tetapi mengurangi dampak query yang berjalan terlalu lama
-- dan membantu mengidentifikasi aktivitas mencurigakan melalui log.
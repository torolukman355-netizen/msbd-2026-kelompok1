-- Diminta: memeriksa apakah peran app_laporan dapat membaca tabel baru yang dibuat oleh postgres (bukan skema_owner) dan menentukan perintah default privileges yang tepat.
-- Dipilih: membuat tabel uji lab11.catatan_postgres sebagai postgres, mengecek has_table_privilege untuk app_laporan, lalu menghapus tabel uji.
-- Alternatif: memberikan GRANT SELECT secara manual setiap kali tabel dibuat; tidak dipilih karena rentan terlewat dan tidak otomatis.

CREATE TABLE lab11.catatan_postgres (id int);
SELECT has_table_privilege('app_laporan', 'lab11.catatan_postgres', 'SELECT') AS via_postgres;
DROP TABLE lab11.catatan_postgres;
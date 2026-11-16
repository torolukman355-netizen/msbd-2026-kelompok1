-- Diminta: menguji pencabutan perintah DROP dari skema_owner dan menjelaskan perbedaan hak akses standar dengan hak kepemilikan.
-- Dipilih: menjalankan REVOKE DROP ON lab11.akun FROM skema_owner untuk mengamati pesan galat tipe hak tidak dikenal dari PostgreSQL.
-- Alternatif: mencabut ALL PRIVILEGES; tidak dipilih karena ALL hanya mencakup hak dalam daftar ACL, bukan operasi struktural milik owner.

REVOKE DROP ON lab11.akun FROM skema_owner;
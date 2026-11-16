-- Diminta: membuktikan bahwa hak biasa (UPDATE) yang dicabut dari pemilik tabel (skema_owner) tetap dapat diberikan kembali oleh pemilik itu sendiri.
-- Dipilih: mencabut UPDATE via superuser, menguji UPDATE sebagai skema_owner (ditolak), lalu menjalankan GRANT UPDATE ke diri sendiri dan mengulang UPDATE (berhasil).
-- Alternatif: mencabut hak melalui peran grup; tidak dipilih karena kepemilikan objek melekat langsung pada peran pemilik (tableowner).

REVOKE UPDATE ON lab11.pelanggan FROM skema_owner;

SET ROLE skema_owner;
BEGIN;
UPDATE lab11.pelanggan SET kota = kota WHERE id = 3;
ROLLBACK;

GRANT UPDATE ON lab11.pelanggan TO skema_owner;

BEGIN;
UPDATE lab11.pelanggan SET kota = kota WHERE id = 3;
ROLLBACK;
RESET ROLE;
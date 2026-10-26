/*
Q13: Menguji SELECT ... FOR UPDATE.

Tujuan:
Mengamati kapan transaksi kedua menunggu dan bagaimana transaksi
kedua melanjutkan proses setelah transaksi pertama selesai.
 */
-- ==========================================
-- SESI 1: Jalankan pada koneksi pertama
-- ==========================================
BEGIN;

SELECT
    rekening_id,
    saldo
FROM
    lab9.rekening
WHERE
    rekening_id = 1 FOR
UPDATE;

-- Jangan COMMIT dahulu.
-- Baris rekening_id = 1 sedang dikunci oleh sesi pertama.
-- ==========================================
-- SESI 2: Jalankan pada koneksi kedua
-- ==========================================
-- Jalankan blok ini setelah sesi 1 mengambil kunci.
-- SELECT berikut akan menunggu selama sesi 1 masih memegang kunci.
-- BEGIN;
-- SELECT rekening_id, saldo
-- FROM lab9.rekening
-- WHERE rekening_id = 1
-- FOR UPDATE;
-- COMMIT;
-- ==========================================
-- KEMBALI KE SESI 1
-- ==========================================
-- Jalankan pada sesi pertama untuk melepaskan kunci:
-- COMMIT;
/*
Penjelasan:
SELECT ... FOR UPDATE mengunci baris yang dipilih.
Ketika sesi kedua meminta kunci pada baris yang sama, sesi kedua
menunggu sampai transaksi pertama melakukan COMMIT atau ROLLBACK.

Setelah transaksi pertama selesai, kunci dilepaskan dan sesi kedua
dapat melanjutkan. Pada tingkat isolasi READ COMMITTED, sesi kedua
akan memperoleh versi baris terbaru yang sesuai dengan kondisi
pencariannya.
 */
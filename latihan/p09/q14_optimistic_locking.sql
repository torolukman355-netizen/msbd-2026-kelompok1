/*
Q14: Mendeteksi perubahan data menggunakan version_no.

Tujuan:
Memastikan data belum berubah sejak aplikasi membaca versi baris.
 */
-- Menambahkan kolom versi jika belum tersedia.
ALTER TABLE lab9.rekening
ADD COLUMN IF NOT EXISTS version_no INTEGER NOT NULL DEFAULT 0;

-- Aplikasi membaca saldo dan nomor versi.
SELECT
    rekening_id,
    saldo,
    version_no
FROM
    lab9.rekening
WHERE
    rekening_id = 1;

-- Contoh: aplikasi sebelumnya membaca version_no = 0.
-- Sesuaikan angka 0 dengan versi aktual yang dibaca aplikasi.
BEGIN;

UPDATE lab9.rekening
SET
    saldo = saldo - 10000,
    version_no = version_no + 1
WHERE
    rekening_id = 1
    AND version_no = 0
    AND saldo >= 10000;

-- Periksa hasil UPDATE pada Command Tag.
-- UPDATE 1 = pembaruan berhasil.
-- UPDATE 0 = versi tidak cocok, rekening tidak ditemukan,
--            atau saldo tidak mencukupi.
SELECT
    rekening_id,
    saldo,
    version_no
FROM
    lab9.rekening
WHERE
    rekening_id = 1;

COMMIT;

/*
Penjelasan:
version_no bertambah setiap kali pembaruan berhasil.

Jika transaksi lain sudah mengubah data dan menaikkan version_no,
kondisi WHERE version_no = 0 tidak lagi terpenuhi. Akibatnya,
UPDATE memengaruhi nol baris.

Aplikasi mengetahui kemungkinan konflik melalui jumlah baris yang
diperbarui. Jika hasilnya nol, aplikasi perlu membaca ulang data
dan menangani konflik sebelum mencoba kembali.
 */
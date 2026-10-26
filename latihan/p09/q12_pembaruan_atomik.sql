/*
Q12: Memperbaiki lost update dengan pembaruan atomik.

Tujuan:
Menghitung pengurangan saldo langsung di database agar perubahan
transaksi lain tidak tertimpa oleh hasil perhitungan saldo lama.
 */
BEGIN;

-- Melihat saldo awal.
SELECT
    rekening_id,
    saldo
FROM
    lab9.rekening
WHERE
    rekening_id = 1;

-- Pembaruan atomik.
UPDATE lab9.rekening
SET
    saldo = saldo - 10000
WHERE
    rekening_id = 1
    AND saldo >= 10000;

-- Memeriksa saldo setelah pembaruan.
SELECT
    rekening_id,
    saldo
FROM
    lab9.rekening
WHERE
    rekening_id = 1;

COMMIT;

/*
Penjelasan:
Pembaruan atomik lebih aman karena pengurangan dihitung langsung
berdasarkan nilai saldo pada database, bukan nilai lama yang dibaca
dan dihitung sebelumnya oleh aplikasi.

Jika dua transaksi mengurangi saldo secara bersamaan, penggunaan
saldo = saldo - 10000 memungkinkan perubahan dilakukan secara
berurutan oleh database sehingga risiko lost update berkurang.

Kondisi saldo >= 10000 mencegah saldo menjadi negatif akibat
pengurangan tersebut.
 */
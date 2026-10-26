/*
Q16: Membaca metadata transaksi PostgreSQL.
 */
SELECT
    rekening_id,
    saldo,
    xmin,
    xmax
FROM
    lab9.rekening
WHERE
    rekening_id = 1;

/*
Penjelasan:

1. xmin
ID transaksi yang membuat versi baris tersebut.

2. xmax
ID transaksi yang menghapus versi baris atau menandainya untuk
dihapus/digantikan, bergantung pada operasi dan mekanisme internal.

xmin dan xmax merupakan metadata sistem PostgreSQL, bukan kolom
bisnis biasa.

Nilai xmax = 0 sering menunjukkan bahwa versi baris belum ditandai
untuk dihapus atau digantikan. Namun, nilai ini saja tidak cukup
untuk memastikan seluruh status visibilitas baris.

Visibilitas juga dipengaruhi status transaksi dan snapshot MVCC.
Karena itu, xmin atau xmax tidak dapat digunakan sendirian untuk
mendiagnosis seluruh status visibilitas data.
 */
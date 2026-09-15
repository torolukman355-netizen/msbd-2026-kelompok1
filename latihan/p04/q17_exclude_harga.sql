-- Diminta: Membuat tabel harga film dengan constraint EXCLUDE sehingga periode harga untuk film dan
--          wilayah yang sama tidak boleh tumpang tindih, lalu membuktikan satu INSERT diterima dan
--          satu INSERT lain ditolak.
-- Dipilih: EXCLUDE USING gist (film_id WITH =, wilayah WITH =, berlaku WITH &&), karena constraint
--          ini menegakkan aturan "tidak boleh overlap" secara deklaratif dan atomik di level database,
--          memakai index GiST yang dirancang untuk kombinasi operator kesetaraan (=) dan overlap (&&).
-- Alternatif: Trigger BEFORE INSERT yang mengecek overlap lewat SELECT sebelum menyisipkan; tidak
--          dipilih karena rentan terhadap race condition antar transaksi konkuren (lihat Pertanyaan
--          Reflektif D).

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    EXCLUDE USING gist (film_id WITH =, wilayah WITH =, berlaku WITH &&)
);

INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (1, 'Sumatera', 3.99, daterange('2026-01-01', '2026-04-01'));

INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (1, 'Sumatera', 4.99, daterange('2026-03-01', '2026-07-01'));

INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (1, 'Sumatera', 4.49, daterange('2026-04-01', '2026-07-01'));

SELECT harga_film_id, film_id, wilayah, harga, berlaku
FROM lab4.harga_film
ORDER BY harga_film_id;
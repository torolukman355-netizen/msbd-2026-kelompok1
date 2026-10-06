-- Diminta: Menambahkan CHECK constraint bahwa rental_rate tidak boleh negatif secara dua tahap
--          (NOT VALID lalu VALIDATE), menyisipkan data negatif lebih dulu untuk membuktikan tahap
--          pertama tetap lolos walau ada data yang melanggar, namun VALIDATE CONSTRAINT gagal,
--          kemudian memperbaiki data dan mengulang validasi hingga berhasil.
-- Dipilih: ADD CONSTRAINT ... CHECK (...) NOT VALID diikuti VALIDATE CONSTRAINT terpisah, karena
--          skema ini membuat constraint langsung aktif untuk baris BARU tanpa harus memvalidasi
--          seluruh baris LAMA sekaligus di saat yang sama.
-- Alternatif: ADD CONSTRAINT ... CHECK (...) langsung tanpa NOT VALID; tidak dipilih karena
--          PostgreSQL akan langsung memindai dan memvalidasi seluruh baris lama, dan constraint
--          akan GAGAL DIBUAT SAMA SEKALI jika ada satu saja baris yang melanggar — padahal soal
--          justru meminta kita membuktikan constraint bisa dibuat dulu dalam kondisi belum valid.


INSERT INTO lab4.film (film_id, title, rental_rate)
VALUES (2001, 'Film Uji Q14', -5.00);

ALTER TABLE lab4.film
    ADD CONSTRAINT film_harga_non_negatif CHECK (rental_rate >= 0) NOT VALID;

SELECT film_id, title, rental_rate
FROM lab4.film
WHERE film_id = 2001;

INSERT INTO lab4.film (film_id, title, rental_rate)
VALUES (2002, 'Film Uji Q14 Baru', -1.00);

ALTER TABLE lab4.film VALIDATE CONSTRAINT film_harga_non_negatif;

UPDATE lab4.film
SET rental_rate = 5.00
WHERE film_id = 2001;

ALTER TABLE lab4.film VALIDATE CONSTRAINT film_harga_non_negatif;

SELECT conname, convalidated
FROM pg_constraint
WHERE conname = 'film_harga_non_negatif';
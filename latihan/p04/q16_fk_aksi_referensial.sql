-- Diminta: Membuat tabel lab4.ulasan dengan foreign key ke lab4.film, mengisi data uji, lalu
--          membuktikan perbedaan perilaku penghapusan baris induk (film) di bawah tiga aksi
--          referensial berbeda: NO ACTION, CASCADE, SET NULL.
-- Dipilih: Mengubah aksi ON DELETE pada foreign key yang sama secara bertahap (DROP CONSTRAINT
--          lalu ADD CONSTRAINT baru) dan mengulang skenario delete untuk tiap aksi, karena ini
--          memungkinkan pengujian ketiga perilaku pada struktur tabel yang identik.
-- Alternatif: Membuat tiga tabel ulasan terpisah (ulasan_no_action, ulasan_cascade, ulasan_set_null)
--          sekaligus; tidak dipilih karena menambah kompleksitas skema tanpa manfaat tambahan,
--          sedangkan mengganti aksi FK pada satu tabel sudah cukup representatif untuk dibandingkan.

CREATE TABLE IF NOT EXISTS lab4.ulasan (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer,
    isi text NOT NULL,
    dibuat_pada timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ulasan_film_fk FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE NO ACTION
);

INSERT INTO lab4.film (film_id, title) VALUES (3001, 'Film Uji Q16 - NO ACTION');
INSERT INTO lab4.ulasan (film_id, isi) VALUES (3001, 'Ulasan uji untuk skenario NO ACTION');

DELETE FROM lab4.film WHERE film_id = 3001;

SELECT film_id, title FROM lab4.film WHERE film_id = 3001;
SELECT ulasan_id, film_id, isi FROM lab4.ulasan WHERE film_id = 3001;

ALTER TABLE lab4.ulasan DROP CONSTRAINT ulasan_film_fk;
ALTER TABLE lab4.ulasan
    ADD CONSTRAINT ulasan_film_fk FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id) ON DELETE CASCADE;

DELETE FROM lab4.film WHERE film_id = 3001;

SELECT film_id, title FROM lab4.film WHERE film_id = 3001;
SELECT ulasan_id, film_id, isi FROM lab4.ulasan WHERE film_id = 3001;

ALTER TABLE lab4.ulasan DROP CONSTRAINT ulasan_film_fk;
ALTER TABLE lab4.ulasan
    ADD CONSTRAINT ulasan_film_fk FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id) ON DELETE SET NULL;

INSERT INTO lab4.film (film_id, title) VALUES (3002, 'Film Uji Q16 - SET NULL');
INSERT INTO lab4.ulasan (film_id, isi) VALUES (3002, 'Ulasan uji untuk skenario SET NULL');

DELETE FROM lab4.film WHERE film_id = 3002;

SELECT ulasan_id, film_id, isi
FROM lab4.ulasan
WHERE isi = 'Ulasan uji untuk skenario SET NULL';


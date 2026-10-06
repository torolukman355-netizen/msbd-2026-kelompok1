-- Diminta: Menambahkan kolom deleted_at (soft delete) pada lab4.film, membuktikan UNIQUE constraint
--          biasa pada title menghalangi pendaftaran ulang judul yang sudah di-soft-delete, lalu
--          menggantinya dengan UNIQUE INDEX PARSIAL yang hanya menegakkan keunikan pada baris aktif.
-- Dipilih: UNIQUE INDEX PARSIAL dengan klausa WHERE deleted_at IS NULL, karena index ini hanya
--          menegakkan keunikan title di antara baris yang masih aktif, sehingga judul yang sudah
--          di-soft-delete boleh didaftarkan ulang oleh baris baru.
-- Alternatif: Tetap memakai UNIQUE constraint biasa pada title; tidak dipilih karena constraint ini
--          menganggap baris soft-deleted tetap "ada" (bukan benar-benar terhapus), sehingga tetap
--          memblokir pendaftaran ulang judul yang sama.

ALTER TABLE lab4.film ADD COLUMN deleted_at timestamptz;
ALTER TABLE lab4.film ADD CONSTRAINT film_judul_unik UNIQUE (title);

UPDATE lab4.film
SET deleted_at = now()
WHERE film_id = 1;

INSERT INTO lab4.film (film_id, title, deleted_at)
SELECT 2003, title, NULL
FROM lab4.film
WHERE film_id = 1;

ALTER TABLE lab4.film DROP CONSTRAINT film_judul_unik;

CREATE UNIQUE INDEX ux_film_judul_aktif
    ON lab4.film (title) WHERE deleted_at IS NULL;

INSERT INTO lab4.film (film_id, title, deleted_at)
SELECT 2003, title, NULL
FROM lab4.film
WHERE film_id = 1;

INSERT INTO lab4.film (film_id, title)
SELECT 2004, title
FROM lab4.film
WHERE film_id = 2003;

SELECT film_id, title, deleted_at
FROM lab4.film
WHERE title = (SELECT title FROM lab4.film WHERE film_id = 1);
INSERT INTO
    lab4.film_murah (film_id, title, rental_rate, rating)
VALUES
    (1001, 'Film Uji Q2', 4.99, 'PG');

SELECT
    COUNT(*) AS jumlah_di_view
FROM
    lab4.film_murah
WHERE
    title = 'Film Uji Q2';

SELECT
    COUNT(*) AS jumlah_di_tabel_dasar
FROM
    lab4.film
WHERE
    title = 'Film Uji Q2';
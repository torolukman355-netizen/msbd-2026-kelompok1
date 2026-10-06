CREATE
OR REPLACE VIEW lab4.pendapatan_kategori AS
SELECT
    c.name AS kategori,
    SUM(p.amount) AS total_pendapatan
FROM
    public.category c
    JOIN public.film_category fc ON c.category_id = fc.category_id
    JOIN public.inventory i ON fc.film_id = i.film_id
    JOIN public.rental r ON i.inventory_id = r.inventory_id
    JOIN public.payment p ON r.rental_id = p.rental_id
GROUP BY
    c.category_id,
    c.name;

SELECT
    *
FROM
    lab4.pendapatan_kategori;

INSERT INTO
    lab4.pendapatan_kategori (kategori, total_pendapatan)
VALUES
    ('Test', 1000);
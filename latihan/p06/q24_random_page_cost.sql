SET
    random_page_cost = 1.1;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    *
FROM
    besar
WHERE
    status = 'SUKSES';

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    *
FROM
    besar
WHERE
    status = 'GAGAL';

RESET random_page_cost;
CREATE INDEX idx_status ON besar (status);

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
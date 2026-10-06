CREATE STATISTICS stat_wilayah_kota_dep (dependencies) ON wilayah,
kota
FROM
    besar;

CREATE STATISTICS stat_wilayah_kota_nd (ndistinct) ON wilayah,
kota
FROM
    besar;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    *
FROM
    besar
WHERE
    wilayah = 'SUMATERA UTARA'
    AND kota = 'MEDAN';

ANALYZE besar;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    *
FROM
    besar
WHERE
    wilayah = 'SUMATERA UTARA'
    AND kota = 'MEDAN';
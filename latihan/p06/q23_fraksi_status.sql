SELECT
    status,
    COUNT(*) AS jumlah,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS fraksi_persen
FROM
    besar
GROUP BY
    status
ORDER BY
    jumlah DESC;
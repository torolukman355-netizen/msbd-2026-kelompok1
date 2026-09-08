WITH RECURSIVE hierarki_pegawai AS (
    SELECT 
        pegawai_id,
        nama,
        atasan_id,
        1 AS level_kedalaman,
        nama::text AS jalur_jabatan
    FROM pegawai
    WHERE atasan_id IS NULL

    UNION ALL

    SELECT 
        p.pegawai_id,
        p.nama,
        p.atasan_id,
        h.level_kedalaman + 1,
        h.jalur_jabatan || ' > ' || p.nama
    FROM pegawai p
    JOIN hierarki_pegawai h ON p.atasan_id = h.pegawai_id
)
SELECT 
    pegawai_id,
    nama,
    level_kedalaman,
    jalur_jabatan
FROM hierarki_pegawai
ORDER BY level_kedalaman, pegawai_id;
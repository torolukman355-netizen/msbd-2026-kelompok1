WITH RECURSIVE hierarki_aman AS (
    -- Anchor member
    SELECT 
        pegawai_id,
        nama,
        atasan_id,
        1 AS level_kedalaman,
        nama::text AS jalur_jabatan
    FROM pegawai
    WHERE atasan_id IS NULL

    UNION ALL

    -- Recursive member
    SELECT 
        p.pegawai_id,
        p.nama,
        p.atasan_id,
        h.level_kedalaman + 1,
        h.jalur_jabatan || ' > ' || p.nama
    FROM pegawai p
    JOIN hierarki_aman h ON p.atasan_id = h.pegawai_id
)
CYCLE pegawai_id SET is_cycle USING path
SELECT 
    pegawai_id,
    nama,
    level_kedalaman,
    jalur_jabatan,
    is_cycle
FROM hierarki_aman
ORDER BY level_kedalaman, pegawai_id;
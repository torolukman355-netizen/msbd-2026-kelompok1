SELECT count(*) AS sebelum_force FROM lab11.pelanggan;

ALTER TABLE lab11.pelanggan FORCE ROW LEVEL SECURITY;
SELECT count(*) AS sesudah_force FROM lab11.pelanggan;

BEGIN;
SET LOCAL ROLE app_analitik;
SELECT count(*) AS lewat_role_biasa FROM lab11.pelanggan;
COMMIT;

GRANT pg_read_all_data TO app_analitik;
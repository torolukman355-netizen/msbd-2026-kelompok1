ALTER TABLE lab11.pelanggan ENABLE ROW LEVEL SECURITY;

BEGIN; 
SET LOCAL ROLE app_laporan;
SELECT count(*) AS sebelum_ada_kebijakan FROM lab11.pelanggan;  -- harapkan 0
COMMIT;
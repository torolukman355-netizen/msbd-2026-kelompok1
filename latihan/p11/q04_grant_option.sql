-- Diminta: menguji pendelegasian hak SELECT menggunakan WITH GRANT OPTION dan mengamati efek pencabutan dengan dan tanpa CASCADE.
-- Dipilih: memberi SELECT WITH GRANT OPTION ke app_write, meneruskannya ke app_analitik, lalu menjalankan REVOKE GRANT OPTION tanpa dan dengan CASCADE.
-- Alternatif: mencabut SELECT secara penuh (REVOKE SELECT ... CASCADE); tidak dipilih karena app_write harus tetap mempertahankan hak bacanya sendiri.

GRANT SELECT ON lab11.transaksi TO app_write WITH GRANT OPTION;

SET ROLE app_write;
GRANT SELECT ON lab11.transaksi TO app_analitik;
RESET ROLE;

REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write;
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write CASCADE;

SELECT has_table_privilege('app_analitik', 'lab11.transaksi', 'SELECT') AS analitik,
       has_table_privilege('app_write', 'lab11.transaksi', 'SELECT')    AS app_write;
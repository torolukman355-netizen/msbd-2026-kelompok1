-- Celah 1: Lupa mengaktifkan RLS pada tabel baru yang baru dibuat.
-- Perbaikan: Selalu terapkan default security policy atau audit otomatis pada skema.
CREATE TABLE IF NOT EXISTS lab11.audit_celah (id int);
-- Lupa ALTER TABLE ... ENABLE ROW LEVEL SECURITY;

-- Celah 2: Penggunaan SECURITY DEFINER pada fungsi helper yang mengabaikan RLS pemanggil.
CREATE OR REPLACE FUNCTION lab11.get_semua_data() 
RETURNS SETOF lab11.pelanggan 
SECURITY DEFINER 
LANGUAGE sql AS $$
    SELECT * FROM lab11.pelanggan; -- Ini membocorkan data lintas tenant!
$$;
-- Perbaikan: Gunakan SECURITY INVOKER agar fungsi berjalan dengan hak akses pengguna yang memanggilnya.

-- Celah 3: Eksploitasi celah tipe data atau celah casting parameter kosong.
BEGIN;
SET LOCAL app.tenant = ''; -- Kosong atau tidak diset dengan benar
SELECT * FROM lab11.pelanggan;
COMMIT;
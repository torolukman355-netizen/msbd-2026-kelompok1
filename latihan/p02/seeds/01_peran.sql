CREATE TABLE IF NOT EXISTS peran (
    kode VARCHAR(10) PRIMARY KEY,
    nama VARCHAR(100) NOT NULL
);

INSERT INTO peran (kode, nama) VALUES
('ADM', 'Administrator'),
('PTG', 'Petugas'),
('AGT', 'Anggota')
ON CONFLICT (kode)
DO UPDATE SET nama = EXCLUDED.nama;
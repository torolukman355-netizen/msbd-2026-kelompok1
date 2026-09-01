CREATE TABLE anggota (
    id_anggota bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nim_nip varchar(20) NOT NULL UNIQUE,
    nama varchar(120) NOT NULL,
    peran varchar(10) NOT NULL CHECK (peran IN ('mahasiswa', 'dosen')),
    status_aktif boolean NOT NULL DEFAULT true,
    email varchar(100)
);

CREATE TABLE judul_buku (
    id_buku bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isbn varchar(20) NOT NULL UNIQUE,
    judul varchar(200) NOT NULL,
    pengarang varchar(100) NOT NULL,
    penerbit varchar(100),
    tahun_terbit integer
);

CREATE TABLE eksemplar_buku (
    id_eksemplar bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_buku bigint NOT NULL REFERENCES judul_buku(id_buku),
    kode_barcode varchar(50) NOT NULL UNIQUE,
    lokasi_rak varchar(50),
    status_ketersediaan varchar(20) NOT NULL DEFAULT 'tersedia' 
        CHECK (status_ketersediaan IN ('tersedia', 'dipinjam', 'rusak', 'hilang'))
);

CREATE TABLE peminjaman (
    id_peminjaman bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_anggota bigint NOT NULL REFERENCES anggota(id_anggota),
    id_eksemplar bigint NOT NULL REFERENCES eksemplar_buku(id_eksemplar),
    tgl_pinjam date NOT NULL DEFAULT current_date,
    tgl_tenggat_kembali date NOT NULL,
    petugas_pinjam varchar(100),
    CONSTRAINT ck_peminjaman_tenggat CHECK (tgl_tenggat_kembali >= tgl_pinjam)
);
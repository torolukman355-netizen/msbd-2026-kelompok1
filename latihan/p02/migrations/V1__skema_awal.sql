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

CREATE TABLE kategori_buku (
    id_kategori bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_kategori varchar(100) NOT NULL UNIQUE,
    deskripsi text,            
    kode_kategori varchar(20)          
);

CREATE TABLE judul_buku_kategori (
    id_buku bigint NOT NULL REFERENCES judul_buku(id_buku) ON DELETE CASCADE,
    id_kategori bigint NOT NULL REFERENCES kategori_buku(id_kategori) ON DELETE CASCADE,
    PRIMARY KEY (id_buku, id_kategori)
);

CREATE TABLE eksemplar_buku (
    id_eksemplar bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_buku bigint NOT NULL REFERENCES judul_buku(id_buku),
    kode_barcode varchar(50) NOT NULL UNIQUE,
    lokasi_rak varchar(50),
    status_ketersediaan varchar(20) NOT NULL DEFAULT 'tersedia' CHECK (status_ketersediaan IN ('tersedia', 'dipinjam', 'rusak', 'hilang'))
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

CREATE TABLE pengembalian (
    id_pengembalian bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_peminjaman bigint NOT NULL REFERENCES peminjaman(id_peminjaman),
    tgl_dikembalikan date NOT NULL DEFAULT current_date,
    kondisi_saat_kembali varchar(10) NOT NULL CHECK (kondisi_saat_kembali IN ('baik', 'rusak', 'hilang')),
    petugas_penerima varchar(100) 
);

CREATE TABLE denda (
    id_denda bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pengembalian bigint NOT NULL REFERENCES pengembalian(id_pengembalian),
    jumlah_hari_terlambat integer NOT NULL DEFAULT 0,
    nominal_denda numeric(12,2) NOT NULL DEFAULT 0,
    status_bayar varchar(10) NOT NULL DEFAULT 'belum' CHECK (status_bayar IN ('belum', 'lunas'))
);
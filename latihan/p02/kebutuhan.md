Dokumen Kebutuhan Data - Sistem Peminjaman Buku Perpustakaan Kampus

# A. Domain

**Nama Domain:** Sistem Peminjaman Buku Perpustakaan Kampus

**Penjelasan Domain:**
Domain ini berfokus pada pengelolaan operasional peminjaman dan pengembalian koleksi buku fisik di perpustakaan kampus. Sistem mencatat katalog judul buku beserta eksemplar fisiknya, transaksi sirkulasi peminjaman oleh anggota (mahasiswa dan dosen), hingga perhitungan denda jika terjadi keterlambatan atau kerusakan. Domain ini membatasi operasinya hanya pada transaksi sirkulasi dan status fisik buku, tanpa mengambil alih fungsi manajemen data induk mahasiswa maupun pengadaan buku baru.

## Daftar Entitas (6 Entitas Main):
1. **Anggota (Member):** Menyimpan data pengguna perpustakaan (mahasiswa/dosen) yang memiliki hak akses untuk meminjam buku.
2. **Judul Buku (Book Title):** Menyimpan data katalog/koleksi buku secara umum (judul, pengarang, penerbit, ISBN).
3. **Eksemplar Buku (Book Copy):** Menyimpan data fisik individual dari tiap buku (kode barcode eksemplar, kondisi fisik, status ketersediaan).
4. **Kategori Buku (Category):** Menyimpan pengelompokan genre atau bidang ilmu dari buku.
5. **Peminjaman (Loan):** Menyimpan transaksi utama saat peminjaman eksemplar buku dilakukan oleh anggota.
6. **Denda (Fine):** Menyimpan catatan sanksi finansial akibat keterlambatan pengembalian atau kerusakan buku.

## Syarat Khusus Domain:
* **Relasi Banyak-ke-Banyak (Many-to-Many):** Relasi antara `Judul Buku` dan `Kategori Buku` (satu buku bisa memiliki banyak kategori, dan satu kategori dapat mencakup banyak judul buku).
* **Aturan Bisnis Tidak Sederhana:** Anggota tidak diperbolehkan meminjam buku baru jika total buku yang sedang dipinjam sudah mencapai batas kuota (maksimal 3 buku untuk mahasiswa, 5 untuk dosen) atau jika memiliki denda tertunggak yang belum dilunasi.

# B. Lingkup

| Termasuk | Tidak termasuk |
|---|---|
| Katalog judul buku dan manajemen eksemplar fisiknya | Pengadaan dan pembelian buku baru |
| Transaksi peminjaman dan pengembalian buku | Manajemen data induk mahasiswa/dosen (sinkronisasi *read-only*) |
| Perhitungan denda keterlambatan dan kerusakan buku | Pembayaran denda (*payment gateway* / transaksi keuangan) |
| Pencatatan riwayat kondisi fisik eksemplar buku | Peminjaman ruang baca / fasilitas perpustakaan lainnya |

# C. Kebutuhan Data

## KD-01 Registrasi dan Sinkronisasi Anggota
- **Deskripsi** : Sistem mencatat data anggota perpustakaan yang tersinkronisasi dari sistem akademik kampus.
- **Data** : `id_anggota`, `nim_nip`, `nama`, `peran` (mahasiswa/dosen), `status_aktif`, `email`.
- **Aturan** : Data sifatnya *read-only* dari sistem akademik; hanya anggota berstatus aktif yang dapat melakukan transaksi peminjaman.
- **Volume** : ±10.000 data anggota (diperbarui sinkronisasi harian).
- **Sumber** : Sistem Informasi Akademik Kampus.
- **Prioritas** : Wajib.

## KD-02 Pengelolaan Katalog Buku
- **Deskripsi** : Petugas pustakawan mengelola informasi master judul buku dan kategorinya.
- **Data** : `id_buku`, `isbn`, `judul`, `pengarang`, `penerbit`, `tahun_terbit`, `id_kategori`.
- **Aturan** : ISBN harus unik; satu buku wajib terhubung dengan minimal satu kategori buku.
- **Volume** : ±5.000 judul buku.
- **Sumber** : Hasil wawancara pustakawan & katalog fisik.
- **Prioritas** : Wajib.

## KD-03 Pengelolaan Eksemplar Buku Fisik
- **Deskripsi** : Petugas mendaftarkan unit fisik (eksemplar) dari setiap judul buku yang tersedia di rak perpustakaan.
- **Data** : `id_eksemplar`, `id_buku`, `kode_barcode`, `lokasi_rak`, `status_ketersediaan` (tersedia/dipinjam/rusak/hilang).
- **Aturan** : `kode_barcode` bersifat unik per unit fisik; eksemplar berstatus rusak atau dipinjam tidak dapat diproses untuk peminjaman baru.
- **Volume** : ±15.000 unit eksemplar.
- **Sumber** : Inventarisasi fisik perpustakaan.
- **Prioritas** : Wajib.

## KD-04 Peminjaman Eksemplar Buku
- **Deskripsi** : Petugas mencatat transaksi peminjaman unit eksemplar buku oleh anggota.
- **Data** : `id_peminjaman`, `id_anggota`, `id_eksemplar`, `tgl_pinjam`, `tgl_tenggat_kembali`, `petugas_pinjam`.
- **Aturan** : Anggota tidak boleh meminjam jika memiliki denda tertunggak atau telah mencapai kuota peminjaman aktif (maksimal 3 buku untuk mahasiswa, 5 untuk dosen); status eksemplar berubah menjadi `dipinjam`.
- **Volume** : ±100 transaksi/hari.
- **Sumber** : Observasi Alur Sirkulasi Perpustakaan.
- **Prioritas** : Wajib.

## KD-05 Pengembalian Buku
- **Deskripsi** : Petugas mencatat transaksi pengembalian eksemplar buku yang dipinjam oleh anggota.
- **Data** : `id_pengembalian`, `id_peminjaman`, `tgl_dikembalikan`, `kondisi_saat_kembali` (baik/rusak/hilang), `petugas_penerima`.
- **Aturan** : Hanya berlaku untuk transaksi peminjaman yang berstatus aktif; keterlambatan otomatis memicu perhitungan denda; status eksemplar diperbarui sesuai kondisi akhir.
- **Volume** : ±90 transaksi/hari.
- **Sumber** : Observasi Alur Sirkulasi Perpustakaan.
- **Prioritas** : Wajib.

## KD-06 Perhitungan Denda Keterlambatan dan Kerusakan
- **Deskripsi** : Sistem menghitung besaran denda secara otomatis jika buku dikembalikan melewati batas tanggal kembali atau dalam keadaan rusak/hilang.
- **Data** : `id_denda`, `id_pengembalian`, `jumlah_hari_terlambat`, `nominal_denda`, `status_bayar` (belum/lunas).
- **Aturan** : Denda keterlambatan dihitung per hari terlambat (misal: Rp2.000/hari); kerusakan/kehilangan dikenakan tarif penggantian khusus; peminjaman baru diblokir sampai status denda `lunas`.
- **Volume** : ±15 transaksi denda/hari.
- **Sumber** : Peraturan Tata Tertib Perpustakaan.
- **Prioritas** : Wajib.

## KD-07 Perpanjangan Masa Pinjam Buku
- **Deskripsi** : Anggota mengajukan perpanjangan durasi peminjaman buku sebelum tanggal tenggat berakhir.
- **Data** : `id_perpanjangan`, `id_peminjaman`, `tgl_perpanjangan`, `tgl_tenggat_baru`.
- **Aturan** : Perpanjangan hanya dapat dilakukan maksimal 1 kali per peminjaman; hanya berlaku jika buku tidak sedang dipesan oleh anggota lain dan tidak mengalami keterlambatan.
- **Volume** : ±20 transaksi/hari.
- **Sumber** : Kebutuhan Pengguna (Anggota).
- **Prioritas** : Opsional.

## KD-08 Pencatatan Riwayat Perbaikan Eksemplar
- **Deskripsi** : Petugas mencatat tindakan perbaikan/restorasi fisik pada eksemplar buku yang mengalami kerusakan ringan.
- **Data** : `id_perbaikan`, `id_eksemplar`, `tgl_mulai_perbaikan`, `tgl_selesai_perbaikan`, `rincian_perbaikan`.
- **Aturan** : Eksemplar yang masuk dalam proses perbaikan diubah status ketersediaannya menjadi `dalam_perbaikan` dan otomatis disembunyikan dari pilihan katalog yang siap pinjam.
- **Volume** : ±5 transaksi/minggu.
- **Sumber** : Tim Pemeliharaan Perpustakaan.
- **Prioritas** : Opsional.
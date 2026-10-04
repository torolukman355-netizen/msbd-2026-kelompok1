### JAWABAN Q1 · REFLEKTIF: UKURAN TABEL & PERBANDINGAN BYTE PER BARIS

1. HASIL PENGUKURAN NYATA (PostgreSQL):
- Ukuran Heap Tabel (pg_relation_size): 458 MB
- Ukuran Total Tabel + Index Primary Key (pg_total_relation_size): 501 MB
- Jumlah Halaman (relpages): 58.571 halaman (ukuran per halaman 8 KB)
- Rata-Rata Byte per Baris Nyata (Heap / 2 Juta Baris): 239.91 byte (~240 byte/baris)

2. PERKIRAAN TEORETIS DEFINISI KOLOM (Murni Data):
- Header Baris (HeapTupleHeaderData): 23 byte
- event_id (bigint): 8 byte
- customer_id (integer): 4 byte
- terjadi_pada (timestamptz): 8 byte
- status (text): ~7 byte (SUKSES/TERTUNDA/GAGAL + 1 byte varlena header)
- wilayah (text): ~6 byte (SUMUT, JABAR, dll. + varlena)
- kota (text): ~8 byte (SUMUT-1, JATIM-9, dll. + varlena)
- email (text): ~23 byte (userX@contoh.ac.id + varlena)
- idempotency_key (uuid): 16 byte
- jumlah (numeric(10,2)): 10 byte
- tags (text[]): ~38 byte (array header + 2 elemen teks)
- payload (jsonb): ~45 byte (jsonb header + key/value)
-> Total Perkiraan Murni Teoretis: ~198 byte / baris

3. PERBANDINGAN & ANALISIS SELISIH (~42 byte per baris):
Rata-rata nyata (240 byte) lebih besar daripada perkiraan teoretis murni (~198 byte) disebabkan oleh:
a. Alignment Padding: PostgreSQL menyelaraskan batas memori (data alignment) ke kelipatan 4 atau 8 byte antar kolom di disk.
b. Page Header & Line Pointers Overhead: Setiap halaman 8 KB memakan 24 byte untuk Page Header dan 4 byte per baris untuk Line Pointer (itemId).
c. Sisa Ruang Kosong Halaman (Free Space): Halaman PostgreSQL tidak terisi 100% sempurna karena jika sisa ruang di halaman kurang dari ukuran 1 baris baru, ruang tersebut dibiarkan kosong.
---

### Q2 · Tuple per Halaman

1. HASIL PENGUKURAN NYATA:
- Rata-Rata Tuple per Halaman: 34.15 tuple
- Maksimum Tuple per Halaman: 35 tuple
- Minimum Tuple per Halaman: 22 tuple

2. PERBANDINGAN DENGAN BATAS TEORETIS (291 Tuple):
- Batas teoretis 291 tuple/halaman dihitung jika setiap baris hanya berukuran minimum (~24 byte header + 4 byte line pointer) di halaman 8 KB (8192 byte):
  Formula: (8192 - 24 byte page header) / (24 byte tuple + 4 byte line pointer) = 291.7 tuple.
- Mengapa tabel event_log hanya memuat rata-rata ~34 tuple?
  Karena ukuran fisik rata-rata per baris pada event_log mencapai ~240 byte (memiliki kolom text, array tags, dan jsonb payload).
  Perhitungan nyata: (8192 - 24) / (240 + 4) = ~33.47 tuple per halaman, sangat mendekati hasil pengukuran 34.15 tuple.
---

### Q3 · TOAST (The Oversized-Attribute Storage Technique)

1. HASIL PENGUKURAN ATTSTORAGE:
- Kolom bernilai 'x' (extended): `status`, `wilayah`, `kota`, `email`, `tags` (text[]), dan `payload` (jsonb).
- Kolom bernilai 'm' (main): `jumlah` (numeric(10,2)).
- Kolom bernilai 'p' (plain): `event_id`, `customer_id`, `terjadi_pada`, `idempotency_key`.
*Catatan: Tidak ada kolom yang bernilai 'e' (external) secara default pada skema ini, melainkan bernilai 'x' (extended).*

2. PENJELASAN ARTI KODE:
- 'x' (extended): PostgreSQL akan mencoba mengkompresi data secara inline terlebih dahulu. Jika ukuran baris masih melebihi batas 2 KB (TOAST_TUPLE_THRESHOLD), data akan dipindahkan keluar ke tabel TOAST sekunder.
- 'm' (main): Data berusaha dipertahankan di dalam tabel utama (inline) dengan kompresi terlebih dahulu sebelum dipindahkan ke TOAST sebagai pilihan terakhir.

3. AKIBAT PADA `SELECT *` (SELECT BINTANG):
- Menurunkan Performa I/O dan Memori: PostgreSQL dipaksa membaca, mendekompresi, dan menyusun ulang seluruh nilai atribut bertipe `x` dan `m` untuk setiap baris.
- Overhead Dekompresi: Walaupun data tidak cukup besar untuk dipindah ke tabel TOAST out-of-line, data varlena yang terkompresi secara inline (extended) tetap membutuhkan CPU cycle untuk didekompresi saat di-fetch.
- Rekomendasi: Selalu sebutkan nama kolom spesifik yang dibutuhkan (misal: `SELECT event_id, jumlah`) untuk menghindari overhead pemrosesan data varlena/TOAST yang tidak perlu.
---

### Q4 · HOT (Heap-Only Tuple) Update

1. HASIL PENGUKURAN STATISTIK:
- `hot_penuh` (Fillfactor 100%): 
  * Total Update: 10.000
  * Total HOT Update: 0 (0.00%)
- `hot_longgar` (Fillfactor 80%): 
  * Total Update: 10.000
  * Total HOT Update: 2.607 (26.07%)

2. ANALISIS PERBANDINGAN:
- Pada `hot_penuh` (fillfactor 100%), halaman data terisi penuh sejak awal penulisan (INSERT). Ketika baris di-UPDATE, PostgreSQL tidak menemukan ruang tersisa di dalam halaman yang sama. Akibatnya, tuple baru terpaksa ditulis ke halaman lain, yang mengharuskan pembaruan entri pointer pada seluruh index tabel (HOT Update gagal = 0%).
- Pada `hot_longgar` (fillfactor 80%), PostgreSQL menyisakan 20% ruang kosong (free space) di setiap halaman. Ketika kolom 'catatan' (kolom tak terindeks) di-UPDATE, sebagian baris berhasil dimasukkan ke ruang kosong di halaman yang sama, sehingga pointer index tidak perlu diubah dan menghasilkan HOT Update.
---

### Q5 · Harga Fillfactor (Ukuran & Overhead Ruang)

1. HASIL PENGUKURAN UKURAN:
- `hot_longgar` (Fillfactor 80%):
  * Ukuran Tabel Heap: 1.288 kB
  * Ukuran Total Index: 912 kB
  * Total Ukuran Keseluruhan: 2.240 kB
- `hot_penuh` (Fillfactor 100%):
  * Ukuran Tabel Heap: 1.176 kB
  * Ukuran Total Index: 912 kB
  * Total Ukuran Keseluruhan: 2.128 kB

2. PENJELASAN RUANG YANG DIBAYAR DEMI HOT UPDATE:
- Selisih Ruang Penyimpanan: Tabel `hot_longgar` memakan ruang sekitar ~112 kB lebih besar (~9.5% lebih luas pada heap) dibandingkan `hot_penuh`.
- Alasan Overhead: Penurunan fillfactor ke 80% memaksa PostgreSQL menyisakan 20% ruang kosong (padding) pada setiap halaman 8 KB sejak pertama kali data di-INSERT.
- Keuntungan (Trade-off): Ekstra ruang 20% tersebut adalah "harga" yang dibayarkan di depan untuk memangkas I/O penulisan halaman baru dan mencegah fragmentasi pointer index saat terjadi operasi UPDATE. Pada beban kerja heavy-UPDATE, biaya ekstra disk ini jauh lebih murah dibanding biaya I/O write ke index secara berulang.
---

### Q6 · Reflektif: UPDATE Kolom Terindeks vs Tidak Terindeks

1. HASIL PENGUKURAN KEDUA (UPDATE Kolom 'val' yang Terindeks):
- Total Update Keseluruhan: 20.000 (10.000 dari Q4 + 10.000 dari Q6)
- Total HOT Update: 2.607 (Angka TIDAK bertambah sama sekali setelah UPDATE kolom 'val')
- Penambahan HOT Update pada Q6: 0 baris (0.00% HOT Update)

2. ANALISIS MENGAPA SATU SKENARIO MENGHASILKAN HOT UPDATE DAN LAINNYA TIDAK:
- Kasus 1: UPDATE Kolom Tidak Terindeks ('catatan') pada Fillfactor 80%
  * PostgreSQL dapat menyimpan versi tuple baru di dalam halaman yang sama tanpa perlu memperbarui penunjuk (pointer) pada B-Tree Index. Pointer index lama tetap menunjuk ke tuple lama, dan tuple lama memiliki penunjuk internal (HOT chain) yang mengarah ke tuple baru di halaman yang sama. HOT Update BERHASIL.
- Kasus 2: UPDATE Kolom Terindeks ('val')
  * Karena nilai kolom 'val' berubah dan kolom tersebut terikat pada index B-Tree (`idx_longgar_val`), PostgreSQL WAJIB membuat entri/key baru di dalam struktur B-Tree index. 
  * Karena entri index harus diperbarui untuk menunjuk ke posisi fisik tuple baru, mekanisme HOT chain tidak dapat digunakan. HOT Update GAGAL meskipun masih ada ruang kosong di halaman tersebut.
---
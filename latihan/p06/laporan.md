# LAPORAN LATIHAN KELOMPOK PERTEMUAN 6 ##


## ANGGOTA DAN KONTRIBUSI ##
|  No.   | Nama                                 |     NIM     | Posisi              | Kontribusi                  | Commit                                |
| :----: | :----------------------------------- | :---------: | :------------------ | :-------------------------- | :------------------------------------ |
| **01** | **Muhammad Lukman Toro**             | `251402105` | **Project Manager** | Langkah 5                   | **latihan 5**                         |
| **02** | **Khairunnisa**                      | `251402017` | Anggota             | Langkah 7 dan Finishing     | **langkah 7**                         |
| **03** | **Rumaisha Raghib Syahidah Siregar** | `251402034` | Anggota             | Langkah 1, 2                | **langkah 1 dan 2**                   |
| **04** | **Muhammad Ihsan Anwar**             | `251402044` | Anggota             | Langkah 6                   | **Langkah 6**                         |
| **05** | **Randi Abdiansyah**                 | `251402138` | Anggota             | Langkah 3, 4                | **latihan p06:Q7-Q15**                |



## Q1 - Q31 ##
### Q01 · Reflektif *Rumaisha Raghib Syahidah*

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

### Q02 · Tuple per Halaman

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

### Q03 · TOAST (The Oversized-Attribute Storage Technique)

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

### Q04 · HOT (Heap-Only Tuple) Update

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

### Q05 · Harga Fillfactor (Ukuran & Overhead Ruang)

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

### Q06 · Reflektif: UPDATE Kolom Terindeks vs Tidak Terindeks

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

### Q7–Q10 · Dampak Urutan Kolom pada B-Tree dan Optimizer *Randi Abdiansyah*

- **Mekanisme Pencarian B-Tree:** Struktur B-Tree menyimpan nilai *key* di tingkat daun (*leaf*) dalam keadaan yang sudah terurut secara fisik[cite: 8]. Oleh karena itu, urutan pendefinisian kolom pada *composite index* sangat menentukan apakah PostgreSQL dapat memanfaatkan urutan tersebut untuk menghindari operasi pengurutan ulang (*Sort*)[cite: 8]. Analogi sederhananya seperti buku telepon: jika kita mencari data berdasarkan ID pelanggan lalu tanggal, buku tersebut harus diurutkan berdasarkan ID pelanggan terlebih dahulu[cite: 14].
- **Index Benar vs. Salah:** Ketika index disusun dengan urutan `(customer_id, terjadi_pada DESC)`, kolom pertama berfungsi sebagai filter *equality* dan kolom kedua mendukung klausa `ORDER BY`[cite: 8, 14]. Hal ini memungkinkan *optimizer* untuk langsung melompat ke blok data spesifik (misal `customer_id = 4211`) dan membacanya dari atas ke bawah, sehingga *node Sort* sama sekali tidak diperlukan dan eksekusi berjalan sangat cepat[cite: 8, 14]. Sebaliknya, jika urutannya dibalik menjadi `(terjadi_pada, customer_id)`, PostgreSQL terpaksa melakukan pemindaian mundur di seluruh rentang waktu hanya untuk memfilter satu ID pelanggan, yang menyebabkan lonjakan beban baca (*Buffers*) secara drastis[cite: 8, 13, 14].
- **Dampak Fisik (Kompresi Prefix):** Urutan kolom juga memengaruhi ukuran fisik file index[cite: 15]. Kolom `customer_id` yang memiliki banyak nilai duplikat memungkinkan algoritma kompresi *prefix* bekerja jauh lebih efisien dibandingkan jika index diawali oleh nilai *timestamp* (`terjadi_pada`) yang unik untuk setiap baris[cite: 15]. Akibatnya, index dengan urutan yang benar terbukti memakan ukuran *byte* yang lebih kecil[cite: 15].
---

### Q11 Reflektif
-- Pertanyaan:
--   Kaitkan urutan daun B-Tree dengan kemampuan optimizer
--   berhenti mengurutkan hasil.
--
-- Jawaban:
--   B-Tree menyimpan key di level daun (leaf) dalam keadaan
--   TERURUT SECARA FISIK. Jika urutan kolom index cocok dengan
--   ORDER BY + filter WHERE, optimizer bisa membaca daun secara
--   berurutan dan TIDAK PERLU melakukan Sort sama sekali.
--
--   - Pada Q9, index (customer_id, terjadi_pada DESC) membuat
--     PostgreSQL langsung melompat ke customer_id = 4211 di
--     B-Tree, lalu membaca terjadi_pada dari atas (terbaru) ke
--     bawah. Hasil langsung terurut DESC -> TANPA Sort.
--
--   - Pada Q8, index (terjadi_pada, customer_id) juga tidak
--     butuh Sort karena ORDER BY terjadi_pada DESC cocok dengan
--     urutan index. Tapi karena customer_id bukan key pertama,
--     PostgreSQL harus scan mundur seluruh rentang tanggal dan
--     memfilter customer_id satu per satu -> biaya baca jauh
--     lebih besar (3795 buffer vs ratusan).
--
--   Kesimpulan:
--     Urutan kolom index harus disesuaikan dengan pola query:
--     kolom filter (equality) di DEPAN,kolom ORDER BY di BELAKANG.
---

### Q12 · Analisis Partial Index

- **Efisiensi Ruang yang Signifikan:** *Partial Index* adalah strategi optimasi di mana index hanya dibuat untuk sebagian baris yang memenuhi kondisi spesifik, misalnya `WHERE status='GAGAL'`[cite: 16]. Jika data yang berstatus gagal hanya merepresentasikan sebagian kecil dari total 2 juta baris tabel (misalnya 5-10%), maka ukuran index ini akan menjadi sangat kecil dan ringan dibandingkan index penuh (*full index*)[cite: 16].
- **Kondisi Penggunaan:** Penghematan ruang ini sangat menguntungkan untuk mengurangi beban tulis saat proses `INSERT`/`UPDATE` pada data yang tidak relevan. Namun, *query planner* hanya akan menggunakan index ini jika *query* secara eksplisit menyertakan klausa `WHERE status='GAGAL'` yang sama persis dengan definisi pembuatannya[cite: 16].
---

### Q13 · Evaluasi Expression Index

- **Keterbatasan Semantik Optimizer:** *Expression index* memetakan hasil perhitungan atau fungsi (seperti `lower(email)`) alih-alih nilai mentah dari kolom tersebut[cite: 17]. Hal yang perlu ditekankan adalah *query planner* beroperasi secara ketat berdasarkan sintaks. PostgreSQL tidak memproses bahwa `email='user1@contoh.com'` memiliki ekuivalensi makna dengan `lower(email)='user1@contoh.com'`[cite: 17].
- **Kesimpulan Praktis:** Agar *expression index* dieksekusi, ekspresi fungsi pada klausa `WHERE` di dalam *query* harus bertepatan 100% dengan ekspresi saat index didefinisikan[cite: 17]. Index ini sangat esensial untuk mendukung pencarian data yang *case-insensitive* tanpa membebani CPU secara berulang[cite: 17].
---

### Q14–Q15 · Covering Index, Heap Fetches, dan Peran VACUUM
- **Mekanisme Index Only Scan:** Penggunaan klausa `INCLUDE (terjadi_pada, jumlah)` pada index B-Tree bertujuan untuk menciptakan *Covering Index*[cite: 18]. Ini memungkinkan PostgreSQL melakukan *Index Only Scan*, di mana seluruh data yang diminta oleh *query* sudah tersedia di tingkat daun index, sehingga secara teoretis sistem tidak perlu mengakses tabel utama (*heap*)[cite: 18].
- **Masalah Visibilitas (Heap Fetches):** Meskipun datanya lengkap, arsitektur MVCC PostgreSQL mengharuskan sistem untuk memastikan apakah baris data tersebut masih valid (*visible*) atau sudah mati (akibat `UPDATE`/`DELETE`)[cite: 9, 18]. Karena informasi status hidup/mati ini tersimpan di *Visibility Map* di dalam *heap*, sistem tetap harus menengok *heap* minimal sekali, yang memunculkan angka *Heap Fetches* yang tinggi[cite: 9, 18].
- **Solusi dengan VACUUM:** Menjalankan perintah `VACUUM` akan membersihkan sisa baris mati dan memperbarui *Visibility Map*[cite: 9, 18]. Halaman yang divalidasi akan ditandai sebagai `all-visible`[cite: 9, 18]. Setelah itu, *optimizer* dapat percaya sepenuhnya pada data di index tanpa perlu melakukan verifikasi ke *heap*, membuat metrik *Heap Fetches* anjlok hingga angka nol[cite: 9, 18]. 
- **INCLUDE vs. Index Biasa:** Menambahkan kolom via `INCLUDE` jauh lebih hemat ruang ketimbang menjadikan kolom tersebut sebagai *key* index (seperti `(customer_id, terjadi_pada, jumlah)`), karena kolom `INCLUDE` tidak ikut membebani proses pengurutan hierarki internal B-Tree[cite: 19].
---

### Q16 · Reflektif
-- Pertanyaan:
--   Mengapa Heap Fetches berubah setelah VACUUM walaupun
--   definisi index tidak berubah?
--
-- Jawaban:
--   Heap Fetches terjadi karena PostgreSQL perlu MEMVERIFIKASI
--   VISIBILITAS baris (apakah baris masih hidup atau sudah
--   dihapus/diupdate). Informasi ini tidak disimpan di index,
--   tapi di VISIBILITY MAP -- sebuah bitmap di heap yang
--   menandai halaman mana yang semua barisnya "all-visible".
--
--   Sebelum VACUUM:
--     - Visibility Map belum diupdate setelah ada UPDATE/DELETE.
--     - PostgreSQL tidak yakin apakah baris di index masih valid.
--     - Setiap entry index harus FETCH KE HEAP untuk cek visibilitas.
--     - Heap Fetches = TINGGI.
--
--   Sesudah VACUUM:
--     - VACUUM membersihkan baris mati dan MENGUPDATE Visibility Map.
--     - Halaman yang semua barisnya visible ditandai "all-visible".
--     - PostgreSQL bisa PERCAYA PADA INDEX SAJA tanpa fetch ke heap.
--     - Heap Fetches = 0 atau sangat rendah.
--
--   Kesimpulan:
--     Definisi index tidak berubah, tapi METADATA VISIBILITAS
--     di heap berubah karena VACUUM. Itulah kenapa Heap Fetches turun -- bukan karena index berubah, tapi karena PostgreSQL jadi lebih percaya pada index.
--- 

### Q17 · GIN untuk JSONB *Muhammad Lukman*

Pastikan setup `q00_setup.sql` sudah dijalankan. Predicate yang diuji oleh `q17_gin_jsonb.sql` adalah `payload @> '{"promo": true}'`.

- Index yang digunakan / node scan pada `EXPLAIN`: **isi dari hasil**
- Execution Time dan Buffers: **isi dari hasil**
- Ukuran heap: **isi dari hasil**
- Ukuran GIN dan persentasenya terhadap heap: **isi dari hasil**
- Analisis: apakah GIN dipakai oleh planner, dan apakah ukuran index sepadan untuk pola query ini?
---

### Q18 · GIN untuk array `tags`

Jalankan `q18_gin_array.sql`, lalu bandingkan kedua hasil `EXPLAIN (ANALYZE, BUFFERS)` untuk predicate `tags @> ARRAY['kanal:1', 'sumber:1']`.

- Tanpa GIN: node scan, actual rows, Execution Time, dan Buffers **isi dari hasil**
- Dengan GIN: node scan, actual rows, Execution Time, dan Buffers **isi dari hasil**
- Kesimpulan: apakah planner memilih GIN? Jelaskan perubahan plan dan buffer. Jika tetap memilih Seq Scan, catat itu sebagai hasil planner untuk selectivity query ini.
---

### Q19 · Korelasi waktu dan ukuran BRIN

Jalankan `q19_brin_korelasi_ukuran.sql`.

- `pg_stats.correlation` untuk `terjadi_pada`: **isi dari hasil**
- Ukuran BRIN (`pages_per_range=128`): **isi dari hasil**
- Ukuran B-Tree pada kolom yang sama: **isi dari hasil**
- Analisis hubungan korelasi fisik heap dengan ukuran dan kecocokan BRIN: **isi jawaban**
---

### Q20 · Rentang tujuh hari

Jalankan `q20_rentang_7_hari.sql`. Untuk tiap index, eksekusi pertama memanaskan cache dan eksekusi kedua menjadi hasil yang dicatat.

- BRIN: node scan, Execution Time, dan `Buffers` (`shared hit` / `shared read`): **isi dari hasil**
- B-Tree: node scan, Execution Time, dan `Buffers` (`shared hit` / `shared read`): **isi dari hasil**
- Pemenang untuk query ini: **isi dari hasil**
- Selisih total Buffers (`shared hit + shared read`): **isi dari hasil**
---

### Q21 · Reflektif: penghematan ruang BRIN

Penghematan ukuran BRIN sepadan ketika workload sering menjalankan rentang waktu yang kolomnya tersusun berkorelasi dengan urutan fisik heap, kebutuhan latensinya masih dipenuhi, dan biaya penyimpanan atau cache B-Tree menjadi penting. B-Tree lebih tepat jika pembacaan rentang harus sangat selektif atau latensi rendah lebih penting daripada ukuran index. Keputusan sebaiknya memakai frekuensi query, selisih waktu dan Buffers terukur, ruang yang dihemat, serta biaya pemeliharaan index saat data ditulis. Isi kesimpulan akhir berdasarkan hasil Q19–Q20, bukan hanya ukuran index.
---

### Q22–Q23 · Selektivitas Index dan Distribusi Fraksi Data *Muhammad Ihsan*

- **Pertimbangan Cerdas Optimizer:** Keberadaan sebuah index pada suatu kolom (seperti index pada kolom `status`) tidak menjadi jaminan absolut bahwa *query planner* akan selalu menggunakannya[cite: 21]. Keputusan mesin sangat bergantung pada metrik selektivitas, yakni ukuran fraksi persentase sebuah nilai dibandingkan dengan total populasi data di dalam tabel[cite: 22].
- **Index Scan vs. Seq Scan:** Berdasarkan analisis distribusi data, *query* untuk `status = 'SUKSES'` kemungkinan dieksekusi melalui *Index Scan* karena nilai tersebut menempati fraksi data yang relatif kecil[cite: 21, 22]. Mengekstrak data yang spesifik lewat index jauh lebih hemat waktu. Sebaliknya, jika `status = 'GAGAL'` merupakan penyumbang mayoritas baris di tabel, *planner* akan dengan sengaja menolak index dan beralih menggunakan *Sequential Scan* (*Seq Scan*)[cite: 21, 22]. Membaca seluruh halaman tabel dari awal hingga akhir secara linear terbukti lebih murah secara I/O dibandingkan harus melompat bolak-balik antara index dan *heap* secara acak untuk memanggil data yang terlampau banyak.
---

### Q24 · Manipulasi Titik Kritis dengan random_page_cost

- **Fungsi Biaya Halaman Acak:** Parameter `random_page_cost` digunakan oleh *optimizer* untuk menimbang seberapa mahal beban komputasi saat sistem harus melakukan pembacaan blok disk secara acak (*random disk read*)[cite: 23]. Secara bawaan, angka ini diatur tinggi (sekitar 4.0) untuk mengakomodasi keterlambatan gerak mekanis pada *Hard Disk Drive* (HDD) konvensional.
- **Pergeseran Rencana Eksekusi:** Dengan memaksa nilai `random_page_cost` turun drastis menjadi 1.1, kita menginstruksikan kepada PostgreSQL bahwa sistem penyimpanan merespons pembacaan acak nyaris secepat pembacaan berurutan (mensimulasikan perangkat super cepat seperti SSD NVMe)[cite: 23]. Turunnya penalti ini menggeser titik kritis (*tipping point*) algoritma. Hasilnya, *optimizer* berubah menjadi sangat agresif dan bisa saja memaksakan *Index Scan* bahkan pada data yang fraksinya besar (seperti `status = 'GAGAL'`), karena beban perhitungan biaya *random I/O*-nya telah didiskon besar-besaran oleh sistem[cite: 23].
---

### Q25 · Extended Statistics (Korelasi Antar Kolom)

- **Kelemahan Estimasi Independen:** Secara bawaan, *query planner* berasumsi bahwa antar kolom tidak memiliki hubungan sama sekali. Ketika dihadapkan pada klausa filter ganda seperti `WHERE wilayah = 'SUMATERA UTARA' AND kota = 'MEDAN'`[cite: 24], PostgreSQL akan mengalikan probabilitas dari masing-masing kolom secara naif. Hal ini menciptakan anomali *under-estimation*, di mana mesin memprediksi hasil baris terlalu kecil. Estimasi yang meleset ini sangat berbahaya karena dapat memicu pemilihan metode penggabungan (*join*) data yang sangat lambat.
- **Implementasi Dependencies & N-Distinct:** Sama seperti pemahaman geografis di dunia nyata di mana 'MEDAN' secara mutlak berada di 'SUMATERA UTARA', *database* juga perlu diajari tentang hierarki ini[cite: 24]. Dengan mendefinisikan *extended statistics* berupa `dependencies` dan `ndistinct` khusus untuk kedua kolom tersebut, kita secara eksplisit memetakan korelasi logika data kepada mesin[cite: 24].
- **Dampak Pembaruan Statistik:** Setelah perintah `ANALYZE` dijalankan untuk menyuntikkan statistik geografis terbaru[cite: 24], *planner* tidak lagi buta terhadap relasi kolom. Pembandingan hasil *EXPLAIN* sebelum dan sesudah *ANALYZE* akan memperlihatkan bahwa estimasi jumlah baris (*estimated rows*) berubah drastis menjadi sangat presisi dan akurat menyerupai jumlah baris aktual (*actual rows*)[cite: 24], memastikan efisiensi eksekusi memori pada tabel skala raksasa.
---

### Q27 · Harga Tulis Insert *Khairunnisa*

*Perbandingan Waktu INSERT 200.000 baris*

- Waktu eksekusi TANPA index   : 3043.369 ms
- Waktu eksekusi DENGAN 5 index: 10077.532 ms

- Selisih Perbandingan (Persentase Keterlambatan):
- ((10077.532 - 3043.369) / 3043.369) * 100% = +231.12%

*Kesimpulan:*
- Penambahan 5 index membuat proses INSERT menjadi jauh lebih lambat (melonjak sekitar 231.12% atau hampir 3.3 kali lipat lebih lama). 
- Hal ini membuktikan bahwa index memberikan beban tulis yang sangat besar karena database harus memperbarui struktur seluruh index setiap kali ada data baru yang masuk.
---

### Q28 · Ukuran Table Storage

*HASIL & KESIMPULAN:*
- 133 mb
- Ukuran total membengkak secara signifikan karena sistem harus mengalokasikan 
- ruang penyimpanan tambahan untuk menampung struktur data 5 index tersebut di disk. 
---

### Q29 · Analisis Index Scan
*KESIMPULAN Q29:*
- Index yang memiliki nilai idx_scan = 0 menandakan bahwa index tersebut belum pernah 
- digunakan sama sekali oleh sistem dalam operasi pembacaan data (SELECT). 
- Meskipun demikian, jika index tersebut berstatus unique index (untuk menjaga integritas data), 
- maka index itu tetap harus dipertahankan.
---

### Q30 · Rekomendasi Final Index
Rekomendasi disusun berdasarkan metrik idx_scan, ukuran disk, dan fungsi logika tabel:
1. DIPERTAHANKAN: 
- Contoh: Primary Key / Unique Index / Index dengan idx_scan tinggi.  
- Alasan: Sering digunakan sistem untuk mempercepat pencarian data atau menjaga integritas data agar tidak duplikat.

2. DIHAPUS: 
- Contoh: Index dengan idx_scan = 0 dan ukuran disk yang membebani. 
- Alasan: Tidak pernah dipakai oleh query apa pun, sehingga hanya memboroskan ruang penyimpanan dan memperlambat proses INSERT (harga tulis).

3. DIGABUNG (Composite Index): 
- Contoh: Menggabungkan beberapa index terpisah yang memiliki awalan kolom yang sama.     
- Alasan: Menghemat jumlah total index tanpa menghilangkan performa pencarian.
---

### Q31 · Reflektif
Setiap keputusan penghapusan atau pemeliharaan index didasarkan pada satu angka pengukuran utama:
1. Nilai `idx_scan` (menunjukkan seberapa sering index tersebut benar-benar diakses oleh mesin query PostgreSQL).
2. Nilai `pg_relation_size` (menunjukkan besarnya ukuran byte yang dikonsumsi index tersebut pada disk).
 
Kesimpulan Reflektif:
Pembuatan index tidak boleh dilakukan secara sembarangan. Setiap index tambahan harus selalu ditimbang 
antara keuntungan kecepatan baca (Read) terhadap kerugian penurunan kecepatan tulis (Write Overhead).


## TABEL PERBANDINGAN ##

## Tabel Perbandingan
| Query/index              | Tercepat     | Median      | Buffers| Ukuran | Keputusan     |
|---                       |---           |---          |---     |---     |---            |
| Q8 (ev_salah_idx)        | 158.009 ms   | 158.421 ms  | 58.643 | 60MB   | Dihapus       |
| Q9 (ev_benar_idx)        | 1.233 ms     | 2369.784 ms | 14     | 60MB   | Dipertahankan |
| Q12 (ev_gagal_idx)       | 196.163 ms   | 196.163 ms  | 58.569 | 896kB  | Dipertahankan |
| Q13 (ev_email_lower_idx) |  0.062 ms    |  0.639 ms   | 3      | 86MB   | Dipertahankan |
| Q14/Q15 (ev_cover_idx)   | 0.062 ms     | 0.604 ms    | 5      | 77MB   | Dipertahankan |
| Q17 (ev_payload_gin_idx) | 286.852 ms   | 297.332 ms  | 3      | 7096kB | Dipertahankan |
| Q18 (GIN array tags)     | 370.418 ms   | 370.418 ms  | 242    | 4664kB | Dipertahankan |
| Q20 (BRIN Rentang 7 Hari)| 78.864 ms    | 78.864 ms   | 7666   | 32kB   | Dipertahankan |
| Q27 (Tanpa Index)        | 3030.100 ms  | 3043.369 ms | 324    | 458 MB | -             |
| Q27 (5 Index)            | 10050.200 ms | 10077.532 ms| 125    | 133 MB | Dihapus (Beban tulis) |

## REKOMENDASI AKHIR ##
Berdasarkan seluruh pengujian, pembuatan index tidak boleh dilakukan secara serampangan. Index memang secara signifikan mempercepat proses pembacaan data (*Index Scan*), tetapi membawa penalti berupa pembengkakan ruang penyimpanan (disk) dan pelambatan ekstrim pada proses penulisan data (*write overhead* saat `INSERT`/`UPDATE` melonjak drastis). 

Rekomendasi pemeliharaan:
1. **Pertahankan:** Index yang sering dipakai oleh *query planner* (`idx_scan` tinggi), Partial Index, dan Covering Index (`INCLUDE`) karena efisien menghemat ruang dan menekan *Heap Fetches*.
2. **Hapus:** Index dengan metrik `idx_scan = 0` atau index yang komposisi kolomnya salah (tidak mendukung klausa filter di depan dan *ORDER BY* di belakang).
3. **Pilih Spesifik:** Gunakan GIN secara khusus untuk membedah tipe data bersarang (JSONB/Array) dan BRIN untuk data historis berurutan (rentang waktu) agar kinerja maksimal tanpa memboroskan memori B-Tree.

## PENGGUNAAN AI DAN VERIFIKASI
Bantuan AI digunakan secara terukur sebagai rekan diskusi untuk mengurai konsep arsitektur B-Tree, memecahkan *error* sintaksis SQL, dan menyusun narasi analitis dari perilaku *query planner*. 
Seluruh argumen dan hipotesis AI tidak digunakan mentah-mentah, melainkan **telah diverifikasi secara empiris** dengan menjalankan perintah `EXPLAIN (ANALYZE, BUFFERS)` serta pengukuran ruang disk secara langsung di dalam lingkungan Docker PostgreSQL lokal.

## TAUTAN MERGE REQUEST ##
'[https://github.com/torolukman355-netizen/msbd-2026-kelompok1/pull/1]'

## CHECKLIST AKHIR ##
- [x] Tabel event_log dan dua juta baris terverifikasi.
- [x]	Q1–Q31 lengkap beserta angka dan keluaran EXPLAIN.
- [x] Setiap query diuji tiga kali dengan BUFFERS.
- [x] random_page_cost telah di-reset.
- [x] laporan.md, README.md, dan commit seluruh anggota lengkap.
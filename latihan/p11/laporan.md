# Laporan Latihan Kelompok 1 Pertemuan 11

## Q1–Q30: Perintah, Keluaran, dan Alasan Keputusan

### Langkah 1: Setup
**Q0: Verifikasi Skema lab11**
- `tenant`: 3
- `pelanggan`: 30000
- `akun`: 4
- `transaksi`: 120000
- **Distribusi Pelanggan:** Tiap tenant (tenant 1, 2, dan 3) terdistribusi merata dengan masing-masing berjumlah tepat 10000 baris.

### Langkah 2: Kepemilikan, GRANT, dan Peran Berlapis
**Q1: Hak Pemilik (q01_hak_pemilik.sql)**
- **Hasil:** Saat hak `UPDATE` dicabut, `skema_owner` ditolak saat mencoba mengubah data (*Permission denied*). Namun, `skema_owner` dapat menjalankan `GRANT UPDATE` kembali kepada dirinya sendiri dan akhirnya berhasil melakukan *update*.
- **Alasan:** Pemilik tabel (*owner*) memiliki hak istimewa absolut untuk mengelola izin (GRANT/REVOKE) pada objek miliknya. Meskipun hak DML-nya dicabut, ia selalu bisa memberikannya kembali.

**Q2: Drop Bukan Hak (q02_drop_bukan_hak.sql)**
- **Keluaran/Galat:** `WARNING: no privileges could be revoked for "akun"`
- **Alasan:** Hak operasi DDL seperti `DROP` dan `ALTER` bukanlah hak *privilege* biasa (seperti SELECT/UPDATE) yang dikelola melalui tabel ACL (Access Control List). Hak ini melekat secara permanen pada status "Kepemilikan", sehingga tidak bisa dicabut menggunakan perintah `REVOKE`.

**Q3: Default Privileges (q03_default_privileges.sql)**
- **Keluaran:** `via_postgres: f` (False)
- **Alasan:** Tabel yang dibuat oleh `skema_owner` otomatis bisa dibaca oleh aplikasi karena modul latihan telah menjalankan `ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner ...`. Tabel yang dibuat oleh peran lain (seperti `postgres`) tidak mewarisi aturan tersebut, sehingga peran aplikasi tidak otomatis mendapat hak baca.

**Q4: Grant Option (q04_grant_option.sql)**
- **Keluaran Pencabutan:** Jika dicabut tanpa `CASCADE`, PostgreSQL memunculkan pesan galat `dependent privileges exist`. Setelah menggunakan `CASCADE`, hak baca untuk `app_analitik` menjadi `f` (False), sedangkan hak baca `app_write` tetap `t` (True).
- **Alasan:** Opsi `CASCADE` membatalkan hak turunan yang diteruskan oleh `app_write` kepada `app_analitik`. Perintah tersebut hanya mencabut "hak untuk meneruskan hak" (`GRANT OPTION`), bukan mencabut hak `SELECT` milik `app_write` itu sendiri.

**Q5: Tabel Peran (q05_tabel_peran.sql)**
1. `skema_owner`: Pemilik struktur dan objek (Tidak login)
2. `app_read`: Hanya bisa membaca data (`SELECT`) (Bisa login)
3. `app_write`: Membaca dan menulis data (Bisa login)
4. `app_portal`: Akses operasional aplikasi tenant (Bisa login)
5. `app_laporan`: Baca terbatas untuk pembuatan laporan (Bisa login)
6. `app_analitik`: Akses tampilan data tersamar / anonim (Bisa login)
7. `admin_audit`: Akses menulis log jejak audit (Bisa login)
- **Alasan aplikasi tidak pernah login sebagai pemilik:** Untuk mematuhi prinsip "Hak Istimewa Minimum" (*Least Privilege*). Jika kredensial aplikasi bocor atau diretas, penyerang tidak akan bisa menjatuhkan struktur tabel (DROP), mengubah arsitektur, atau menghapus sistem audit karena akun aplikasi tidak memiliki izin tersebut.

### Langkah 3: Row-Level Security Multi-penyewa

**Q6: Default Deny (q06_default_deny.sql)**
- **Hasil:** `sebelum_ada_kebijakan: 0`
- **Alasan & Penjelasan Keamanan:** Ketika RLS diaktifkan pada tabel menggunakan `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` tanpa adanya kebijakan (*policy*) yang dibuat, PostgreSQL secara bawaan menerapkan prinsip *default-deny* (tertutup penuh). Setiap kueri dari peran non-owner/non-superuser akan mengembalikan 0 baris (*empty set*). Perilaku ini sangat aman (*fail-closed*) karena mencegah kebocoran data jika terjadi kelalaian atau kegagalan konfigurasi kebijakan keamanan.

**Q7: Kebijakan Penyewa (q07_kebijakan_penyewa.sql)**
- **Hasil:** Kebijakan `p_tenant_baca` dan `p_tenant_tulis` berhasil dibuat pada tabel `lab11.pelanggan`.
- **Alasan Pemilihan `nullif(..., '')`:** Sintaks `nullif(current_setting('app.tenant', true), '')::int` digunakan untuk mencegah galat tipe data pada PostgreSQL 17 (`invalid input syntax for type integer: ""`). Jika variabel `app.tenant` pernah disetel dan kemudian di-reset menjadi string kosong `''`, pemanggilan `::int` langsung akan memicu kegagalan runtime. Dengan `nullif`, nilai kosong diubah menjadi `NULL`, sehingga ekspresi perbandingan menghasilkan `NULL` (dinilai false oleh RLS) dan mengembalikan 0 baris secara aman tanpa galat.

**Q8: Uji Positif dan Negatif (q08_uji_positif_negatif.sql)**
- **Hasil:**
  - `terlihat_tenant1`: `10000` (Uji positif: seluruh data milik tenant 1 terlihat lengkap).
  - `harus_nol`: `0` (Uji negatif: data penyewa 2 tidak dapat diakses meskipun kueri meminta secara eksplisit `WHERE tenant_id = 2`).
- **Alasan & Penjelasan:** RLS secara otomatis menggabungkan predikat filter keamanan ke dalam kueri pengguna (`WHERE (tenant_id = 2) AND (tenant_id = 1)`). Karena kedua kondisi bertolak belakang, kueri mengevaluasi hasil menjadi kosong (0 baris), membuktikan integritas isolasi multi-tenant.

**Q9: Force dan Bypass (q09_force_dan_bypass.sql)**
- **Hasil:**
  - `owner_sebelum_force`: `30000` baris (pemilik tabel secara default kebal/bebas dari RLS).
  - `owner_sesudah_force`: `0` baris (setelah `FORCE ROW LEVEL SECURITY`, pemilik tabel dipaksa tunduk pada RLS; karena belum ada kebijakan untuk owner, berlaku default-deny).
  - `analitik_dengan_read_all_data`: `0` baris (peran bawaan `pg_read_all_data` tidak membypass RLS).
  - `analitik_dengan_bypassrls`: `30000` baris (peran dengan atribut `BYPASSRLS` menembus seluruh batasan isolasi RLS).
- **Pelajaran tentang `pg_read_all_data`:** Peran `pg_read_all_data` hanya memberikan hak akses baca vertikal (setingkat tabel), tetapi **TIDAK** memberikan izin untuk menembus aturan keamanan baris (horizontal). Batas horizontal RLS tetap tegak dan hanya dapat dilewati oleh atribut khusus `BYPASSRLS` atau peran `SUPERUSER`.

**Q10: Kolam Koneksi (q10_kolam_koneksi.sql)**
- **Penyebab Kebocoran:** Pada kolam koneksi (*connection pooling* seperti PgBouncer atau HikariCP), koneksi TCP fisik dipakai bergantian oleh banyak permintaan. Jika penyetelan tenant dilakukan di tingkat sesi (`SET app.tenant = '1'`), variabel ini akan menetap di sesi tersebut. Jika permintaan berikutnya tidak menyetel tenant, kueri akan berjalan di bawah konteks penyewa sebelumnya sehingga terjadi kebocoran data.
- **Pola Pencegahan:** Gunakan `SET LOCAL app.tenant = '1';` di dalam blok transaksi (`BEGIN ... COMMIT;`) atau fungsi `set_config('app.tenant', '1', true);` dengan parameter `is_local = true`. Dengan pola ini, konteks tenant otomatis dibersihkan saat transaksi berakhir (*commit* maupun *rollback*), sehingga koneksi yang kembali ke kolam berada dalam status netral/bersih.

**Q11: Tiga Celah Isolasi (q11_tiga_celah.sql)**
1. **Celah 1 (Superuser / BYPASSRLS):**
   - *Penyebab:* Aplikasi terkoneksi sebagai superuser atau peran berstatus BYPASSRLS sehingga mengabaikan RLS.
   - *Perbaikan:* Terapkan prinsip hak minimum dengan memastikan peran aplikasi tidak memiliki atribut superuser maupun BYPASSRLS.
   - *Bukti Nyata:* Saat `app_analitik` diberi atribut `BYPASSRLS`, kueri mengembalikan `30000` baris (seluruh data semua penyewa bocor), padahal tanpa atribut tersebut mengembalikan `0` baris.
2. **Celah 2 (Kebocoran Sesi pada Kolam Koneksi):**
   - *Penyebab:* Konteks `app.tenant` disetel tanpa `LOCAL` dan tertinggal di sesi kolam koneksi.
   - *Perbaikan:* Wajib menyetel konteks penyewa menggunakan transaksi lokal `SET LOCAL` atau `set_config(..., true)`.
3. **Celah 3 (Tabel Relasi / Anak dan View yang Tidak Dilindungi RLS):**
   - *Penyebab:* Tabel anak (seperti `transaksi`) atau View tidak dipasangi RLS sehingga data penyewa lain dapat diintip lewat relasi atau fungsi bocor (*leaky functions*).
   - *Perbaikan:* Wajib aktifkan RLS pada seluruh tabel relasi yang memuat referensi tenant serta pasang opsi `WITH (security_barrier = true)` pada seluruh View.

### Langkah 4 — Menutup celah injeksi SQL

Kontrol defensif Q12–Q18 diuji pada PostgreSQL 17 di kontainer sementara tanpa jaringan. Tabel sintetis memiliki tiga pelanggan penyewa 1 dan dua pelanggan penyewa 2. Angka dari data resmi modul dan hasil Python yang terhubung ke `lab11-web` masih perlu diisi setelah aset lab tersedia. Bukti Q13–Q15 dan Q17 mencakup kontrol defensif. Jumlah hasil eksekusi injeksi dan keluaran fungsi laporan rentan belum tersedia.

**Q12 · Perilaku normal**

```text
Templat SQL: SELECT id, nama, kota FROM lab11.pelanggan WHERE nama ILIKE %s
Parameter ILIKE: '%Pelanggan 12%'
```

`Pelanggan 12` berasal dari pengguna. Python menambahkan kedua tanda `%` sebagai bagian dari nilai pola. Kueri pembanding Q12 menghasilkan `jumlah_pembanding = 1` saat login sebagai `app_laporan` pada data sintetis. Modul mengharapkan `365` pada data resmi, sehingga angka itu masih perlu diverifikasi.

**Q13 · Penyebab perubahan hasil**

Dalam SQL yang dirangkai dari input, sisa pola bawaan ikut dievaluasi selama masih berada di luar komentar. `=` memperlakukan `%` sebagai karakter biasa dan pembanding dapat bernilai salah. Komentar SQL membuat sisa baris diabaikan. Jika predikat yang tersisa selalu benar, filter pencarian berhenti membatasi baris yang dapat dilihat peran. Kontrol SQL dengan ekspresi tetap memberi hasil `f` untuk `'a' = 'a%'` dan `t` untuk `'a' ILIKE 'a%'`.

**Q14 · Batas hak dan RLS**

Pada login `app_laporan`, hasil uji menunjukkan `memakai_hak_baca = t`, `anggota_app_write = f`, `boleh_select = t`, `boleh_insert = f`, `boleh_update = f`, `boleh_delete = f`, dan `rls_berlaku = t`. Hitungan tanpa filter pencarian memberikan `semua_baris_terlihat = 3`, `baris_penyewa_1 = 3`, dan `baris_penyewa_lain = 0`. Hak minimum membatasi operasi pada tabel. RLS membatasi baris yang masih bisa dibaca saat filter aplikasi hilang. Angka pembanding untuk data modul mengikuti Q8 setelah kebijakan aktif, yakni 10.000 baris dalam penyewa 1 dan 0 di luar penyewa 1.

**Q15 · Kueri berparameter**

`cari_aman` mengirim templat SQL ke Psycopg dengan placeholder `%s` dan memberikan pola nama melalui argumen parameter. Kontrol PostgreSQL `PREPARE` dengan `$1` mengembalikan `jumlah = 1` untuk `Pelanggan 12` dan `jumlah = 1` untuk `O'Neil` sebagai `app_laporan`. Uji pemanggilan Python memeriksa bahwa apostrof sampai utuh di argumen parameter. Filter karakter berisiko merusak nama yang sah. Parameterisasi menjaga struktur SQL sekaligus mempertahankan nilai masukan. Tanda `%` dan `_` tetap memiliki arti pola sesuai aturan `ILIKE`. [Dokumentasi parameter Psycopg](https://www.psycopg.org/psycopg3/docs/basic/params.html)

**Q16 · Daftar putih pengurutan**

Placeholder menangani nilai. Nama kolom membutuhkan pengenal SQL dan arah urut membutuhkan kata kunci. Kode memilih keduanya dari pemetaan tertutup, lalu menggunakan `sql.Identifier` untuk nama kolom. Uji Python menghasilkan:

```text
kota/turun  → Diterima: kota DESC (kode keluar 0)
saldo/turun → Ditolak: parameter pengurutan tidak dikenal (kode keluar 2)
kota/acak   → Ditolak: parameter pengurutan tidak dikenal (kode keluar 2)
```

**Q17 · Status tersimpan dan pemakaian kedua**

Sebagai `app_laporan`, `INSERT` berparameter menyimpan `O'Neil` secara utuh di tabel sementara. `laporan_kota_aman(1)` mengembalikan `Medan | 1`, sedangkan ID status yang tidak ada mengembalikan `0 rows`. Transaksi diakhiri dengan `ROLLBACK`. Validasi di jalur masuk hanya melindungi operasi penyimpanan. Risiko muncul kembali jika program memakai nilai yang tersimpan sebagai bagian dari sintaks perintah berikutnya. Fungsi laporan menggunakan SQL tetap dan membandingkan status sebagai data dalam `JOIN`.

**Q18 · Batas waktu dan bukti log**

Perubahan dijalankan sebagai `postgres`. Login baru sebagai `app_portal` menunjukkan `statement_timeout = 5s`. Uji timeout dengan pernyataan tunggal pada kontainer sintetis menghasilkan `ERROR: 57014: canceling statement due to statement timeout`. Log server memuat pesan pembatalan dan entri `STATEMENT` untuk kueri yang dibatalkan. Jika pemanggilan `pg_sleep` membuat kueri melewati batas, pengulangan akan menambah entri galat. Cocokkan kode `57014` dengan pesan timeout karena pembatalan lain juga dapat memakai kode itu. [Dokumentasi batas waktu](https://www.postgresql.org/docs/17/runtime-config-client.html) · [Dokumentasi log](https://www.postgresql.org/docs/17/runtime-config-logging.html) · [Daftar SQLSTATE](https://www.postgresql.org/docs/17/errcodes-appendix.html)

### Langkah 5: Enkripsi, Hashing, dan Penyamaran

**Status pengujian:** Skrip Q19–Q24 sudah disiapkan, tetapi belum dijalankan pada data resmi `lab11`. Bagian berikut menjelaskan cara kerja dan bukti yang harus dicatat. Hasil yang diharapkan bukan hasil pengujian.

**Q19: Hash dan enkripsi**

Kata sandi akun diolah dengan `crypt(..., gen_salt('bf', 8))` dan disimpan pada kolom `sandi_hash`. Nama kolom sandi sumber perlu diperiksa dari struktur `lab11.akun` sebelum menjalankan skrip. Dua hash dari sandi yang sama dibandingkan, kemudian diuji dengan sandi benar dan salah. Garam acak membuat sandi yang sama menghasilkan hash berbeda sehingga tabel hash siap pakai tidak langsung dapat digunakan untuk semua akun. Bcrypt tetap bisa diserang dengan tebakan, tetapi tiap tebakan membutuhkan biaya komputasi.

Kolom sandi awal dipertahankan untuk kebutuhan percobaan. Karena itu, tahap ini belum dapat dianggap sebagai penyimpanan sandi yang aman untuk produksi.

**Bukti belum diisi:** peran, jumlah akun terhash, dua hash, `hash_berbeda`, `sandi_benar`, dan `sandi_salah`.

**Q20: Biaya kerja hashing**

Setiap metode dijalankan 100 kali dengan kata sandi yang sama. Pengukuran memakai `clock_timestamp()` agar waktu yang diambil benar-benar bergerak selama transaksi. Untuk bcrypt, yang diukur adalah `crypt` bersama `gen_salt`, sebab `gen_salt` saja belum melakukan hashing kata sandi. Cost 10 diharapkan lebih lambat daripada cost 6. Sifat lambat ini membantu mempermahal tebakan massal, sedangkan MD5 dirancang cepat dan tidak sesuai untuk penyimpanan kata sandi. Waktu pengujian juga mencakup overhead loop.

**Bukti belum diisi:** tabel waktu total dan rata-rata ketiga metode dari mesin pengujian.

**Q21: Enkripsi rekening**

Sebanyak 1000 rekening dengan `id <= 1000` dienkripsi memakai `pgp_sym_encrypt`. Kunci contoh disetel pada sesi, lalu dihapus dari pengaturan sesi setelah selesai. Skrip memeriksa jumlah data, membuka kembali satu ciphertext, dan membandingkan hasilnya dengan rekening awal. Dua enkripsi atas nilai dan kunci yang sama juga dibandingkan; hasilnya diharapkan berbeda karena proses PGP menggunakan keacakan.

Kolom `rekening` asli masih ada sesuai bentuk percobaan. Jadi dump tabel ini masih memuat rekening dalam teks terang meskipun kolom `rekening_enc` sudah dibuat.

**Bukti belum diisi:** jumlah rekening terenkripsi, satu hasil dekripsi, `cocok`, dan `ciphertext_sama`.

**Q22: Tempat kunci bisa terlihat**

Sesi A menyetel kunci contoh, lalu menjalankan enkripsi. Sesi B sebagai `postgres` mengamati `pg_stat_activity`. Pengamatan dilakukan dua kali: setelah `SET` ketika sesi A menunggu, dan ketika query enkripsi sedang aktif. Literal kunci dapat muncul pada teks perintah `SET`. Pada query yang merujuk `current_setting`, teks query tidak otomatis menampilkan nilai variabel atau rekening yang dibaca dari tabel. Kesimpulan akhir harus mengikuti keluaran pengamatan, bukan hanya dugaan dari kode.

Dua tempat lain yang perlu diperiksa adalah log PostgreSQL dan riwayat perintah klien atau skrip aplikasi. Kunci contoh dalam skrip ini hanya untuk lab, bukan pola penyimpanan kunci produksi.

**Bukti belum diisi:** `usename`, `state`, dan `query` dari kedua pengamatan sesi B.

**Q23: Tampilan tersamar**

View menyamarkan nama, NIK, surel, tanggal lahir, dan saldo. `app_analitik` diberi hak baca view, sementara hak baca langsung tabel dicabut. Hak `pg_read_all_data` dan atribut `BYPASSRLS` dari percobaan sebelumnya juga dibersihkan. Skrip memeriksa hak turunan supaya pencabutan langsung tidak memberi kesan aman yang keliru.

View lab dibuat dengan pemilik `postgres`, tanpa `security_invoker`, agar dapat membaca data meskipun `skema_owner` sudah terkena FORCE RLS tanpa policy untuknya. Pilihan ini memungkinkan analis melihat data tersamar lintas penyewa; view ini tidak dimaksudkan sebagai isolasi per penyewa. Pengujian dilakukan setelah `SET ROLE app_analitik`: view harus bisa dibaca, sedangkan tabel asli harus menghasilkan galat izin, bukan hanya hasil kosong.

**Bukti belum diisi:** peran aktif, lima baris view, jumlah baris view, dan galat akses langsung beserta SQLSTATE.

**Q24: Identifikasi ulang**

Kombinasi unik dihitung sebagai kelompok `(kota, lahir)` yang berisi tepat satu orang. Perhitungan diulang setelah tanggal lahir diganti tahun. Persentase penurunan dihitung dengan `(unik_sebelum - unik_sesudah) / unik_sebelum × 100%`. Jika tidak ada kombinasi unik sejak awal, persentase ditampilkan sebagai NULL.

Untuk percobaan agregat, skrip memilih satu tanggal lahir yang hanya dimiliki satu pelanggan di suatu kota. Query pertama menghitung jumlah orang dan total saldo seluruh kota; query kedua menghitung kota yang sama tanpa tanggal tersebut. Jika selisih jumlah orang adalah satu, selisih total saldo mengungkap saldo orang itu. Generalisasi mengurangi keunikan, tetapi akses agregat yang saling bertumpang tindih masih dapat membocorkan informasi.

**Bukti belum diisi:** jumlah unik sebelum/sesudah, persentase penurunan, target yang ditemukan, dua hasil agregat, dan selisihnya. Bila target tidak ditemukan, catat bahwa contoh tersebut belum dapat dibuktikan pada data yang tersedia.

*(Q25–Q30 dilanjutkan oleh anggota berikutnya.)*

## Refleksi A–E

**📝 Reflektif A (Langkah 2)**
Mencabut hak (*revoke privilege*) bukan jalan keluar untuk keluhan keamanan antar penyewa. Seperti yang dibuktikan di Langkah 2, pengguna yang memiliki hak aplikasi seperti `app_write` masih bisa mengedit seluruh baris di tabel `pelanggan` karena tidak ada batasan horizontal. Jika penyerang mengeksploitasi aplikasi, mencabut hak tak berguna karena penyerang "berpura-pura" menjadi aplikasi yang sah. Jalan keluar yang tepat adalah menggunakan **Row-Level Security (RLS)**, sehingga basis data menolak akses ke baris penyewa lain meskipun kuerinya dijalankan oleh aplikasi dengan hak `UPDATE` yang sah.

**📝 Reflektif B (Langkah 3)**
**Apakah penyaring `WHERE tenant_id` di aplikasi masih perlu ditulis padahal RLS sudah aktif?**
**Ya, tetap sangat perlu ditulis.** Keduanya mengemban tugas fundamental yang berbeda:
1. **RLS bertugas sebagai Garis Pertahanan Keamanan (Security Barrier):**
   RLS adalah jaring pengaman tingkat basis data (*defense-in-depth*). RLS menjamin bahwa meskipun terjadi bug di kode aplikasi, kelalaian developer lupa menuliskan filter, atau celah logika, basis data secara mutlak menolak membocorkan baris milik penyewa lain (*fail-safe security*).
2. **Penyaring `WHERE tenant_id` di aplikasi bertugas untuk Optimasi Kinerja & Rencana Eksekusi (Query Performance):**
   Dari sisi rencana eksekusi (*query execution plan*), PostgreSQL Query Planner sangat bergantung pada predikat eksplisit untuk menentukan jalur akses tercepat:
   - **Pemanfaatan Indeks:** Dengan menuliskan `WHERE tenant_id = $1` secara eksplisit, perencana kueri dapat langsung menggunakan indeks komposit `(tenant_id, ...)` pada kondisi indeks (*Index Cond*). Sebaliknya, jika hanya mengandalkan RLS, evaluasi fungsi dinamis `current_setting('app.tenant')` sering kali diperlakukan sebagai filter pasca-pembacaan baris (*Filter: ...*), yang berpotensi memicu *Sequential Scan* penuh pada tabel besar.
   - **Partition Pruning:** Jika tabel dipartisi berdasarkan `tenant_id`, klausul `WHERE tenant_id = $1` memungkinkan *pruning* partisi dilakukan sejak tahap perencanaan kueri (*compile-time pruning*), sehingga PostgreSQL hanya membaca partisi milik penyewa tersebut dan mengabaikan partisi penyewa lain.
- **Kesimpulan:** RLS menjamin **keamanan mutlak**, sedangkan klausul `WHERE` di aplikasi menjamin **efisiensi dan performa tinggi**.

**Reflektif C (Langkah 4)**

Parameterisasi menghapus penyebab injeksi pada nilai dengan memisahkan templat dari data. Daftar putih mengendalikan bagian sintaks yang memang perlu dipilih, seperti nama kolom dan arah urut. Hak minimum dan RLS membatasi dampak di basis data. Pada Q14 `app_laporan` hanya punya `SELECT` dan tidak melihat baris di luar penyewa aktif. Batas waktu membatasi durasi pernyataan dan memberi sinyal di log, seperti pembatalan `57014` pada Q18.

**Reflektif D (Langkah 5)**

Enkripsi kolom saja belum cukup. Pertama, pihak yang mempunyai kunci dan hak akses masih dapat membaca data; dekripsi pada Q21 serta pengamatan kunci pada Q22 menjadi pengujiannya. Kedua, informasi seseorang masih dapat disimpulkan dari data yang terlihat atau selisih agregat, seperti percobaan Q23–Q24. Risiko operasionalnya adalah kehilangan kunci: ciphertext tidak bisa dipulihkan tanpa kunci yang benar. Karena itu, akses dan cadangan kunci juga perlu dikelola. Bukti hasil untuk mendukung jawaban ini belum tersedia sampai Q21–Q24 dijalankan.

*(Refleksi E diisi oleh anggota berikutnya.)*

## Peta Tiket #1134 ke UU PDP
| Keluhan | Pasal relevan | Kontrol teknis pencegah | Bukti |
|---|---|---|---|
| *(Dilengkapi Anggota 5 di Langkah 6)* | | | |

Rujukan teknis bagian ini: [pgcrypto PostgreSQL 17](https://www.postgresql.org/docs/17/pgcrypto.html), [CREATE VIEW](https://www.postgresql.org/docs/17/sql-createview.html), dan [pg_stat_activity](https://www.postgresql.org/docs/17/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW).
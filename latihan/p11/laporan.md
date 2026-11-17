# Laporan Latihan Kelompok Pertemuan 11
**Menutup Pintu yang Terbuka: Peran Berlapis, Row-Level Security, Query Berparameter, Enkripsi, Penyamaran, Audit, dan UU PDP**

## Anggota dan Kontribusi
| Nama | NIM | Kontribusi | Commit |
|---|---|---|---|
| Rumaisha Raghib Syahidah Siregar | 251402034 | Langkah 1 dan Langkah 2 | langkah 1 dan 2 |
| *(Anggota 2)* | *(NIM)* | *(Bagian)* | *(Commit)* |
| *(Anggota 3)* | *(NIM)* | *(Bagian)* | *(Commit)* |

---

## Q0–Q30: Perintah, Keluaran Nyata, dan Alasan Keputusan

### Langkah 1 · Setup Klaster Tertutup dan Skema `lab11` (`q00_setup.sql`)
- **Peran yang menjalankan:** `postgres` (superuser)
- **Alasan keputusan:** Menjalankan kontainer PostgreSQL 17 dan kontainer aplikasi di dalam jaringan Docker dengan mode `internal: true` (`lab11_labnet`) untuk menjamin seluruh simulasi keamanan berlangsung terisolasi dari internet publik, serta memverifikasi jumlah baris keempat tabel utama agar seluruh pengujian berikutnya memiliki acuan data yang deterministik.
- **Perintah verifikasi versi basis data & isolasi jaringan:**
  ```bash
  docker exec -it lab11-db psql -U postgres -d msbd -c "SELECT version();"
  docker network inspect lab11_labnet --format '{{.Internal}}'
  ```
- **Keluaran nyata versi & isolasi jaringan:**
  ```text
                                                         version                                                        
  ----------------------------------------------------------------------------------------------------------------------
   PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
  (1 row)

  true
  ```
- **Perintah verifikasi jumlah baris (`q00_setup.sql`):**
  ```sql
  SELECT (SELECT count(*) FROM lab11.tenant)     AS tenant,
         (SELECT count(*) FROM lab11.pelanggan)  AS pelanggan,
         (SELECT count(*) FROM lab11.akun)       AS akun,
         (SELECT count(*) FROM lab11.transaksi)  AS transaksi;

  SELECT tenant_id, count(*) AS jumlah_pelanggan
  FROM lab11.pelanggan
  GROUP BY 1
  ORDER BY 1;
  ```
- **Keluaran nyata jumlah baris & distribusi per penyewa:**
  ```text
   tenant | pelanggan | akun | transaksi 
  --------+-----------+------+-----------
        3 |     30000 |    4 |    120000
  (1 row)

   tenant_id | jumlah_pelanggan 
  -----------+------------------
           1 |            10000
           2 |            10000
           3 |            10000
  (3 rows)
  ```
- **Ringkasan verifikasi:** Seluruh data awal termuat lengkap sesuai baseline (`3` penyewa, `30.000` pelanggan yang terdistribusi merata masing-masing `10.000` baris per `tenant_id`, `4` akun, dan `120.000` transaksi), dengan status jaringan internal `true`.

### Langkah 2 · Kepemilikan, GRANT, dan Peran Berlapis (`Q1–Q5`)

#### Q1 · Hak yang Melekat pada Pemilik (`q01_hak_pemilik.sql`)
- **Peran yang menjalankan:** `postgres` (superuser) dan `skema_owner` (pemilik tabel)
- **Alasan keputusan:** Mencabut hak `UPDATE` dari `skema_owner` melalui superuser lalu menguji eksekusi `UPDATE` sebelum dan sesudah `skema_owner` memberikan kembali hak tersebut kepada dirinya sendiri untuk membuktikan bahwa `REVOKE` hanya menghapus entri ACL, bukan status kepemilikan objek.
- **Perintah yang dijalankan:**
  ```sql
  REVOKE UPDATE ON lab11.pelanggan FROM skema_owner;

  SET ROLE skema_owner;
  BEGIN;
  UPDATE lab11.pelanggan SET kota = kota WHERE id = 3;
  ROLLBACK;

  GRANT UPDATE ON lab11.pelanggan TO skema_owner;

  BEGIN;
  UPDATE lab11.pelanggan SET kota = kota WHERE id = 3;
  ROLLBACK;
  RESET ROLE;
  ```
- **Keluaran nyata:**
  ```text
  REVOKE
  SET
  BEGIN
  ERROR:  permission denied for table pelanggan
  ROLLBACK
  GRANT
  BEGIN
  UPDATE 1
  ROLLBACK
  RESET
  ```
- **Analisis:** Pada percobaan pertama, `UPDATE` ditolak dengan galat `permission denied for table pelanggan` karena entri `UPDATE` telah dihapus dari daftar ACL tabel. Namun, pada percobaan kedua, `skema_owner` berhasil menjalankan `GRANT UPDATE ON lab11.pelanggan TO skema_owner` dan memulihkan aksesnya sendiri (`UPDATE 1`). Hal ini terjadi karena di PostgreSQL status kepemilikan (*ownership*) tetap melekat pada peran pemilik objek (`tableowner`), sehingga pemilik selalu memegang wewenang mutlak untuk mengatur ulang hak akses atas tabel miliknya kapan saja.

---

#### Q2 · `DROP` Bukan Hak Akses Biasa (`q02_drop_bukan_hak.sql`)
- **Peran yang menjalankan:** `postgres` (superuser)
- **Alasan keputusan:** Menjalankan `REVOKE DROP ON lab11.akun FROM skema_owner` secara langsung untuk membuktikan bahwa perintah struktural seperti `DROP` tidak dikelola sebagai tipe *privilege* di dalam sistem ACL PostgreSQL.
- **Perintah yang dijalankan:**
  ```sql
  REVOKE DROP ON lab11.akun FROM skema_owner;
  ```
- **Keluaran nyata (kutipan galat):**
  ```text
  ERROR:  unrecognized privilege type "drop"
  ```
- **Analisis (Perbedaan Hak Biasa vs Hak Kepemilikan):**
  - **Hak Biasa (`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `REFERENCES`, `TRIGGER`):** Merupakan *access privileges* standar yang disimpan di daftar ACL objek dan dapat diberikan atau dicabut secara fleksibel menggunakan perintah `GRANT` dan `REVOKE`.
  - **Hak yang Melekat pada Kepemilikan (`DROP`, `ALTER`, `GRANT`/`REVOKE` atas objek tersebut):** Bukan merupakan jenis *privilege* dalam ACL (sehingga ditolak dengan pesan `unrecognized privilege type "drop"`), melainkan otoritas bawaan yang melekat eksklusif pada pemilik objek (`tableowner`) atau `superuser`. Satu-satunya cara mencabut kemampuan ini adalah memindahkan kepemilikan objek melalui `ALTER TABLE ... OWNER TO`.

---

#### Q3 · Pengaruh Pembuat Objek pada `ALTER DEFAULT PRIVILEGES` (`q03_default_privileges.sql`)
- **Peran yang menjalankan:** `postgres` (superuser)
- **Alasan keputusan:** Membuat tabel sementara `lab11.catatan_postgres` menggunakan peran `postgres` (bukan `skema_owner`) dan memeriksa izin `SELECT` peran `app_laporan` melalui `has_table_privilege` untuk membuktikan cakupan peran pada aturan *default privileges*.
- **Perintah yang dijalankan:**
  ```sql
  CREATE TABLE lab11.catatan_postgres (id int);
  SELECT has_table_privilege('app_laporan', 'lab11.catatan_postgres', 'SELECT') AS via_postgres;
  DROP TABLE lab11.catatan_postgres;
  ```
- **Keluaran nyata:**
  ```text
  CREATE TABLE
   via_postgres 
  --------------
   f
  (1 row)

  DROP TABLE
  ```
- **Analisis:** Nilai `via_postgres` bernilai `f` (*false*), yang berarti `app_laporan` tidak otomatis mendapatkan hak `SELECT` atas tabel yang dibuat oleh `postgres`. Di PostgreSQL, klausa `ALTER DEFAULT PRIVILEGES` terikat secara spesifik pada peran pembuat objek (`FOR ROLE ...`), bukan berlaku menyeluruh untuk semua pembuat di dalam skema. Saat inisialisasi skema, aturan default hanya dipasang untuk `skema_owner`. Agar tabel baru yang dibuat oleh `postgres` juga otomatis dapat dibaca oleh `app_laporan`, perintah yang seharusnya dijalankan adalah:
  ```sql
  ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11
      GRANT SELECT ON TABLES TO app_laporan;
  ```

---

#### Q4 · Pendelegasian Hak dengan `WITH GRANT OPTION` dan `CASCADE` (`q04_grant_option.sql`)
- **Peran yang menjalankan:** `postgres` (superuser) dan `app_write`
- **Alasan keputusan:** Memberikan hak `SELECT ... WITH GRANT OPTION` kepada `app_write`, meneruskannya ke `app_analitik`, lalu menguji pencabutan opsi delegasi tanpa `CASCADE` dan dengan `CASCADE` agar hak baca utama milik `app_write` tetap terjaga.
- **Perintah yang dijalankan:**
  ```sql
  GRANT SELECT ON lab11.transaksi TO app_write WITH GRANT OPTION;

  SET ROLE app_write;
  GRANT SELECT ON lab11.transaksi TO app_analitik;
  RESET ROLE;

  REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write;
  REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write CASCADE;

  SELECT has_table_privilege('app_analitik', 'lab11.transaksi', 'SELECT') AS analitik,
         has_table_privilege('app_write', 'lab11.transaksi', 'SELECT')    AS app_write;
  ```
- **Keluaran nyata:**
  ```text
  GRANT
  SET
  GRANT
  RESET
  ERROR:  dependent privileges exist
  HINT:  Use CASCADE to revoke them too.
  REVOKE
   analitik | app_write 
  ----------+-----------
   f        | t
  (1 row)
  ```
- **Analisis:** Percobaan pencabutan tanpa `CASCADE` gagal dengan galat `ERROR: dependent privileges exist` karena masih ada hak turunan pada `app_analitik` yang diberikan oleh `app_write`. Setelah klausa `CASCADE` ditambahkan pada `REVOKE GRANT OPTION FOR SELECT ...`, PostgreSQL mencabut wewenang delegasi milik `app_write` sekaligus mencabut hak baca turunan pada `app_analitik` (`f`), sementara hak `SELECT` utama milik `app_write` tetap bertahan (`t`).

---

#### Q5 · Pemetaan Tujuh Peran pada Skema `lab11` (`q05_tabel_peran.sql`)
- **Peran yang menjalankan:** `postgres` (superuser)
- **Alasan keputusan:** Mengeksekusi kueri terhadap katalog sistem `pg_roles` untuk memverifikasi atribut `rolcanlogin` dan `rolsuper` seluruh peran pada `lab11` secara aktual.
- **Perintah yang dijalankan:**
  ```sql
  SELECT rolname AS nama_peran,
         rolcanlogin AS dapat_login,
         rolsuper AS superuser
  FROM pg_roles
  WHERE rolname IN (
      'skema_owner', 'app_read', 'app_write',
      'app_portal', 'app_laporan', 'app_analitik', 'app_migrasi'
  )
  ORDER BY rolcanlogin, rolname;
  ```
- **Keluaran nyata:**
  ```text
    nama_peran  | dapat_login | superuser 
  --------------+-------------+-----------
   app_read     | f           | f
   app_write    | f           | f
   skema_owner  | f           | f
   app_analitik | t           | f
   app_laporan  | t           | f
   app_migrasi  | t           | f
   app_portal   | t           | f
  (7 rows)
  ```

- **Tabel Pemetaan Tujuh Peran pada `lab11`:**

| Nama Peran | Lapisan / Jenis Peran | Dapat Login (`LOGIN`)? | Hak & Tanggung Jawab Utama |
| :--- | :--- | :---: | :--- |
| **`skema_owner`** | Lapis 1 · Pemilik Objek (`NOLOGIN`) | Tidak (`f`) | Pemilik skema dan seluruh tabel di `lab11`; mengelola DDL (`CREATE`, `ALTER`, `DROP`) dan ACL objek. |
| **`app_read`** | Lapis 2 · Peran Fungsional (`NOLOGIN`) | Tidak (`f`) | Peran grup (*role group*) yang membundel hak baca dasar (`SELECT`) pada tabel operasional. |
| **`app_write`** | Lapis 2 · Peran Fungsional (`NOLOGIN`) | Tidak (`f`) | Peran grup (*role group*) yang membundel hak baca dan tulis (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) pada tabel operasional. |
| **`app_portal`** | Lapis 3 · Peran Aplikasi (`LOGIN`) | **Ya (`t`)** | Akun koneksi aplikasi portal utama; mewarisi `app_write` untuk transaksi harian dan tunduk pada kebijakan RLS. |
| **`app_laporan`** | Lapis 3 · Peran Aplikasi (`LOGIN`) | **Ya (`t`)** | Akun koneksi layanan pelaporan; mewarisi `app_read` (hanya baca) dan tunduk pada kebijakan RLS antar penyewa. |
| **`app_analitik`** | Lapis 3 · Peran Analitik (`LOGIN`) | **Ya (`t`)** | Akun koneksi tim analis data; hanya diizinkan membaca tampilan tersamar (`v_pelanggan_samar`) tanpa akses ke data mentah. |
| **`app_migrasi`** | Peran Operasional DDL (`LOGIN`) | **Ya (`t`)** | Akun khusus deployment/migrasi skema saat pemeliharaan sistem (`IN ROLE skema_owner`), terpisah dari trafik aplikasi harian. |

- **Alasan aplikasi tidak pernah login sebagai pemilik (1 kalimat):** Aplikasi tidak pernah login sebagai pemilik (`skema_owner`) karena pemilik objek dapat memulihkan haknya sendiri setelah `REVOKE`, memiliki otoritas bawaan untuk menghapus atau mengubah struktur tabel (`DROP`/`ALTER`), serta secara bawaan melewati kebijakan Row-Level Security sehingga satu celah keamanan di aplikasi dapat merusak atau membocorkan seluruh basis data.

---

## Refleksi A–E

### Refleksi A
Berdasarkan bukti keluaran pada Q1 dan Q2, "mencabut hak" dengan perintah `REVOKE` bukan jalan keluar untuk keluhan **K1** (aplikasi login memakai akun pemilik tabel yang dapat menjalankan `DROP TABLE` secara tidak sengaja maupun akibat bug) karena dua alasan utama dari data percobaan:
1. **Hak biasa dapat dipulihkan sendiri oleh pemilik:** Pada Q1, meskipun `UPDATE` dicabut dari `skema_owner` sehingga sempat memunculkan `permission denied`, peran `skema_owner` tetap dapat mengeksekusi `GRANT UPDATE ON lab11.pelanggan TO skema_owner` dan memulihkan aksesnya (`UPDATE 1`).
2. **Hak destruktif melekat pada kepemilikan dan tidak bisa di-`REVOKE`:** Pada Q2, upaya mencabut `DROP` menghasilkan galat `unrecognized privilege type "drop"`, yang membuktikan bahwa wewenang `DROP` dan `ALTER` merupakan hak bawaan pemilik tabel yang tidak dapat dibatasi lewat ACL.

**Jalan keluar untuk K1** adalah menerapkan **pemisahan peran tiga lapis** berbasis prinsip hak minimum (*Principle of Least Privilege*): menjadikan `skema_owner` sebagai peran `NOLOGIN` khusus kepemilikan objek, membundel hak akses ke dalam peran fungsional (`app_read` dan `app_write` yang juga `NOLOGIN`), serta menghubungkan aplikasi melalui akun `LOGIN` terpisah (`app_portal` dan `app_laporan`) yang hanya meminjam hak DML seperlunya tanpa kepemilikan tabel.


# Reflektif C — Analisis Empat Lapis Pertahanan SQL Injection

Parameterized query merupakan mekanisme utama yang menghilangkan penyebab SQL Injection karena memisahkan struktur perintah SQL dengan input pengguna. Dengan mekanisme ini, input diperlakukan sebagai data, bukan sebagai bagian dari sintaks SQL.

Tiga mekanisme pertahanan lainnya memiliki fungsi sebagai berikut:

1. **Allowlist**

   Membatasi identifier SQL, seperti nama kolom dan arah pengurutan, hanya pada nilai yang telah diizinkan sehingga input yang tidak dikenal akan ditolak.

2. **Least Privilege dan Row-Level Security (RLS)**

   Membatasi hak akses serta cakupan data yang dapat diakses oleh akun aplikasi. Hal ini dibuktikan pada Q14, ketika akun `app_laporan` tetap dibatasi oleh kebijakan RLS meskipun query diuji menggunakan payload SQL Injection.

3. **Statement Timeout**

   Membatasi durasi eksekusi query untuk mengurangi dampak query yang berjalan terlalu lama. Pada Q18, konfigurasi `statement_timeout = '5s'` menyebabkan query yang melebihi lima detik dibatalkan oleh PostgreSQL dengan SQLSTATE `57014` (*query_canceled*).

Dengan demikian, parameterized query mengatasi penyebab utama SQL Injection, sedangkan allowlist, Least Privilege dan RLS, serta Statement Timeout berfungsi membatasi kemungkinan penyalahgunaan dan mengurangi dampak ketika kerentanan masih terjadi.

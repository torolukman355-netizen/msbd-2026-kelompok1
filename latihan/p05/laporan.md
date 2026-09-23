# Laporan Latihan Kelompok Pertemuan 5
**Dari Procedure sampai Endpoint: PL/pgSQL, psycopg 3, Connection Pool, SQLAlchemy, N+1, dan FastAPI**

---

## Anggota dan Kontribusi

| No. | Nama | NIM | Posisi | Kontribusi | Commit |
| :-: | :--- | :---: | :--- | :--- | :--- |
| **01** | **Muhammad Lukman Toro** | `251402105` | **Project Manager** | **Langkah 5:** Pemetaan ORM SQLAlchemy 2.0, Eksperimen N+1 (`selectinload` vs `joinedload`), & Benchmark (`lab5_orm.py`, Q16–Q20) | `feat: build SQLAlchemy ORM models and resolve N+1 Q16-Q20` |
| **02** | **Randi Abdiansyah** | `251402138` | **Anggota** | **Langkah 1 & 2:** Setup lingkungan `lab5` (`q00_setup.sql`), Stored Procedure & Batas Transaksi (`q01`–`q05`) | `feat: setup schema lab5 and stored procedures Q1-Q5` |
| **03** | **Muhammad Ihsan Anwar** | `251402044` | **Anggota** | **Langkah 3:** Tipe Data Domain, Enum, Array, & JSONB sebagai Penolak Keadaan Tidak Sah (`q06`–`q09`) | `feat: implement domain, enum, array, and jsonb Q6-Q9` |
| **04** | **Khairunnisa** | `251401017` | **Anggota** | **Langkah 4:** Integrasi psycopg 3 Driver, Parameter Binding, Injeksi, & ConnectionPool (`lab5_driver.py`, Q10–Q15) | `feat: implement psycopg3 driver, injection test, and connection pool Q10-Q15` |
| **05** | **Rumaisha Raghib Syahidah Siregar** | `251402034` | **Anggota** | **Langkah 6 & 7:** Endpoint FastAPI, Validasi Error (`lab5_api.py`, Q21–Q24), Refleksi A–E, Tabel R1, & Penyusunan Laporan | `feat: build FastAPI endpoints, error translation Q21-Q24, and full report` |

---

## Q1–Q24: Perintah, Keluaran, dan Alasan Keputusan

### LANGKAH 1: Setup Lingkungan (q00_setup.sql) — *Randi Abdiansyah*
- **Verifikasi Versi Dependensi & Basis Data:**
  psycopg: 3.2.1 | sqlalchemy: 2.0.35 | fastapi: 0.115.0
  PostgreSQL: PostgreSQL 17.0 (Debian 17.0-1.pgdg120+1) on x86_64-pc-linux-gnu
  jumlah_customer: 599

### LANGKAH 2: PL/pgSQL dan Batas Transaksi (Q1–Q5) — *Randi Abdiansyah*
- **Q1 (`q01_total_dibayar.sql`):** Function `lab5.total_dibayar(p_rental_id bigint)` dibuat menggunakan `numeric` dan `STABLE` untuk mengkalkulasi jumlah pembayaran. Pemanggilan dengan `SELECT` untuk penyewaan yang ada mengembalikan nilai total numeric secara akurat.
- **Q2 (`q02_process_rental.sql`):** Stored procedure `lab5.process_rental` membungkus operasi `INSERT` ke `lab5.rental_tx` dan `lab5.payment_tx` dalam satu unit bisnis. Pemanggilan berhasil menambah 1 baris di kedua tabel secara atomik.
- **Q3 (`q03_buktikan_rollback.sql`):** Pemanggilan `CALL lab5.process_rental(1, 1, 1, -4.99)` memicu galat `CHECK constraint violation` pada domain `positive_amount`. Jumlah `rental_tx` sesudahnya tetap `1` (tidak bertambah), membuktikan bahwa transaksi di-rollback secara utuh oleh PostgreSQL.
- **Q4 (`q04_commit_dalam_procedure.sql`):** Menambahkan `COMMIT` di dalam procedure saat dipanggil dari Python di dalam `with psycopg.connect()` menghasilkan galat:
  `psycopg.errors.InvalidTransactionTermination: cannot commit while a transaction is active`
  *Alasan:* Driver Python membuka transaksi secara implisit, sehingga procedure tidak diizinkan menutup/mengomit transaksi secara independen.
- **Q5 (`q05_exception_fk.sql`):** Menambahkan `EXCEPTION WHEN foreign_key_violation` membuat pesan galat lebih ramah bagi pengguna API. Namun, informasi konteks teknis (seperti nama tabel constraint asli dan stack trace internal SQL) menjadi tersembunyi. Penangkapan ini layak dilakukan di layer API/aplikasi agar tidak membocorkan skema sensitif ke publik.

### LANGKAH 3: Tipe Data sebagai Penolak Keadaan Tidak Sah (Q6–Q9) — *Muhammad Ihsan Anwar*
- **Q6 (`q06_domain_positive_amount.sql`):** Percobaan memasukkan nilai `0` dan `-4.99` ditolak oleh domain `lab5.positive_amount`.
  - Pesan Galat: `ERROR: value for domain lab5.positive_amount violates check constraint "positive_amount_check"`
  - SQLSTATE: `23514` (check_violation)
- **Q7 (`q07_enum_status.sql`):** Percobaan mengisi status `'EXPIRED'` ditolak dengan SQLSTATE `22P02` (invalid_text_representation). Setelah dieksekusi `ALTER TYPE lab5.rental_status ADD VALUE 'EXPIRED'`, status baru berhasil dimasukkan.
- **Q8 (`q08_tags_array.sql`):** Pengisian `tags = ARRAY['promo','akhir-pekan','anggota']` berhasil dan query pencarian menggunakan `'promo' = ANY(tags)` berhasil mengembalikan baris yang relevan.
- **Q9 (`q09_metadata_jsonb.sql`):** Atribut `'{"channel":"web","device":"android"}'::jsonb` disimpan pada kolom `metadata`. Ekstraksi menggunakan operator `metadata ->> 'channel'` mengembalikan string `'web'` tanpa parsing manual di sisi aplikasi.

### LANGKAH 4: psycopg 3 — Binding, Transaksi, dan Pool (Q10–Q15) — *Khairunnisa*
- **Q10 (SELECT Berparameter):** Menjalankan query dengan placeholder `%s` (`SELECT * FROM public.customer WHERE last_name = %s`). Parameter dibind dengan aman oleh driver.
- **Q11 (Uji Injeksi):** Cetakan f-string berbahaya: `SELECT * FROM public.customer WHERE last_name = 'SMITH' OR '1'='1'`.
  Saat dijalankan dengan parameter binding `(%s,)` menggunakan payload `SMITH' OR '1'='1`, query mencari nama literal tersebut dan mengembalikan hasil kosong `[]`, membuktikan f-string berhasil dicegah dari eksekusi SQL arbitrary.
- **Q12 (Identifier & Allow-list):** Mengirim nama kolom `ORDER BY` sebagai parameter nilai (`%s`) gagal karena PostgreSQL menganggapnya sebagai literal string biasa. Perbaikan dilakukan menggunakan `sql.Identifier(col_name)` disertai allow-list tertutup (`['customer_id', 'first_name', 'last_name']`).
- **Q13 (Rollback dari Aplikasi):** `process_rental` dipanggil di dalam blok koneksi Python, lalu dilempar `RuntimeError("gagal di tengah alur")`. Jumlah baris `rental_tx` sebelum dan sesudah exception tetap `0`, membuktikan blok `with psycopg.connect()` otomatis memanggil `conn.rollback()`.
- **Q14 (ConnectionPool):** `ConnectionPool` diinisialisasi dengan `min_size=1, max_size=2`. Menjalankan 5 permintaan berurutan berjalan lancar. Hasil `pool.get_stats()`:
  `{'connections_num': 2, 'requests_num': 5, 'pool_available': 2, 'requests_waiting': 0}`
- **Q15 (Idle in Transaction):** Transaksi dibuka dan didiamkan selama 30 detik. Pemantauan dari terminal psql lain melalui `pg_stat_activity` menampilkan:
  `pid | state | xact_start | query`
  `26828 | idle in transaction | 2026-09-23 10:16:04+00 | CALL lab5.process_rental(...)`

### LANGKAH 5: ORM dan Masalah N+1 (Q16–Q20) — *Muhammad Lukman Toro*
- **Q16 (Model Deklaratif):** Model `Customer` dan `Rental` dipetakan menggunakan `DeclarativeBase` dan `Mapped` SQLAlchemy 2.0 lengkap dengan `relationship()`.
- **Q17 (Bukti N+1):** Mengakses `c.rentals` pada 10 customer memicu 1 query awal ditambah 10 query tambahan ke tabel `rental` (Total **11 SELECT statements**). Ini membuktikan masalah N+1.
- **Q18 (selectinload):** Menggunakan `options(selectinload(Customer.rentals))` memangkas jumlah query menjadi tepat **2 SELECT statements** (1 query customer + 1 query IN dengan seluruh customer_id).
- **Q19 (joinedload):** Menggunakan `joinedload(Customer.rentals)` menghasilkan **1 SELECT statement** dengan `LEFT OUTER JOIN`. Berbeda dari `selectinload` yang memisahkan query koleksi, `joinedload` menggabungkan data dalam satu query tabel besar namun menduplikasi baris induk sehingga memerlukan `.unique()`.
- **Q20 (ORM vs SQL Mentah):** Query analitik 5 film paling sering disewa dieksekusi dalam dua versi:
  - *Waktu Eksekusi ORM (SQLAlchemy):* ~1.42 ms
  - *Waktu Eksekusi SQL Mentah (psycopg):* ~1.18 ms

### LANGKAH 6: API Integration & Validasi HTTP (Q21–Q24) — *Rumaisha Raghib Syahidah Siregar*
- **Q21 (Dependency Koneksi):** Dependency `get_conn()` dibangun menggunakan `yield` untuk meminjam dan mengembalikan koneksi dari `ConnectionPool` secara teratur.
- **Q22 (POST /rentals - Sukses):** Pengiriman payload valid mengembalikan HTTP 201 Created:
  `{"rental_id": 2, "message": "Rental berhasil diproses"}`
- **Q23 (Nilai Negatif - HTTP 422):** Pengiriman `amount = -4.99` ditolak oleh validasi schema Pydantic (`Field(gt=0)`). Server mengembalikan HTTP 422 Unprocessable Entity tanpa membocorkan pesan error internal SQL.
- **Q24 (Inventory Tidak Ada - HTTP 409):** Pengiriman `inventory_id = 999999` ditangkap oleh exception handler PostgreSQL (`Foreign Key Violation`) dan diterjemahkan menjadi HTTP 409 Conflict.

---

## Refleksi A–E

### Refleksi A
- **Memulai Transaksi:** Client (`psycopg`), bukan procedure. `with psycopg.connect(...)` membuka transaksi secara implisit sebelum `CALL` dijalankan.
- **Mengakhiri Transaksi:** Client juga, lewat `commit()` atau `rollback()` otomatis saat blok `with` selesai.
- **Bukti Data:** Di Q3, `count(*)` pada `rental_tx` sebelum dan sesudah `CALL` dengan `amount = -4.99` sama-sama 1, padahal `INSERT` di dalam procedure sudah dieksekusi; ini membuktikan rollback dikendalikan client. Di Q4, `COMMIT` di dalam procedure ditolak dengan `invalid transaction termination`, membuktikan procedure tidak berwenang menutup transaksi.

### Refleksi B
- **Keputusan Struktur Data:** Metadata sebaiknya tetap `JSONB` karena fleksibel untuk menyimpan atribut yang dapat berubah. Namun, jika metadata sering digunakan untuk pencarian dan laporan, sebaiknya dipindahkan ke tabel terstruktur.
- **Pertanyaan Bisnis:** *"Apakah channel dan device akan sering digunakan untuk laporan atau analisis transaksi?"*

### Refleksi C
- **Persamaan Rollback:** Keduanya sama-sama memastikan tidak ada perubahan data yang tersimpan secara permanen (inkonsisten) di dalam database saat terjadi kegagalan/error. Jumlah baris pada tabel tetap aman dan tidak bertambah. Keduanya memanfaatkan konsep transaksi ACID (*Atomicity*).
- **Satu Hal yang Hanya Dapat Didukung Sisi Aplikasi:** Mengendalikan alur berdasarkan logika bisnis / exception eksternal. Sisi aplikasi (Python) dapat dengan sengaja melempar galat (*exception*) atau menghentikan alur berdasarkan keputusan logika bisnis, kondisi runtime, kegagalan integrasi API luar, atau input pengguna sebelum/selama transaksi berjalan (seperti perintah `raise RuntimeError("gagal di tengah alur")` di Q13), lalu memerintahkan `conn.rollback()` secara eksplisit. Sebaliknya, rollback di level basis data (Q3) murni terjadi secara otomatis karena penolakan aturan integritas data internal SQL (*check constraint*).

### Refleksi D
- **Pilihan ORM vs SQL Mentah (Q20):** Kami memilih versi ORM.
  - ORM dan SQL mentah sama-sama menjalankan 1 SELECT.
  - Keduanya menghasilkan 5 baris karena `LIMIT 5`.
  - ORM tetap jelas menyatakan JOIN, GROUP BY, ORDER BY, dan LIMIT melalui API SQLAlchemy.
  - Versi ORM lebih mudah dirawat ketika nama model atau relasi berubah. Selisih waktunya sangat kecil (1.2 ms vs 1.4 ms) sehingga ORM lebih unggul dari segi maintainability.
- **Penggunaan `joinedload` vs `selectinload`:** `joinedload` lebih tepat ketika relasinya *many-to-one* atau *one-to-one*, jumlah baris kecil, dan satu query lebih penting (contoh: 100 Rental dengan satu Customer masing-masing). Untuk relasi koleksi seperti `Customer.rentals`, `selectinload` lebih tepat karena `joinedload` menggandakan baris customer dan memerlukan `.unique()`, sedangkan `selectinload` menghasilkan 2 SELECT tanpa duplikasi hasil induk.

### Refleksi E
- **Jika Validasi Pydantic Dihapus (Hanya Mengandalkan DB):** Request dengan nilai `amount` negatif akan lolos dari filter awal aplikasi dan langsung dieksekusi ke PostgreSQL. Aplikasi melakukan overhead koneksi/query untuk data invalid, pencemaran log DB terjadi, dan aplikasi harus menangani DB exception secara manual untuk memetakan ke respons HTTP 422/400.
- **Jika Validasi Basis Data Dihapus (Hanya Mengandalkan Pydantic):** Database menerima data raw tanpa perlindungan aturan bisnis di tingkat tabel/procedure. Jika ada skrip internal, migration tool, skrip Python driver (`lab5_driver.py`), atau admin yang memasukkan data langsung via `psql`/GUI tanpa melewati API FastAPI, data bernilai negatif akan berhasil masuk (*data corruption*).
- **Kesimpulan Validasi Berlapis:** Pydantic berfungsi sebagai *fail-fast barrier* di layer HTTP untuk memberikan respons cepat (HTTP 422) dan menghemat resource server, sedangkan Constraint/Domain DB berfungsi sebagai *ultimate single source of truth* untuk menjamin konsistensi dan integritas data secara mutlak.

---

## Di Mana Aturan Itu Tinggal

| Aturan | Lapisan | Risiko bila dipindahkan | Bukti |
| :--- | :--- | :--- | :--- |
| **Pembayaran Harus Positif (`amount > 0`)** | **Domain Basis Data & Pydantic Schema** | Jika dipindahkan hanya ke Pydantic, data bernilai negatif bisa masuk via `psql`/skrip backend. Jika hanya di DB, koneksi membuang resource untuk data invalid. | Q3 & Q6 menunjukkan penolakan `CHECK constraint` SQLSTATE `23514`. Q23 menunjukkan penolakan HTTP 422 di layer Pydantic. |
| **Penyewaan dan Pembayaran Atomik** | **Stored Procedure & Transaksi psycopg** | Jika diproses terpisah di aplikasi tanpa transaksi, kegagalan pembayaran akan menyisakan data rental "gantung" tanpa bukti bayar (*data inconsistency*). | Q2 & Q13 membuktikan bahwa kegagalan di tengah alur membatalkan pembentukan `rental_tx` dan `payment_tx` sekaligus. |
| **Klien Tidak Melihat Detail SQL (Galat Aman)** | **FastAPI Exception Handler (API Layer)** | Jika detail SQL/DB dibocorkan ke klien, peretas dapat memanfaatkan struktur skema dan nama constraint tersebut untuk menyusun serangan SQL Injection. | Q23 & Q24 menghasilkan respons HTTP 422 & 409 yang bersih tanpa struktur SQL, sedangkan Q5 menunjukkan hilangnya detail internal saat ditangkap. |

---

## Ringkasan N+1

| Q17 (Lazy Loading / Default) | Q18 (selectinload) | Q19 (joinedload) | Penafsiran |
| :---: | :---: | :---: | :--- |
| **11 Statements** | **2 Statements** | **1 Statement** | Default ORM memicu masalah N+1 (11 query). `selectinload` menyelesaikan N+1 secara efisien dengan 2 query terpisah. `joinedload` menggunakan 1 query `LEFT JOIN`, sangat cepat untuk relasi tunggal namun menghasilkan duplikasi baris pada relasi koleksi. |

---

## Penggunaan AI dan Verifikasi

Dalam pengerjaan Latihan Pertemuan 5 ini, kelompok memanfaatkan bantuan AI (Gemini) untuk:
1. Membantu diagnosis ralat konfigurasi port mapping Docker (`5433:5432`) dan penyesuaian DSN psycopg 3.
2. Membantu pemahaman konsep sintaks deklaratif SQLAlchemy 2.0 (Mapped dan relationship) serta perbedaan mekanisme selectinload vs joinedload.

**Verifikasi Mandiri:** Seluruh potongan kode, kueri SQL, skrip Python driver, model ORM, dan endpoint FastAPI telah dieksekusi, diuji, dan diverifikasi secara langsung oleh anggota kelompok pada lingkungan lokal (`docker compose` & `.venv`) hingga seluruh pengujian berjalan sukses 100%.

---

## Tautan Merge Request
* **Merge Request Link:** `[https://gitlab.com/msbd-2026/msbd-2026-kelompok1/-/merge_requests/5](https://gitlab.com/msbd-2026/msbd-2026-kelompok1/-/merge_requests/5)`

---

## Checklist Akhir

- [x] Skema `lab5` dan lingkungan Python berhasil dibangun.
- [x] Q1–Q24 lengkap dengan bukti keluaran atau pesan galat.
- [x] Payload injeksi tidak dijalankan sebagai SQL yang dirangkai.
- [x] Hitungan statement Q17, Q18, dan Q19 dicatat.
- [x] Endpoint menghasilkan 201, 422, dan 409 sesuai pengujian.
- [x] Refleksi A–E, R1, README.md, dan laporan.md lengkap.
- [x] Setiap anggota memiliki commit yang dapat ditelusuri.
- [x] Merge request sudah dibuka dan tautannya dicantumkan.
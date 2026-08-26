# LAPORAN LATIHAN P01

## DOCKER

> **Mata Kuliah:** Manajemen Sistem Basis Data
> **Praktikum:** P01 — Docker
> **Repository:** `msbd-2026-kelompok1`

---

## DAFTAR ISI

1. [Hasil Praktikum Docker](#1-hasil-praktikum-docker)
2. [Pertanyaan Langkah 1](#2-pertanyaan-langkah-1)
3. [Pertanyaan Langkah 2](#3-pertanyaan-langkah-2)
4. [Pertanyaan Langkah 3](#4-pertanyaan-langkah-3)
5. [Hasil Query](#5-hasil-query)
6. [Tautan Repository](#6-tautan-repository)
7. [Commit Anggota Kelompok](#7-commit-anggota-kelompok)
8. [Tantangan Tambahan](#8-tantangan-tambahan)

---

# 1. HASIL DOCKER

## 1.1 Versi Docker

Perintah:

```bash
docker --version
```

Output:

```text
Docker version 29.7.2, build a7dcaa6
```

## 1.2 Versi Docker Compose

Perintah:

```bash
docker compose version
```

Output:

```text
Docker Compose version v5.4.0
```

## 1.3 Status Container

Perintah:

```bash
docker compose ps
```

Output:

```text
NAME         IMAGE            COMMAND                  SERVICE    CREATED          STATUS                    PORTS
msbd-mongo   mongo:8          "docker-entrypoint.s…"   mongo      About an hour    Up About an hour          0.0.0.0:27017->27017/tcp
msbd-pg      postgres:17      "docker-entrypoint.s…"   postgres   About an hour    Up About an hour (healthy) 0.0.0.0:5432->5432/tcp
msbd-redis   redis:7-alpine   "docker-entrypoint.s…"   redis      About an hour    Up About an hour          0.0.0.0:6379->6379/tcp
```

### Ringkasan Container

| Container    | Image            | Service    | Status       | Port    |
| ------------ | ---------------- | ---------- | ------------ | ------- |
| `msbd-mongo` | `mongo:8`        | MongoDB    | Up           | `27017` |
| `msbd-pg`    | `postgres:17`    | PostgreSQL | Up (healthy) | `5432`  |
| `msbd-redis` | `redis:7-alpine` | Redis      | Up           | `6379`  |

## 1.4 Informasi PostgreSQL

Perintah:

```sql
SELECT version();
```

Output:

```text
PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu,
compiled by gcc (Debian 14.2.0-19), 64-bit
```

### Daftar Database

| Name        | Owner  | Encoding | Locale Provider | Collate      | Ctype        |
| ----------- | ------ | -------- | --------------- | ------------ | ------------ |
| `latihan`   | `msbd` | UTF8     | libc            | `en_US.utf8` | `en_US.utf8` |
| `pagila`    | `msbd` | UTF8     | libc            | `en_US.utf8` | `en_US.utf8` |
| `postgres`  | `msbd` | UTF8     | libc            | `en_US.utf8` | `en_US.utf8` |
| `template0` | `msbd` | UTF8     | libc            | `en_US.utf8` | `en_US.utf8` |
| `template1` | `msbd` | UTF8     | libc            | `en_US.utf8` | `en_US.utf8` |

**Schema:** `public`
**Relations:** Tidak ditemukan pada database yang diperiksa.

---

# 2. PERTANYAAN LANGKAH 1

## 2.1 Apa yang dimaksud dengan Docker Image?

Docker Image adalah sebuah paket yang berisi semua kebutuhan untuk menjalankan suatu aplikasi, seperti kode program, library, dependency, dan konfigurasi. Image digunakan sebagai dasar untuk membuat container.

## 2.2 Apa yang dimaksud dengan Container?

Container adalah lingkungan terisolasi yang dibuat dari Docker Image untuk menjalankan aplikasi. Container membuat aplikasi dapat berjalan dengan lingkungan dan dependency yang sudah ditentukan tanpa banyak memengaruhi sistem utama.

## 2.3 Apa fungsi Volume?

Volume berfungsi untuk menyimpan data dari container secara permanen. Dengan volume, data tidak ikut hilang ketika container dihapus atau dibuat ulang, sehingga cocok untuk menyimpan database, file, atau data aplikasi.

---

# 3. PERTANYAAN LANGKAH 2

## 3.1 Apa yang terjadi jika bagian `volumes:` pada layanan PostgreSQL dihapus, kemudian container dihentikan menggunakan `docker compose down -v`?

Jika `volumes:` dihapus, data database hanya tersimpan di dalam writable layer container dan tidak memiliki persistent storage yang terpisah. Ketika container dihapus menggunakan `docker compose down -v`, data tersebut ikut terhapus.

Akibatnya, data database dapat hilang dan tidak dapat dipulihkan tanpa adanya backup.

## 3.2 Mengapa pemetaan port ditulis `5432:5432` dan bukan cukup satu angka?

Pemetaan `5432:5432` memiliki dua sisi:

* `5432` pertama → port pada komputer/host.
* `5432` kedua → port PostgreSQL di dalam container.

Jika komputer sudah memiliki PostgreSQL lain yang menggunakan port `5432`, port pada host dapat diubah, misalnya:

```yaml
ports:
  - "5433:5432"
```

Dengan konfigurasi tersebut, PostgreSQL tetap menggunakan port `5432` di dalam container, tetapi dapat diakses dari komputer melalui port `5433`.

## 3.3 Apa fungsi blok `healthcheck`?

`healthcheck` digunakan untuk memastikan bahwa suatu service benar-benar siap digunakan, bukan hanya sekadar container dalam kondisi `running`.

Hal ini penting karena container dapat berstatus berjalan ketika PostgreSQL masih dalam proses inisialisasi. Service lain yang bergantung pada PostgreSQL dapat menggunakan status `healthy` sebagai indikator bahwa database sudah siap menerima koneksi.

Tanpa healthcheck, service lain dapat mencoba terhubung terlalu cepat sehingga menyebabkan kegagalan koneksi.

## 3.4 Bagaimana cara menyimpan password dengan lebih aman?

Password sebaiknya disimpan dalam file `.env`, kemudian dipanggil dari `docker-compose.yml`, misalnya:

```yaml
environment:
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
```

File `.env` kemudian dapat dimasukkan ke `.gitignore` agar tidak ikut diunggah ke repository Git.

Hal ini penting karena password yang ditulis langsung di `docker-compose.yml` dapat terlihat oleh siapa saja yang memiliki akses ke repository, terutama jika repository bersifat publik.

---

# 4. PERTANYAAN LANGKAH 3

## 4.1 Aktivitas yang lebih cepat menggunakan `psql`

Inspeksi cepat metadata dan scripting/automasi lebih cepat dilakukan menggunakan `psql`.

Contohnya, perintah:

```text
\dt
```

untuk melihat daftar tabel dan:

```text
\l
```

untuk melihat daftar database.

`psql` juga memungkinkan eksekusi SQL script atau dump secara langsung melalui terminal tanpa overhead antarmuka grafis.

## 4.2 Aktivitas yang lebih cepat menggunakan DBeaver

Eksplorasi database secara visual lebih cepat dilakukan menggunakan DBeaver.

Contohnya:

* Melihat struktur tabel.
* Melihat hubungan antartabel melalui ER Diagram.
* Menjelajahi data dalam tampilan tabel.
* Melakukan filter dan sorting.
* Mengedit data secara visual.

## 4.3 Perbandingan `psql` dan DBeaver

| Aspek           | `psql`                       | DBeaver     |
| --------------- | ---------------------------- | ----------- |
| Antarmuka       | Terminal/CLI                 | GUI         |
| Menjalankan SQL | Sangat cepat                 | Mudah       |
| Metadata        | Cepat melalui command        | Visual      |
| Scripting       | Sangat baik                  | Baik        |
| Eksplorasi data | Kurang visual                | Sangat baik |
| ER Diagram      | Tidak tersedia secara visual | Tersedia    |
| Editing data    | Berbasis SQL                 | Visual      |

**Kesimpulan:** `psql` lebih unggul untuk menjalankan perintah SQL, mengecek metadata, dan scripting melalui terminal. DBeaver lebih unggul untuk eksplorasi database secara visual, seperti melihat tabel, ER Diagram, dan mengelola data melalui antarmuka grafis.

---

# 5. HASIL QUERY

## 5.1 V1

**Hasil:**

| count |
| ----: |
|    21 |

---

## 5.2 V2

**Ukuran Relasi:**

| Relasi             |  Ukuran |
| ------------------ | ------: |
| `rental`           | 2352 kB |
| `film`             |  952 kB |
| `payment_p2017_04` |  656 kB |
| `payment_p2017_03` |  568 kB |
| `film_actor`       |  488 kB |
| `inventory`        |  440 kB |
| `payment_p2017_02` |  296 kB |
| `payment_p2017_01` |  248 kB |
| `customer`         |  216 kB |
| `address`          |  160 kB |

---

## 5.3 V3

**5 Film dengan Total Penyewaan Tertinggi:**

| No. | Title                 | Total Sewa |
| --: | --------------------- | ---------: |
|   1 | `BUCKET BROTHERHOOD`  |         34 |
|   2 | `ROCKETEER MOTHER`    |         33 |
|   3 | `RIDGEMONT SUBMARINE` |         32 |
|   4 | `SCALAWAG DUCK`       |         32 |
|   5 | `FORWARD TEMPLE`      |         32 |

---

## 5.4 V4 — Query Plan

Hasil `EXPLAIN ANALYZE`:

```text
HashAggregate
  (cost=713.69..723.69 rows=1000 width=23)
  (actual time=16.628..16.765 rows=958 loops=1)

  Group Key: f.title
  Batches: 1
  Memory Usage: 193kB

  -> Hash Join
       (cost=238.57..633.47 rows=16044 width=15)
       (actual time=2.458..12.258 rows=16044 loops=1)

       Hash Cond: (i.film_id = f.film_id)

       -> Hash Join
            (cost=128.07..480.67 rows=16044 width=2)
            (actual time=1.549..8.145 rows=16044 loops=1)

            Hash Cond: (r.inventory_id = i.inventory_id)

            -> Seq Scan on rental r
                 (cost=0.00..310.44 rows=16044 width=4)
                 (actual time=0.013..1.437 rows=16044 loops=1)

            -> Hash
                 (cost=70.81..70.81 rows=4581 width=6)
                 (actual time=1.438..1.440 rows=4581 loops=1)

                 Buckets: 8192
                 Batches: 1
                 Memory Usage: 234kB

                 -> Seq Scan on inventory i
                      (cost=0.00..70.81 rows=4581 width=6)
                      (actual time=0.009..0.600 rows=4581 loops=1)

       -> Hash
            (cost=98.00..98.00 rows=1000 width=19)
            (actual time=0.838..0.839 rows=1000 loops=1)

            Buckets: 1024
            Batches: 1
            Memory Usage: 60kB

            -> Seq Scan on film f
                 (cost=0.00..98.00 rows=1000 width=19)
                 (actual time=0.043..0.566 rows=1000 loops=1)

Planning Time: 0.677 ms
Execution Time: 17.124 ms
```

### Catatan

Bagian yang paling membingungkan dari keluaran tersebut adalah struktur hierarki teks dan berbagai informasi numerik pada `actual time` dan `cost`, sehingga query plan cukup sulit dipahami secara visual.

Namun, query plan menunjukkan bahwa PostgreSQL menggunakan beberapa operasi `Hash Join`, `HashAggregate`, dan `Seq Scan` untuk memproses data.

---

# 6. TAUTAN REPOSITORY

Repository tugas dan praktikum kelompok:

**[MSBD 2026 — Kelompok 1](https://github.com/torolukman355-netizen/msbd-2026-kelompok1/)**

---

# 7. COMMIT ANGGOTA KELOMPOK

### 26 Agustus 2026

| Anggota              | Commit                                | Waktu             |
| -------------------- | ------------------------------------- | ----------------- |
| `MuhammadIhsanAnwar` | Finishing: Penyelesaian seluruh tugas | 1 menit yang lalu |

### 25 Agustus 2026

| Anggota             | Commit                                                           | Waktu            |
| ------------------- | ---------------------------------------------------------------- | ---------------- |
| `rumaisharaghibsrg` | Tahap 4: menyelesaikan restore pagila dan query verifikasi V1-V4 | 1 hari yang lalu |

### 23 Agustus 2026

| Anggota                 | Commit                                    | Waktu            |
| ----------------------- | ----------------------------------------- | ---------------- |
| `torolukman355-netizen` | langkah 3                                 | 2 hari yang lalu |
| `randii-tech`           | step 2                                    | 2 hari yang lalu |
| `torolukman355-netizen` | latihan                                   | 2 hari yang lalu |
| `Khairunnisa017`        | Cek Docker dan Buat folder awal msbd-2026 | 2 hari yang lalu |

---

# 8. TANTANGAN TAMBAHAN

## 8.1 Perbandingan Performa Sebelum dan Sesudah Index

Sebelum index dibuat, waktu pencarian adalah:

```text
0,134 detik
```

Setelah index dibuat:

```text
0,002 detik
```

Dengan demikian, penggunaan index mempercepat proses pencarian secara signifikan.

### Perbandingan

| Kondisi       |       Waktu |
| ------------- | ----------: |
| Sebelum index | 0,134 detik |
| Setelah index | 0,002 detik |
| Percepatan    |        ±67× |

Index membantu PostgreSQL menemukan data berdasarkan nilai pada kolom tertentu tanpa harus memeriksa seluruh 2.000.000 baris.

Sebelum menggunakan index, PostgreSQL harus melakukan pencarian secara berurutan atau `Sequential Scan`. Setelah index dibuat, PostgreSQL dapat menggunakan `Index Scan` sehingga proses pencarian menjadi jauh lebih cepat.

Dengan demikian, waktu pencarian berkurang dari **0,134 detik menjadi 0,002 detik**, atau sekitar **67 kali lebih cepat**.

---
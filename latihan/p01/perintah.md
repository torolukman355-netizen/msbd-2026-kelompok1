# LANGKAH-LANGKAH PRAKTIKUM P01

## 1. Memverifikasi Docker

Verifikasi dilakukan untuk memastikan Docker dan Docker Compose telah terpasang serta dapat digunakan dengan baik.

### 1.1 Memeriksa Versi Docker

```bash
docker --version
```

### 1.2 Memeriksa Versi Docker Compose

```bash
docker compose version
```

### 1.3 Menjalankan Container `hello-world`

```bash
docker run --rm hello-world
```

Perintah tersebut digunakan untuk memastikan Docker Engine dapat menjalankan container dengan normal. Opsi `--rm` akan menghapus container secara otomatis setelah proses selesai.

---

## 2. Menjalankan Environment

### 2.1 Membuat Folder Dump

```bash
mkdir -p dump
```

Folder `dump` digunakan sebagai lokasi penyimpanan file dump database yang akan digunakan dalam proses restore.

### 2.2 Menjalankan Seluruh Service

```bash
docker compose up -d
```

Opsi `-d` digunakan agar container berjalan di background tanpa mengambil alih terminal.

### 2.3 Memeriksa Status Container

```bash
docker compose ps
```

Perintah ini digunakan untuk memastikan seluruh service yang didefinisikan dalam Docker Compose telah berjalan.

### 2.4 Memeriksa Log PostgreSQL

```bash
docker compose logs postgres | tail -20
```

Perintah tersebut digunakan untuk melihat 20 baris terakhir log service PostgreSQL. Log dapat digunakan untuk memastikan PostgreSQL berhasil melakukan proses inisialisasi dan tidak mengalami error.

---

## 3. Mengakses PostgreSQL Menggunakan `psql`

PostgreSQL dapat diakses langsung dari dalam container menggunakan `psql`.

### 3.1 Membuka `psql`

```bash
docker compose exec postgres psql -U msbd -d latihan
```

Keterangan:

| Parameter             | Fungsi                                  |
| --------------------- | --------------------------------------- |
| `docker compose exec` | Menjalankan perintah di dalam container |
| `postgres`            | Nama service PostgreSQL                 |
| `psql`                | PostgreSQL interactive terminal         |
| `-U msbd`             | Menggunakan user `msbd`                 |
| `-d latihan`          | Mengakses database `latihan`            |

### 3.2 Memeriksa Versi PostgreSQL

```sql
SELECT version();
```

Perintah ini digunakan untuk mengetahui versi PostgreSQL yang sedang digunakan.

### 3.3 Melihat Daftar Database

```text
\l
```

Menampilkan seluruh database yang tersedia pada server PostgreSQL.

### 3.4 Melihat Daftar Tabel

```text
\dt
```

Menampilkan tabel yang terdapat pada schema yang sedang digunakan.

### 3.5 Melihat Daftar Schema

```text
\dn
```

Menampilkan seluruh schema yang tersedia pada database.

### 3.6 Melihat Daftar Role

```text
\du
```

Menampilkan role atau user PostgreSQL beserta atribut dan hak aksesnya.

### 3.7 Melihat Lokasi Penyimpanan Data

```sql
SHOW data_directory;
```

Menampilkan lokasi direktori tempat PostgreSQL menyimpan data database.

### 3.8 Melihat Konfigurasi `shared_buffers`

```sql
SHOW shared_buffers;
```

Menampilkan ukuran memory yang dialokasikan PostgreSQL untuk `shared_buffers`, yaitu area memory yang digunakan untuk melakukan caching terhadap halaman data dan indeks.

---

## 4. Mengakses PostgreSQL dari DBeaver

PostgreSQL juga dapat diakses menggunakan aplikasi DBeaver melalui koneksi TCP ke port yang telah dipetakan oleh Docker.

### Konfigurasi Koneksi

| Parameter    | Nilai       |
| ------------ | ----------- |
| **Host**     | `localhost` |
| **Port**     | `5432`      |
| **Database** | `latihan`   |
| **Username** | `msbd`      |
| **Password** | `msbd2026`  |

Konfigurasi tersebut memungkinkan DBeaver pada komputer host terhubung ke PostgreSQL yang berjalan di dalam container Docker melalui port `5432`.

> **Catatan:** Password sebaiknya tidak dicantumkan dalam repository publik. Untuk dokumentasi yang akan diunggah ke GitHub, password dapat disamarkan menjadi `********`.

---

# 5. Restore Database Pagila

Database **Pagila** digunakan sebagai dataset latihan untuk melakukan eksplorasi dan pengujian query PostgreSQL.

## 5.1 Membuat Database Kosong

Database `pagila` dibuat terlebih dahulu sebelum proses restore dilakukan.

```bash
docker compose exec postgres createdb -U msbd pagila
```

Perintah tersebut membuat database baru bernama `pagila` menggunakan user PostgreSQL `msbd`.

---

## 5.2 Melakukan Restore Pagila

```bash
docker compose exec postgres pg_restore \
  -U msbd \
  -d pagila \
  --no-owner \
  /dump/pagila.dump
```

Keterangan:

| Parameter           | Fungsi                                     |
| ------------------- | ------------------------------------------ |
| `pg_restore`        | Melakukan restore database dari file dump  |
| `-U msbd`           | Menggunakan user `msbd`                    |
| `-d pagila`         | Restore dilakukan ke database `pagila`     |
| `--no-owner`        | Mengabaikan informasi owner dari file dump |
| `/dump/pagila.dump` | Lokasi file dump di dalam container        |

---

## 5.3 Verifikasi Tabel

Setelah proses restore selesai, keberadaan tabel diverifikasi menggunakan perintah:

```bash
docker compose exec postgres psql -U msbd -d pagila -c "\dt"
```

Perintah tersebut menjalankan `psql` secara langsung dan menampilkan daftar tabel yang terdapat pada database `pagila`.

Jika proses restore berhasil, daftar tabel Pagila akan ditampilkan pada output terminal.

---

# 6. Alur Singkat Tugas

```text
Verifikasi Docker
       │
       ▼
Menjalankan Docker Compose
       │
       ▼
Memeriksa Status Container
       │
       ▼
Mengakses PostgreSQL dengan psql
       │
       ▼
Menghubungkan PostgreSQL dengan DBeaver
       │
       ▼
Membuat Database pagila
       │
       ▼
Restore pagila.dump
       │
       ▼
Verifikasi Tabel Pagila
```
=======
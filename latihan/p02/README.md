# Manajemen Sistem Basis Data

<div align="center">

<table>
<tr>
<td align="center" width="800">

<img src="https://img.shields.io/badge/MANAJEMEN%20SISTEM%20BASIS%20DATA-2026-5D4037?style=for-the-badge" alt="Manajemen Sistem Basis Data">

<br><br>

# MSBD - Kelompok 1

**Repository Tugas**

Manajemen Sistem Basis Data

<br>

<img src="https://img.shields.io/badge/KELOMPOK-1-C9A227?style=for-the-badge" alt="Kelompok 1">
<img src="https://img.shields.io/badge/STATUS-AKTIF-5D4037?style=for-the-badge" alt="Status Aktif">

</td>
</tr>
</table>

</div>

---

## Anggota Kelompok

<div align="center">

|  No.   | Nama                                 |     NIM     | Posisi              |
| :----: | :----------------------------------- | :---------: | :------------------ |
| **01** | **Muhammad Lukman Toro**             | `251402105` | **Project Manager** |
| **02** | **Khairunnisa**                      | `251402017` | Anggota             |
| **03** | **Rumaisha Raghib Syahidah Siregar** | `251402034` | Anggota             |
| **04** | **Muhammad Ihsan Anwar**             | `251402044` | Anggota             |
| **05** | **Randi Abdiansyah**                 | `251402138` | Anggota             |

</div>

---

## Informasi Mata Kuliah

<div align="center">

<table>
<tr>

<td align="center" width="260">

<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/postgresql/postgresql-original.svg" width="45">

<br>

**Mata Kuliah**

Manajemen Sistem Basis Data

</td>

<td align="center" width="220">

<img src="https://img.icons8.com/ios-filled/100/5D4037/conference-call.png" width="45">

<br>

**Kelompok**

Kelompok 1

</td>

<td align="center" width="300">

<img src="https://img.icons8.com/ios-filled/100/5D4037/teacher.png" width="45">

<br>

**Dosen Pengampu**

Muhammad Isa Dadi Hasibuan, S.Kom., M.Kom.

</td>

</tr>
</table>

</div>

---

## Domain yang Dipilih

<div align="center">

<table>
<tr>
<td align="center" width="800">

<img src="https://img.icons8.com/ios-filled/100/5D4037/books.png" width="55">

<br>

### Sistem Manajemen Perpustakaan

Sistem basis data yang digunakan untuk mengelola kegiatan operasional perpustakaan, meliputi data anggota, buku, kategori buku, eksemplar buku, peminjaman, pengembalian, denda, serta peran pengguna.

</td>
</tr>
</table>

</div>

---

## Teknologi & Tools

<div align="center">

<table>
<tr>

<td align="center" width="220">

<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/postgresql/postgresql-original.svg" width="70">

<br>

### PostgreSQL

Sistem Manajemen Basis Data Relasional

</td>

<td align="center" width="220">

<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/docker/docker-original.svg" width="70">

<br>

### Docker

Containerization Platform

</td>

<td align="center" width="220">

<img src="https://dbeaver.io/wp-content/uploads/2015/09/beaver-head.png" width="70">

<br>

### DBeaver

Database Management Tool

</td>

</tr>
</table>

</div>

---

## 1. Menjalankan Docker Compose

Pastikan **Docker Desktop** sudah berjalan.

Buka terminal pada folder utama project:

```text
D:\0_Project_VS_Code\msbd-2026-kelompok1
```

Kemudian jalankan:

```bash
docker compose up -d
```

Perintah tersebut akan menjalankan service yang telah dikonfigurasi pada Docker Compose.

Untuk memeriksa status container:

```bash
docker compose ps
```

Container PostgreSQL, MongoDB, dan Redis akan dijalankan sesuai konfigurasi pada `docker-compose.yml`.

---

## 2. Konfigurasi Database

Database PostgreSQL yang digunakan dalam project:

| Konfigurasi | Nilai        |
| :---------- | :----------- |
| Host        | `localhost`  |
| Port        | `5432`       |
| Database    | `proyek_dev` |
| Username    | `msbd`       |
| Password    | `msbd2026`   |

Database dapat diakses menggunakan DBeaver atau PostgreSQL client lainnya.

---

## 3. Menjalankan Migration

Migration database menggunakan **Flyway**.

File migration terdapat pada:

```text
latihan/p02/migrations/
```

Untuk menjalankan migration:

```bash
docker compose run --rm flyway migrate
```

Flyway akan membaca file migration dan menerapkannya pada database `proyek_dev`.

### Memeriksa Status Migration

Gunakan:

```bash
docker compose run --rm flyway info
```

Contoh hasil ketika migration berhasil:

```text
Successfully validated 1 migration
Current version of schema "public": 1
Schema "public" is up to date.
No migration necessary.
```

---

## 4. Menjalankan Seed Data

Seed digunakan untuk memasukkan data awal ke dalam database.

File seed terdapat pada:

```text
latihan/p02/seeds/01_peran.sql
```

Seed berisi data awal tabel `peran`:

| Kode  | Nama          |
| :---: | :------------ |
| `ADM` | Administrator |
| `PTG` | Petugas       |
| `AGT` | Anggota       |

Isi file `01_peran.sql`:

```sql
CREATE TABLE IF NOT EXISTS peran (
    kode VARCHAR(10) PRIMARY KEY,
    nama VARCHAR(100) NOT NULL
);

INSERT INTO peran (kode, nama) VALUES
('ADM', 'Administrator'),
('PTG', 'Petugas'),
('AGT', 'Anggota')
ON CONFLICT (kode)
DO UPDATE SET nama = EXCLUDED.nama;
```

### Menjalankan Seed

Karena project dijalankan melalui PowerShell, gunakan:

```powershell
Get-Content .\latihan\p02\seeds\01_peran.sql | docker compose exec -T postgres psql -U msbd -d proyek_dev
```

### Pengujian Idempotensi

Seed dapat dijalankan lebih dari satu kali tanpa menghasilkan data duplikat.

Untuk menjalankan seed sebanyak dua kali:

```powershell
1..2 | ForEach-Object { Get-Content .\latihan\p02\seeds\01_peran.sql | docker compose exec -T postgres psql -U msbd -d proyek_dev }
```

Seed menggunakan:

```sql
ON CONFLICT (kode)
DO UPDATE SET nama = EXCLUDED.nama;
```

Dengan mekanisme tersebut, apabila `kode` sudah tersedia di database, data akan diperbarui dan tidak dibuat sebagai baris baru.

### Memeriksa Jumlah Data

Untuk memeriksa jumlah data pada tabel `peran`:

```powershell
docker compose exec postgres psql -U msbd -d proyek_dev -c "SELECT count(*) FROM peran;"
```

Hasil yang diharapkan:

```text
 count
-------
     3
(1 row)
```

Meskipun seed dijalankan dua kali, jumlah data tetap **3 baris**.

---

## 5. Alur Menjalankan Project

<div align="center">

<table>
<tr>

<td align="center" width="220">

<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/docker/docker-original.svg" width="50">

<br>

<b>Docker Compose</b>

<br><br>

```text
docker compose
up -d
```

</td>

<td align="center" width="50">

→

</td>

<td align="center" width="220">

<img src="https://img.icons8.com/ios-filled/100/5D4037/synchronize.png" width="50">

<br>

<b>Migration</b>

<br><br>

```text
flyway
migrate
```

</td>

<td align="center" width="50">

→

</td>

<td align="center" width="220">

<img src="https://img.icons8.com/ios-filled/100/5D4037/database.png" width="50">

<br>

<b>Seed Data</b>

<br><br>

```text
01_peran.sql
```

</td>

</tr>
</table>

</div>

---

## Quick Start

Untuk menjalankan project dari awal:

### Menjalankan Docker Compose

```bash
docker compose up -d
```

### Menjalankan Migration

```bash
docker compose run --rm flyway migrate
```

### Memeriksa Migration

```bash
docker compose run --rm flyway info
```

### Menjalankan Seed

```powershell
Get-Content .\latihan\p02\seeds\01_peran.sql | docker compose exec -T postgres psql -U msbd -d proyek_dev
```

### Memeriksa Data Seed

```powershell
docker compose exec postgres psql -U msbd -d proyek_dev -c "SELECT * FROM peran;"
```

---

## Catatan

- Pastikan **Docker Desktop** sudah berjalan sebelum menjalankan Docker Compose.
- PostgreSQL menggunakan user `msbd`.
- Database yang digunakan adalah `proyek_dev`.
- Migration database dikelola menggunakan Flyway.
- Seed data dapat dijalankan berulang kali tanpa menghasilkan duplikasi.
- Jangan menghapus volume PostgreSQL apabila masih terdapat data yang diperlukan.
- DBeaver dapat digunakan untuk melihat dan mengelola database secara visual.

---

<div align="center">

<img src="https://img.icons8.com/ios-filled/100/5D4037/database.png" width="45">

### Manajemen Sistem Basis Data

**Kelompok 1 — 2026**

<br>

<sub>Repository Tugas Manajemen Sistem Basis Data</sub>

</div>

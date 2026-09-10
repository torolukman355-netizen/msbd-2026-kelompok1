# Latihan Pertemuan 3 — SQL Lanjutan I

> **Mata Kuliah:** Manajemen Sistem Basis Data  
> **Database:** Pagila  
> **DBMS:** PostgreSQL 17  
> **Environment:** Docker & Docker Compose

---

## ◆ Tujuan Latihan

Mempraktikkan penggunaan **SQL lanjutan pada PostgreSQL** melalui database Pagila, meliputi **CTE, subquery, recursive query, window function, agregasi, grouping, dan JSON/JSONB** untuk melakukan analisis data.

---

## ◆ Prasyarat

Sebelum menjalankan latihan, pastikan:

- Docker sudah terpasang dan sedang berjalan.
- PostgreSQL 17 digunakan melalui Docker.
- Basis data Pagila sudah terisi.
- Docker Compose sudah dikonfigurasi.
- Seluruh file latihan berada di folder `latihan/p03/`.

---

## ◆ Menjalankan Setup

Jalankan `q00_setup.sql` terlebih dahulu untuk menyiapkan kebutuhan awal latihan.

```powershell
Get-Content latihan/p03/q00_setup.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

---

## ◆ Menjalankan Jawaban

Jawaban latihan dikerjakan secara berurutan dari **Q1 sampai Q20**, kemudian dilanjutkan dengan **R1**.

### Q1 — Tarif di Atas Rata-rata

```powershell
Get-Content latihan/p03/q01_tarif_di_atas_rata.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q2 — Kategori Lebih dari 60

```powershell
Get-Content latihan/p03/q02_kategori_lebih_60.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q3 — Pelanggan dengan Pembayaran Besar

```powershell
Get-Content latihan/p03/q03_pelanggan_pembayaran_besar.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q4 — Film yang Tidak Pernah Disewa

```powershell
Get-Content latihan/p03/q04_film_tidak_pernah_disewa.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q5 — Tarif Tertinggi per Toko

```powershell
Get-Content latihan/p03/q05_tarif_tertinggi_per_toko.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q6 — CTE Kategori

```powershell
Get-Content latihan/p03/q06_cte_kategori.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q7 — Hierarki Pegawai

```powershell
Get-Content latihan/p03/q07_hierarki_pegawai.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q8 — Bawahan Bima

```powershell
Get-Content latihan/p03/q08_bawahan_bima.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q9 — Rekursi Tahan Siklus

```powershell
Get-Content latihan/p03/q09_rekursi_tahan_siklus.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q10 — Tiga Peringkat Tarif

```powershell
Get-Content latihan/p03/q10_tiga_peringkat_tarif.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q11 — Tiga Film Tertinggi

```powershell
Get-Content latihan/p03/q11_tiga_film_tertinggi.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q12 — Perubahan Omzet Harian

```powershell
Get-Content latihan/p03/q12_perubahan_omzet_harian.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q13 — Kumulatif & Rerata 7 Hari

```powershell
Get-Content latihan/p03/q13_kumulatif_rerata_7hari.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q14 — ROWS vs RANGE

```powershell
Get-Content latihan/p03/q14_rows_vs_range.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q15 — Riwayat Pembayaran Pelanggan

```powershell
Get-Content latihan/p03/q15_riwayat_pembayaran_pelanggan.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q16 — ROLLUP Kategori & Rating

```powershell
Get-Content latihan/p03/q16_rollup_kategori_rating.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q17 — Filter per Kategori

```powershell
Get-Content latihan/p03/q17_filter_per_kategori.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q18 — Rekonsiliasi Inventory & Rental

```powershell
Get-Content latihan/p03/q18_rekonsiliasi_inventory_rental.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q19 — Notifikasi Lunas

```powershell
Get-Content latihan/p03/q19_notifikasi_lunas.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q20 — Bentangkan Kontak

```powershell
Get-Content latihan/p03/q20_bentangkan_kontak.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### R1 — Laporan Bulanan

```powershell
Get-Content latihan/p03/r1_laporan_bulanan.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

---

## ◆ Catatan Q9

Q9 melakukan perubahan terhadap **relasi atasan secara sementara** untuk menguji rekursi dan kondisi siklus.

> **Penting:** Pastikan data dipulihkan setelah pengujian selesai agar basis data Pagila kembali ke kondisi semula.

---

## ◆ Struktur Folder

```text
latihan/
└── p03/
    ├── laporan.md
    ├── q00_setup.sql
    ├── q01_tarif_di_atas_rata.sql
    ├── q02_kategori_lebih_60.sql
    ├── q03_pelanggan_pembayaran_besar.sql
    ├── q04_film_tidak_pernah_disewa.sql
    ├── q05_tarif_tertinggi_per_toko.sql
    ├── q06_cte_kategori.sql
    ├── q07_hierarki_pegawai.sql
    ├── q08_bawahan_bima.sql
    ├── q09_rekursi_tahan_siklus.sql
    ├── q10_tiga_peringkat_tarif.sql
    ├── q11_tiga_film_tertinggi.sql
    ├── q12_perubahan_omzet_harian.sql
    ├── q13_kumulatif_rerata_7hari.sql
    ├── q14_rows_vs_range.sql
    ├── q15_riwayat_pembayaran_pelanggan.sql
    ├── q16_rollup_kategori_rating.sql
    ├── q17_filter_per_kategori.sql
    ├── q18_rekonsiliasi_inventory_rental.sql
    ├── q19_notifikasi_lunas.sql
    ├── q20_bentangkan_kontak.sql
    ├── r1_laporan_bulanan.sql
    └── README.md
```

---

## ◆ Anggota Kelompok

<div align="center">

| No. | Nama | NIM | Posisi |
|:---:|:---|:---:|:---|
| **01** | **Muhammad Lukman Toro** | `251402105` | **Project Manager** |
| **02** | **Khairunnisa** | `251402017` | Anggota |
| **03** | **Rumaisha Raghib Syahidah Siregar** | `251402034` | Anggota |
| **04** | **Muhammad Ihsan Anwar** | `251402044` | Anggota |
| **05** | **Randi Abdiansyah** | `251402138` | Anggota |

</div>

---

## ◆ Catatan

Seluruh query pada latihan ini dijalankan menggunakan **PostgreSQL 17** melalui container Docker dengan database **`pagila`**.

Pastikan container PostgreSQL aktif sebelum menjalankan file SQL.

---
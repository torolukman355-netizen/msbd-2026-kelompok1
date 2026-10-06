# README Latihan P04

## Prasyarat

- Docker Desktop aktif.
- Service `postgres` dari `docker-compose.yml` berjalan.
- Database `pagila` dan dump tersedia.
- `psql` tersedia di host atau container PostgreSQL.

Jalankan database dari root repository:

```bash
docker compose up -d postgres
```

## Menyiapkan Data

Jalankan [q00_setup.sql](q00_setup.sql) pada database `pagila`:

```bash
psql -h localhost -U msbd -d pagila -f latihan/p04/q00_setup.sql
```

Password sesuai `docker-compose.yml` adalah `msbd2026`.

## Urutan Q1–Q21

Jalankan file berikut berurutan pada database yang sama:

```text
q01_view_film_murah.sql
q02_baris_menghilang.sql
q03_check_option.sql
q04_view_pendapatan_kategori.sql
q05_query_dasar_akses.sql
q06_buat_matview.sql
q07_refresh_konkuren.sql
q08_analisis_kinerja.sql
q09_trigger_audit_baris.sql
q10_uji_audit_baris.sql
q11_null_pada_trigger.sql
q12_biaya_trigger_baris.sql
q13_trigger_pernyataan.sql
q14_check_not_valid.sql
q15_unique_soft_delete.sql
q16_fk_aksi_referensial.sql
q17_exclude_harga.sql
q18_expand_tulis_ganda.sql
q19_backfill_bertahap.sql
q20_contract_view_fasad.sql
```

Q21 memakai migration pada [migrations/](migrations/) secara berurutan dari `0041` sampai `0046`. Jangan menjalankan `0046` sebelum bukti Q20 terkumpul.

## Dua Sesi psql

Q8 membutuhkan dua sesi psql: sesi pertama menjalankan insert/refresh dan sesi kedua membaca materialized view. Q20 juga membutuhkan dua sesi. Pada sesi kedua, jalankan terus:

```sql
SELECT title, rental_rate FROM lab4.film LIMIT 5;
```

Sesi pembaca harus tetap aktif selama Q18, Q19, dan Q20 untuk membuktikan kompatibilitas aplikasi lama.

## Peringatan Rollback

Q20 dan `0046_contract_drop_kolom_lama.up.sql` bersifat destruktif. Setelah kolom fisik `rental_rate` dihapus, file down hanya membuat kolom kosong kembali; nilai lama tidak dapat dipulihkan. Simpan bukti view fasad dan stabilitas pembaca lama sebelum menjalankan 0046.

Simpan seluruh keluaran, screenshot, alasan keputusan, dan URL commit pada [laporan.md](laporan.md).

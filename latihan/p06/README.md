### Latihan Pertemuan 6: Indexing dan Anatomi Storage PostgreSQL


### Prasyarat
* Docker & Docker Compose
* DSN
* postgresql://msbd:msbd2026@localhost:5433/pagila


## Setup
- bash
- docker compose up -d
- docker exec -i msbd-pg psql -U msbd -d pagila < latihan/p06/q00_setup.sql


## Menjalankan Skrip
- bash
- docker exec -i msbd-pg psql -U msbd -d pagila < latihan/p06/q17_gin_jsonb.sql


## Isi Folder
- laporan.md: laporan kelompok (Q1-Q31)
- hasil_pengukuran.md: catatan mentah pengukuran
- q00_setup.sql ... q30_rekomendasi_index.sql: skrip soal
- explain/: output EXPLAIN (ANALYZE, BUFFERS)
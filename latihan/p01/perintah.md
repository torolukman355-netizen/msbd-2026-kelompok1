# Memverifikasi Docker
docker --version
docker compose version
docker run --rm hello-world

# Menjalankan Environment
mkdir -p dump
docker compose up -d
docker compose ps
docker compose logs postgres | tail -20

# Mengakses PostgreSQL dari psql
docker compose exec postgres psql -U msbd -d latihan

SELECT version();

\l
\dt
\dn
\du

SHOW data_directory;
SHOW shared_buffers;

# Mengakses PostgreSQL dari DBeaver
Host        : localhost
Port        : 5432
Database    : latihan
Username    : msbd
Password    : msbd2026

# Restore Pagila
1. Buat Database Kosong
docker compose exec postgres createdb -U msbd pagila

2. Restore Pagila
docker compose exec postgres pg_restore -U msbd -d pagila --no-owner /dump/pagila.dump

3. Verifikasi Tabel
docker compose exec postgres psql -U msbd -d pagila -c "\dt"


# Latihan Pertemuan 5: Dari Stored Procedure Sampai Endpoint HTTP

---

## 1. Prasyarat Sistem
* Docker & Docker Compose
* Python 3.10+
* Git Bash / Terminal Linux

---

## 2. Variabel DSN (Data Source Name)
Koneksi ke basis data PostgreSQL menggunakan variabel DSN berikut:
* **Format DSN psycopg 3 / Driver:**
  postgresql://msbd:msbd2026@localhost:5433/pagila
* **Format DSN SQLAlchemy ORM:**
  postgresql+psycopg://msbd:msbd2026@localhost:5433/pagila

*(Catatan: Port 5433 digunakan untuk menghindari konflik dengan PostgreSQL lokal).*

---

## 3. Cara Setup Skema lab5
1. Jalankan Kontainer Docker:
   docker compose up -d

2. Aktifkan Virtual Environment & Instal Dependensi:
   python -m venv .venv
   source .venv/bin/activate  # Di Windows Git Bash: source .venv/Scripts/activate
   pip install "psycopg[binary,pool]==3.2.*" "sqlalchemy==2.0.*" "fastapi==0.115.*" "uvicorn==0.32.*" "pydantic==2.*"

3. Eksekusi Skrip Setup & Stored Procedure:
   docker exec -i msbd-pg psql -U msbd -d pagila < latihan/p05/q00_setup.sql
   docker exec -i msbd-pg psql -U msbd -d pagila < latihan/p05/q02_process_rental.sql

---

## 4. Cara Menjalankan Tiga Program Python

1. Jalankan Skrip Driver (lab5_driver.py):
   python latihan/p05/lab5_driver.py

2. Jalankan Skrip ORM (lab5_orm.py):
   python latihan/p05/lab5_orm.py

3. Jalankan Server FastAPI (lab5_api.py):
   uvicorn latihan.p05.lab5_api:app --reload --port 8000
   *(Akses dokumentasi interaktif di http://127.0.0.1:8000/docs)*

---

## 5. Perintah cURL untuk Uji Endpoint (Q22–Q24)

Jalankan perintah ini di terminal terpisah saat server uvicorn sedang berjalan:

* Q22 · Uji Transaksi Valid (HTTP 201 Created):
  curl -s -X POST http://localhost:8000/rentals -H 'content-type: application/json' -d '{"customer_id":1,"inventory_id":1,"staff_id":1,"amount":4.99}'

* Q23 · Uji Amount Negatif (HTTP 422 Unprocessable Entity):
  curl -s -i -X POST http://localhost:8000/rentals -H 'content-type: application/json' -d '{"customer_id":1,"inventory_id":1,"staff_id":1,"amount":-4.99}'

* Q24 · Uji Inventory Tidak Ada (HTTP 409 Conflict):
  curl -s -i -X POST http://localhost:8000/rentals -H 'content-type: application/json' -d '{"customer_id":1,"inventory_id":999999,"staff_id":1,"amount":4.99}'
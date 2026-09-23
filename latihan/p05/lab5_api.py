# Diminta: menerjemahkan galat basis data menjadi respons HTTP yang aman.
# Dipilih: dependency psycopg ConnectionPool dan exception handler khusus untuk HTTP 409 & 422.
# Alternatif: membuka koneksi manual per request tanpa pool; tidak dipilih karena boros resource.

import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, status
from pydantic import BaseModel, Field
import psycopg
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

# Konfigurasi DSN
DSN = os.getenv("DSN", "postgresql://msbd:msbd2026@localhost:5433/pagila")

# Global Pool Variable
pool: ConnectionPool = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool
    pool = ConnectionPool(conninfo=DSN, min_size=2, max_size=5, open=False)
    pool.open()
    yield
    pool.close()

app = FastAPI(lifespan=lifespan)

# Q21 · Dependency Koneksi
def get_conn():
    with pool.connection() as conn:
        conn.row_factory = dict_row
        yield conn

# Schema Input dengan Pydantic
class RentalCreate(BaseModel):
    customer_id: int
    inventory_id: int
    staff_id: int
    amount: float = Field(..., gt=0, description="Amount harus bernilai positif")

# Q22–Q24 · Endpoint POST /rentals
@app.post("/rentals", status_code=status.HTTP_201_CREATED)
def create_rental(payload: RentalCreate, conn: psycopg.Connection = Depends(get_conn)):
    try:
        with conn.cursor() as cur:
            cur.execute(
                "CALL lab5.process_rental(%s, %s, %s, %s)",
                (payload.customer_id, payload.inventory_id, payload.staff_id, payload.amount)
            )
            cur.execute("SELECT max(rental_id) AS rental_id FROM lab5.rental_tx WHERE customer_id = %s", (payload.customer_id,))
            result = cur.fetchone()
            
            return {"rental_id": result["rental_id"], "message": "Rental berhasil diproses"}

    except psycopg.errors.ForeignKeyViolation:
        # Q24: Kirim HTTP 409 jika inventory_id/customer_id/staff_id tidak ada
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Data referensi (customer/inventory/staff) tidak ditemukan."
        )
    except psycopg.errors.CheckViolation:
        # Menangkap galat domain basis data jika lolos dari Pydantic
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Nilai pembayaran tidak valid."
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Terjadi kesalahan internal server."
        )
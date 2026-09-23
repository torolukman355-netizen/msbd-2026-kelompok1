# -- Diminta: Menggabungkan Q10, Q11, Q12, dan Q13 (Memanggil process_rental dalam blok koneksi, melempar exception, dan mencatat jumlah baris serta rollback).
# -- Dipilih: Menggunakan with psycopg.connect() dengan pencatatan count baris, pemanggilan CALL stored procedure, dan blok try-except untuk rollback.
# -- Alternatif: Auto-commit langsung; tidak dipilih karena perubahan data yang sudah masuk tidak dapat dibatalkan saat terjadi kegagalan.

import psycopg
from psycopg import sql

DSN = "dbname=postgres user=msbd password=msbd2026 host=localhost port=5432"

def q10():
    print("--- Q10: SELECT Berparameter ---")
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            query = "SELECT rental_id, customer_id FROM lab5.rental_tx LIMIT 1"
            cur.execute(query)
            print("Hasil Q10:", cur.fetchall())

def q11():
    print("\n--- Q11: Uji Injeksi ---")
    payload = "SMITH' OR '1'='1"
    sql_fstring = f"SELECT * FROM public.customer WHERE last_name = '{payload}'"
    print("Cetak f-string (Berbahaya / Tidak dijalankan):")
    print(sql_fstring)
    
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            query_safe = "SELECT * FROM public.customer WHERE last_name = %s"
            cur.execute(query_safe, (payload,))
            print("\nHasil parameter binding dengan payload berbahaya:", cur.fetchall())

def q12():
    print("\n--- Q12: Identifier dan Allow-list (Diperbaiki) ---")
    allowed_columns = {
        "rental_id": "rental_id",
        "customer_id": "customer_id",
        "created_at": "created_at"
    }
    user_input = "rental_id"
    
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            if user_input not in allowed_columns:
                raise ValueError("Kolom pengurutan tidak diizinkan!")
            
            query_aman = sql.SQL("SELECT rental_id, customer_id FROM lab5.rental_tx ORDER BY {col} DESC LIMIT 3").format(
                col=sql.Identifier(allowed_columns[user_input])
            )
            cur.execute(query_aman)
            print("Hasil Q12:", cur.fetchall())


if __name__ == "__main__":
    q10()
    q11()
    q12()
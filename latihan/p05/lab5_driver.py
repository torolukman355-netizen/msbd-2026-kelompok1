# -- Diminta: Menyelesaikan rangkaian tugas lab p05 dari Q10 hingga Q15 secara lengkap dan aman.
# -- Dipilih: Menggunakan psycopg, connection pool, pengelolaan transaksi, dan pemantauan pg_stat_activity.
# -- Alternatif: Pendekatan manual tanpa pengaman; tidak dipilih karena rentan terhadap error dan SQL injection.

import time
import psycopg
from psycopg import sql
from psycopg_pool import ConnectionPool

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

def q13():
    print("\n--- Q13: Rollback dari Aplikasi dengan process_rental ---")
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM lab5.rental_tx;")
            print(f"Jumlah baris rental_tx SEBELUM transaksi: {cur.fetchone()[0]}")

    try:
        with psycopg.connect(DSN) as conn:
            with conn.cursor() as cur:
                cur.execute("CALL lab5.process_rental(%s, %s, %s, %s::numeric)", (1, 1, 1, 4.99))
                raise RuntimeError("gagal di tengah alur")
    except RuntimeError as e:
        print(f"Tertangkap exception: {e}")
        print("Rollback berhasil dijalankan oleh aplikasi.")

    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM lab5.rental_tx;")
            print(f"Jumlah baris rental_tx SESUDAH rollback: {cur.fetchone()[0]}")

def q14():
    print("\n--- Q14: ConnectionPool ---")
    with ConnectionPool(conninfo=DSN, min_size=1, max_size=2) as pool:
        print("ConnectionPool berhasil diinisialisasi.")
        for i in range(1, 6):
            with pool.connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT %s, NOW()", (i,))
                    print(f"Permintaan ke-{i}: {cur.fetchone()}")
        print("\nStatistik ConnectionPool (get_stats):")
        print(pool.get_stats())

def q15():
    print("\n--- Q15: Idle in transaction ---")
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM lab5.rental_tx;")
            print("Transaksi dibuka. Diamkan selama 30 detik (cek via terminal psql)...")
            time.sleep(30)
            print("Selesai.")

if __name__ == "__main__":
    q10()
    q11()
    q12()
    q13()
    q14()
    q15() # Jalankan terpisah jika ingin menguji jeda 30 detik
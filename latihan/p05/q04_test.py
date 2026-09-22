import psycopg

DSN = "postgresql://msbd:msbd2026@localhost:5432/pagila"

with psycopg.connect(DSN) as conn:
    with conn.cursor() as cur:
        try:
            cur.execute("CALL lab5.process_rental_commit(1, 1, 1, 4.99)")
            print("BERHASIL (tidak diharapkan)")
        except Exception as e:
            print("ERROR:", type(e).__name__)
            print(e)
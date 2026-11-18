# Diminta: menguji pencarian pelanggan dan validasi pengurutan.
# Dipilih: parameter untuk pola pencarian dan daftar putih untuk ORDER BY.
# Alternatif: menyaring karakter masukan. Cara itu bisa mengubah nama sah seperti O'Neil.

import argparse
import sys


KOLOM = {"nama": "nama", "kota": "kota", "terbaru": "dibuat_pada"}
ARAH = {"naik": "ASC", "turun": "DESC"}
SQL_CARI = "SELECT id, nama, kota FROM lab11.pelanggan WHERE nama ILIKE %s"


def validasi_pengurutan(kolom, arah):
    if kolom not in KOLOM or arah not in ARAH:
        raise ValueError("parameter pengurutan tidak dikenal")
    return KOLOM[kolom], ARAH[arah]


def cari_aman(cur, kata, *, pembanding=False, pengurutan=None):
    batas = "" if pembanding else " LIMIT 100"
    query = SQL_CARI + batas
    templat = query
    if pengurutan is not None:
        from psycopg import sql

        kolom, arah = validasi_pengurutan(*pengurutan)
        query = sql.SQL(SQL_CARI + " ORDER BY {} {}, id ASC" + batas).format(
            sql.Identifier(kolom), sql.SQL(arah)
        )
        templat = query.as_string(cur)

    pola = f"%{kata}%"
    print("Templat SQL:", templat)
    print("Parameter ILIKE:", repr(pola))
    cur.execute(query, (pola,))
    return len(cur.fetchall())


def main():
    parser = argparse.ArgumentParser(description="Pencarian pelanggan penyewa 1 di lab11")
    parser.add_argument("kata", nargs="?", help="nilai pencarian nama")
    parser.add_argument("--pembanding", action="store_true", help="hitung tanpa LIMIT")
    parser.add_argument("--kolom", default="nama")
    parser.add_argument("--arah", default="naik")
    parser.add_argument("--urut", action="store_true", help="aktifkan ORDER BY")
    parser.add_argument("--validasi-urut", action="store_true", help="uji daftar putih tanpa DB")
    args = parser.parse_args()
    pengurutan = (args.kolom, args.arah)

    if args.urut or args.validasi_urut:
        try:
            kolom, arah = validasi_pengurutan(*pengurutan)
        except ValueError as exc:
            print(f"Ditolak: {exc}", file=sys.stderr)
            return 2
        if args.validasi_urut:
            print(f"Diterima: {kolom} {arah}")
            return 0

    if args.kata is None:
        parser.error("masukkan nilai pencarian")

    try:
        import psycopg
    except ImportError:
        print("Driver psycopg 3 diperlukan di lab11-web.", file=sys.stderr)
        return 1

    try:
        with psycopg.connect(dbname="msbd", user="app_laporan", connect_timeout=5) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT session_user, current_user, set_config('app.tenant', %s, true)", ("1",))
                login, peran, penyewa = cur.fetchone()
                print(f"Login={login} peran={peran} penyewa={penyewa}")
                jumlah = cari_aman(
                    cur, args.kata, pembanding=args.pembanding,
                    pengurutan=pengurutan if args.urut else None,
                )
                print(f"Jumlah baris: {jumlah}")
    except psycopg.Error as exc:
        print(f"SQLSTATE {exc.sqlstate or '-'}: {exc.diag.message_primary or exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
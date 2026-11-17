# Daftar putih nama kolom yang diperbolehkan.
KOLOM = {
    "nama": "nama",
    "kota": "kota",
    "terbaru": "dibuat_pada"
}

# Daftar putih arah pengurutan.
ARAH = {
    "naik": "ASC",
    "turun": "DESC"
}

# Validasi input pengguna sebelum menyusun query.
if kolom not in KOLOM or arah not in ARAH:
    raise ValueError("parameter pengurutan tidak dikenal")

# Menyusun query menggunakan identifier yang telah divalidasi.
sql = f"""
SELECT id, nama, kota
FROM lab11.pelanggan
ORDER BY {KOLOM[kolom]} {ARAH[arah]}
LIMIT %s
"""

cur.execute(sql, (100,))

# Pengujian input valid:
# kolom = "nama"
# arah = "naik"
#
# Pengujian input tidak valid:
# kolom = "nama; DROP TABLE pelanggan"
# arah = "naik"
#
# Hasil yang diharapkan:
# Input tidak valid menghasilkan ValueError.
#
# Penjelasan:
# Nama kolom dan arah pengurutan merupakan identifier SQL
# yang tidak dapat menggunakan placeholder parameter biasa.
# Oleh karena itu, digunakan allowlist untuk membatasi
# pilihan identifier hanya pada nilai yang telah ditentukan.
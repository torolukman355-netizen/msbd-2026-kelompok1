# Menggunakan parameterized query untuk mencegah SQL Injection.
# Input pengguna dikirim sebagai parameter terpisah dari struktur SQL.

cur.execute(
    "SELECT id, nama, kota FROM lab11.pelanggan "
    "WHERE nama ILIKE %s LIMIT 100",
    (f"%{kata}%",)
)

# Pengujian kembali menggunakan payload:
# zz' OR '1'='1' --
#
# Hasil yang diharapkan:
# Payload diperlakukan sebagai teks pencarian biasa,
# bukan sebagai bagian dari sintaks SQL.
#
# Penjelasan:
# Parameterized query memisahkan kode SQL dengan data pengguna.
# Dengan demikian, karakter khusus tidak dapat mengubah struktur
# maupun kondisi logika query.
#
# Penyaringan karakter saja tidak cukup karena pola serangan
# dapat bervariasi dan tidak semua karakter berbahaya dapat
# diidentifikasi melalui blacklist.
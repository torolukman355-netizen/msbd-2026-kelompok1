# Pengujian payload pertama
python rentan.py "zz' OR '1'='1"

# Pengujian payload kedua
python rentan.py "zz' OR '1'='1' --"

# Analisis:
# Payload pertama dapat menghasilkan 0 baris karena karakter
# tambahan dari query asli masih menempel pada input sehingga
# kondisi SQL yang terbentuk tidak sesuai dengan ekspresi logika
# yang dimaksudkan.
#
# Payload kedua menggunakan tanda komentar SQL (--), sehingga
# bagian query setelah komentar diabaikan oleh PostgreSQL.
#
# Kondisi '1'='1' selalu bernilai TRUE. Akibatnya, query dapat
# mengembalikan seluruh baris yang dapat diakses oleh akun database.
#
# Catat jumlah baris aktual dari kedua pengujian.
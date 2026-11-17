# Jalankan pengujian menggunakan akun app_laporan.
# Pastikan konfigurasi koneksi rentan.py menggunakan akun tersebut.

python rentan.py "zz' OR '1'='1' --"

# Analisis:
# SQL Injection masih dapat memengaruhi struktur query karena
# aplikasi belum menggunakan parameterized query.
#
# Namun, jumlah data yang dapat dibaca tetap dibatasi oleh
# hak akses app_laporan dan kebijakan Row-Level Security (RLS).
#
# Hal ini membuktikan prinsip Least Privilege, yaitu setiap akun
# aplikasi hanya diberikan hak akses sesuai kebutuhannya.
#
# RLS membatasi data yang dapat diakses, tetapi tidak menghilangkan
# penyebab SQL Injection.
#
# Catat jumlah baris aktual dan bandingkan dengan hasil Q13.
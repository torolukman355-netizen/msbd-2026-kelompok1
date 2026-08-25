# LAPORAN LATIHAN P01

# DOCKER

1. Output docker --version
   Docker version 29.7.2, build a7dcaa6

2. Output docker compose version
   Docker Compose version v5.4.0

3. Output docker compose ps
   NAME IMAGE COMMAND SERVICE CREATED STATUS PORTS
   msbd-mongo mongo:8 "docker-entrypoint.s…" mongo About an hour ago Up About an hour 0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
   msbd-pg postgres:17 "docker-entrypoint.s…" postgres About an hour ago Up About an hour (healthy) 0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
   msbd-redis redis:7-alpine "docker-entrypoint.s…" redis About an hour ago Up About an hour 0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp

4. Output SELECT version();
   version

---

PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(1 row)

                                                 List of databases

Name | Owner | Encoding | Locale Provider | Collate | Ctype | Locale | ICU Rules | Access privileges
-----------+-------+----------+-----------------+------------+------------+--------+-----------+-------------------
latihan | msbd | UTF8 | libc | en_US.utf8 | en_US.utf8 | | |
pagila | msbd | UTF8 | libc | en_US.utf8 | en_US.utf8 | | |
postgres | msbd | UTF8 | libc | en_US.utf8 | en_US.utf8 | | |
template0 | msbd | UTF8 | libc | en_US.utf8 | en_US.utf8 | | | =c/msbd +
| | | | | | | | msbd=CTc/msbd
template1 | msbd | UTF8 | libc | en_US.utf8 | en_US.utf8 | | | =c/msbd +
| | | | | | | | msbd=CTc/msbd
(5 rows)

Did not find any relations.
List of schemas
Name | Owner
--------+-------------------
public | pg_database_owner
(1 row)

     List of roles

Role name | Attributes
-----------+------------

\du: extra argument "data_directory;" ignored
\du: extra argument "SHOW" ignored
\du: extra argument "shared_buffers;" ignored
Timing is on.

# PERTANYAAN LANGKAH 1

1. Apa yang dimaksud dengan Docker Image?
   `Docker Image adalah sebuah paket yang berisi semua kebutuhan untuk menjalankan suatu aplikasi, seperti kode program, library, dependency, dan konfigurasi. Image digunakan sebagai dasar untuk membuat container.`

2. Apa yang dimaksud dengan Container?
   `Container adalah lingkungan terisolasi yang dibuat dari Docker Image untuk menjalankan aplikasi. Container membuat aplikasi dapat berjalan dengan lingkungan dan dependency yang sudah ditentukan tanpa banyak memengaruhi sistem utama.`

3. Apa fungsi Volume?
   `Volume berfungsi untuk menyimpan data dari container secara permanen. Dengan volume, data tidak ikut hilang ketika container dihapus atau dibuat ulang, sehingga cocok untuk menyimpan database, file, atau data aplikasi.`

# PERTANYAAN LANGKAH 2

1. Apa yang terjadi jika bagian volumes: pada layanan PostgreSQL dihapus, kemudian container dihentikan menggunakan docker compose down -v?
   `Kalau volumes: dihapus, data database cuma nyimpen di dalam container doang, nggak ada backup di luar. Terus kalau pakai down -v, itu bakal ngehapus volume juga pas container-nya dimatiin. Jadi hasilnya: semua data ilang total, nggak bisa balik lagi.`

2. Mengapa pemetaan port ditulis "5432:5432" dan bukan cukup satu angka? Apa yang harus diubah apabila komputer Anda sudah memiliki PostgreSQL lain yang menggunakan port 5432?
   `Karena ada dua sisi: angka kiri itu port di laptop kita, angka kanan itu port di dalam container. Ditulis dua-duanya biar bisa beda kalau perlu. Kalau di laptop udah ada PostgreSQL lain yang pakai port 5432, tinggal ganti angka sebelah kiri aja, misal jadi "5433:5432". Port di dalam container tetap 5432, tapi diakses dari laptop lewat 5433 biar nggak bentrok.`

3. Apa fungsi blok healthcheck? Mengapa healthcheck penting ketika terdapat layanan lain yang bergantung pada basis data?
   `Healthcheck itu buat ngecek apakah database-nya udah beneran siap dipakai, bukan cuma "container-nya nyala" doang. Soalnya container udah running belum tentu PostgreSQL-nya udah selesai loading dan siap nerima koneksi. Ini penting kalau ada service lain yang butuh nyambung ke database ini. Tanpa healthcheck, service itu bisa nyoba connect kecepetan pas database-nya belum siap, jadi error. Dengan healthcheck, service lain bisa nunggu sampai statusnya healthy dulu baru jalan.`

4. Menyimpan password langsung di dalam docker-compose.yml merupakan praktik yang kurang baik. Sebutkan satu cara yang lebih aman dan jelaskan mengapa hal tersebut penting ketika berkas masuk ke repositori Git.
   `Simpan password di file .env, terus di docker-compose.yml tinggal panggil pakai ${POSTGRES_PASSWORD}, jangan ditulis langsung. Ini penting karena kalau file compose-nya di-push ke GitHub, orang lain yang buka repo bisa langsung liat passwordnya kalau ditulis langsung di situ. Kalau pakai .env, file itu bisa dimasukin ke .gitignore jadi nggak ikut ke-push, password tetap aman meski repo-nya kebuka buat orang lain.`

# PERTANYAAN LANGKAH 3

1. Satu aktivitas yang menurut Anda lebih cepat dilakukan menggunakan psql.
   `Inspeksi cepat metadata dan scripting/automasi: Menjalankan perintah pintas (meta-commands) seperti mengecek daftar tabel (\dt), melihat daftar database (\l), atau mengeksekusi skrip SQL / dump secara langsung dari terminal tanpa overhead antarmuka grafis atau waktu loading GUI.`

2. Satu aktivitas yang menurut Anda lebih cepat dilakukan menggunakan DBeaver.
   `Eksplorasi visual dan relasi data (ER Diagram): Melihat diagram relasi antartabel (Entity-Relationship Diagram), menjelajah data dalam bentuk spreadsheet interaktif, serta melakukan filter, sort, atau pengeditan data baris per baris secara visual tanpa perlu menulis query SQL manual.`

3. Perbandingan psql dan DBeaver
   `psql lebih cepat digunakan untuk menjalankan perintah SQL, mengecek metadata, serta melakukan scripting melalui terminal, sedangkan DBeaver lebih unggul untuk eksplorasi database secara visual seperti melihat tabel, ER Diagram, dan mengelola data dengan antarmuka grafis.`

# HASIL QUERY

1. V1
   count
   21

2. V2
   relname ukuran
   rental 2352 kB
   film 952 kB
   payment_p2017_04 656 kB
   payment_p2017_03 568 kB
   film_actor 488 kB
   inventory 440 kB
   payment_p2017_02 296 kB
   payment_p2017_01 248 kB
   customer 216 kB
   address 160 kB

3. V3
   title total_sewa
   BUCKET BROTHERHOOD 34
   ROCKETEER MOTHER 33
   RIDGEMONT SUBMARINE 32
   SCALAWAG DUCK 32
   FORWARD TEMPLE 32

4. V4
   QUERY PLAN
   HashAggregate (cost=713.69..723.69 rows=1000 width=23) (actual time=16.628..16.765 rows=958 loops=1)
   Group Key: f.title
   Batches: 1 Memory Usage: 193kB
   -> Hash Join (cost=238.57..633.47 rows=16044 width=15) (actual time=2.458..12.258 rows=16044 loops=1)
   Hash Cond: (i.film_id = f.film_id)
   -> Hash Join (cost=128.07..480.67 rows=16044 width=2) (actual time=1.549..8.145 rows=16044 loops=1)
   Hash Cond: (r.inventory_id = i.inventory_id)
   -> Seq Scan on rental r (cost=0.00..310.44 rows=16044 width=4) (actual time=0.013..1.437 rows=16044 loops=1)
   -> Hash (cost=70.81..70.81 rows=4581 width=6) (actual time=1.438..1.440 rows=4581 loops=1)
   Buckets: 8192 Batches: 1 Memory Usage: 234kB
   -> Seq Scan on inventory i (cost=0.00..70.81 rows=4581 width=6) (actual time=0.009..0.600 rows=4581 loops=1)
   -> Hash (cost=98.00..98.00 rows=1000 width=19) (actual time=0.838..0.839 rows=1000 loops=1)
   Buckets: 1024 Batches: 1 Memory Usage: 60kB
   -> Seq Scan on film f (cost=0.00..98.00 rows=1000 width=19) (actual time=0.043..0.566 rows=1000 loops=1)
   Planning Time: 0.677 ms
   Execution Time: 17.124 ms

   `_Yang paling membingungkan dari keluaran ini adalah banyaknya struktur hierarki teks dan format angka waktu (actual time) yang sulit dipahami secara visual pada query plan_`

# TAUTAN REPOSITORY

https://github.com/torolukman355-netizen/msbd-2026-kelompok1/

# COMMIT ANGGOTA KELOMPOK
Commits on Aug 26, 2026
Finishing: Penyelesaian seluruh tugas
MuhammadIhsanAnwar committed 1 minutes ago

Commits on Aug 25, 2026
Tahap 4: menyelesaikan restore pagila dan query verifikasi V1-V4
rumaisharaghibsrg committed yesterday

Commits on Aug 23, 2026
langkah 3
torolukman355-netizen committed 2 days ago

step 2
randii-tech committed 2 days ago

latihan
torolukman355-netizen committed 2 days ago

Cek Docker dan Buat folder awal msbd-2026
Khairunnisa017 committed 2 days ago

# TANTANGAN TAMBAHAN

1. Sebelum index dibuat, waktu pencarian adalah 0,134 detik, sedangkan setelah index dibuat menjadi 0,002 detik. Dengan demikian, penggunaan index berhasil mempercepat proses pencarian secara signifikan, yaitu sekitar 67 kali lebih cepat. Perbedaan waktu terjadi karena index membantu PostgreSQL menemukan data pada kolom nilai tanpa harus memeriksa seluruh 2.000.000 baris. Sebelum menggunakan index, PostgreSQL harus melakukan pencarian secara berurutan (sequential scan), sedangkan setelah index dibuat, PostgreSQL dapat menggunakan index scan untuk menemukan data dengan lebih cepat. Oleh karena itu, waktu pencarian berkurang dari 0,134 detik menjadi 0,002 detik.

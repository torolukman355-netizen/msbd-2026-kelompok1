**Q23. Perbandingan Konfigurasi Timeout pada PostgreSQL**

PostgreSQL menyediakan beberapa parameter *timeout* untuk mengontrol dan mencegah transaksi yang menggantung. Berikut adalah fungsi masing-masing:

**1. lock_timeout**
* **Fungsi:** Menentukan batas waktu maksimal sebuah *statement* (query) diizinkan untuk menunggu dalam antrean demi mendapatkan *lock* (baik tabel maupun baris).
* **Perilaku:** Jika *lock* tidak didapatkan dalam waktu yang ditentukan, query tersebut akan langsung dibatalkan. Ini sangat berguna untuk mencegah aplikasi *hang* karena antrean *lock* panjang.

**2. statement_timeout**
* **Fungsi:** Menentukan batas waktu maksimal keseluruhan eksekusi sebuah *statement* (query) dari awal hingga akhir, terlepas dari apakah query tersebut lambat karena komputasi berat, pencarian data yang masif, atau karena menunggu *lock*.
* **Perilaku:** Jika query berjalan melebihi batas waktu ini, prosesnya akan dibatalkan.

**3. idle_in_transaction_session_timeout**
* **Fungsi:** Menentukan batas waktu maksimal sebuah sesi diizinkan berstatus menganggur (*idle*) ketika sedang berada di dalam transaksi yang aktif (sudah menjalankan `BEGIN` tetapi belum `COMMIT` atau `ROLLBACK`).
* **Perilaku:** Jika aplikasi menahan transaksi terbuka tanpa mengirim query apa pun melebihi batas waktu ini, PostgreSQL akan membatalkan transaksi dan memutus/menutup sesi tersebut. Ini adalah pertahanan utama terhadap aplikasi yang *crash* atau *buggy* yang menahan *lock* secara tidak sengaja (mencegah *long lock queues*).

**4. deadlock_timeout**
* **Fungsi:** Menentukan batas waktu tunggu sebelum PostgreSQL repot-repot menjalankan algoritma pendeteksian *deadlock* (pemeriksaan siklus/graf tunggu) yang memakan banyak memori dan CPU.
* **Perilaku:** Secara default nilainya adalah 1 detik. Ini **bukan** batas waktu untuk membatalkan antrean normal, melainkan hanya ambang batas pemicu. Jika antrean berlangsung lebih dari 1 detik, sistem akan memeriksa apakah itu adalah antrean lurus (dibiarkan) atau *deadlock* (salah satu dibatalkan).
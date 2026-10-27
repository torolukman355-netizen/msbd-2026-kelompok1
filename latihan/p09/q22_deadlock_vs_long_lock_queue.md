**Q22. Perbedaan Deadlock dan Antrean Lock Panjang**

Meskipun sama-sama menyebabkan transaksi terhenti atau menunggu (*blocking*), *deadlock* dan antrean *lock* panjang memiliki akar masalah dan penanganan sistem yang berbeda:

**1. Deadlock (Kebuntuan)**
* **Definisi:** Terjadi ketika dua atau lebih transaksi saling mengunci baris yang dibutuhkan satu sama lain sehingga membentuk siklus saling tunggu yang melingkar (*circular wait*). Misalnya: Transaksi A menunggu Transaksi B, dan Transaksi B menunggu Transaksi A.
* **Perilaku Sistem:** Karena kebuntuan ini tidak akan pernah selesai dengan sendirinya, PostgreSQL harus melakukan intervensi. Setelah melewati batas waktu `deadlock_timeout` (biasanya 1 detik), sistem akan menjalankan algoritma pendeteksi siklus. Jika terdeteksi, PostgreSQL akan membatalkan salah satu transaksi secara paksa (memunculkan error `SQLSTATE 40P01`) agar transaksi lainnya bisa berjalan.

**2. Antrean Lock Panjang (Long Lock Queue)**
* **Definisi:** Terjadi ketika satu transaksi memegang *lock* dalam waktu yang sangat lama, sehingga transaksi-transaksi lain menumpuk dalam satu garis lurus untuk mendapatkan *lock* tersebut (Transaksi B, C, dan D semuanya menunggu Transaksi A).
* **Perilaku Sistem:** Tidak ada siklus melingkar di sini. Selama tidak terdeteksi *circular wait*, PostgreSQL **tidak akan** membatalkannya sebagai *deadlock*. Sistem akan membiarkan transaksi lain mengantre selamanya, kecuali ada pembatasan waktu seperti `lock_timeout` atau `statement_timeout` yang dikonfigurasi.

**Contoh Kasus Antrean Lock Panjang:**
Sebuah aplikasi memulai transaksi (`BEGIN`), mengunci baris pengguna (`SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;`), lalu aplikasi tersebut mengalami *crash*, kehilangan koneksi jaringan, atau melakukan proses komputasi yang sangat lambat sebelum memanggil `COMMIT`. Transaksi tersebut menjadi *idle in transaction* dan menahan *lock*, membuat semua transaksi dari pengguna lain yang ingin mengakses rekening 1 tertahan (mengantre) tanpa batas waktu.
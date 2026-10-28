Latihan P09 - Menguji Transaksi dan Kendali Konkurensi

Metadata eksperimen
- Database server: PostgreSQL 17 dari image Docker `postgres:17`.
- Client: `psql 17.11`; dua terminal PowerShell sebagai Sesi A dan Sesi B.
- Database dan role: `latihan` dan `msbd`; eksperimen dibatasi ke skema `lab9`.
- Konfigurasi yang dicatat: `deadlock_timeout = 1s`, `lock_timeout = 0`,
  `statement_timeout = 0`, `idle_in_transaction_session_timeout = 0`.
  Timeout uji Q23 memakai `SET LOCAL lock_timeout = '2s'` di dalam transaksi;
  tidak ada timeout global yang diubah.
- Penggunaan AI: AI membantu menyusun dan merapikan skrip/laporan serta
  menginterpretasikan urutan eksperimen. Perintah dijalankan oleh anggota
  kelompok; hasil yang dicatat berasal dari output psql dan bukti kelompok.

Langkah 1 (Q1 sampai Q5)

Catatan: hasil Q1-Q5 di bawah sudah dijalankan setelah q00_setup.sql. Simpan
transkrip sesi sebagai bukti pengumpulan.

Q1 Kondisi awal dan total saldo
Setelah q00_setup.sql dijalankan pada PostgreSQL dalam container Docker, hasil
menunjukkan rekening 1 (Ani) dan rekening 2 (Budi), masing-masing bersaldo
1000000.00. Query COUNT dan SUM menghasilkan 2 rekening dan total saldo
2000000.00.

Q2 Perubahan sebelum COMMIT
Sesi A menjalankan BEGIN dan mengurangi saldo rekening 1 sebesar 100000.
SELECT di Sesi A menampilkan 900000.00. Saat transaksi A masih terbuka, SELECT
di Sesi B menampilkan 1000000.00 (nilai sebelum perubahan), sehingga perubahan
belum di-COMMIT tidak terlihat oleh sesi lain. Setelah A menjalankan COMMIT,
SELECT berikutnya di Sesi B menampilkan 900000.00. PostgreSQL yang dipakai
melaporkan versi psql 17.11.

Q3 Perbandingan COMMIT dan ROLLBACK
Setelah Q2, Sesi A mengurangi saldo rekening 1 sebesar 50000. SELECT di dalam
transaksi menampilkan 850000.00. Setelah ROLLBACK, SELECT berikutnya menampilkan
900000.00. Perubahan Q2 bertahan karena di-COMMIT; perubahan Q3 tidak bertahan
karena di-ROLLBACK.

Q4 SAVEPOINT
Sesi A mengurangi saldo rekening 1 sebesar 10000, membuat SAVEPOINT, lalu
mengurangi saldo rekening 2 sebesar 20000. Sebelum ROLLBACK TO SAVEPOINT, SELECT
menampilkan saldo rekening 1 sebesar 890000.00 dan rekening 2 sebesar 980000.00.
Setelah rollback ke savepoint, SELECT menampilkan rekening 1 sebesar 890000.00
dan rekening 2 sebesar 1000000.00. Dengan demikian, perubahan sebelum savepoint
tetap ada, sedangkan perubahan sesudahnya dibatalkan. Transaksi kemudian di-
COMMIT; perubahan rekening 1 sebesar 10000 tersimpan.

Q5 Atomicity dan consistency
Atomicity terlihat dari COMMIT yang mempertahankan perubahan transaksi dan
ROLLBACK yang membatalkannya. Pada Q3, perubahan saldo dari 900000.00 menjadi
850000.00 dibatalkan dan nilai kembali ke 900000.00. SAVEPOINT memungkinkan
pembatalan sebagian transaksi tanpa membatalkan perubahan sebelumnya. Consistency
dibantu constraint CHECK (saldo >= 0): percobaan mengubah saldo rekening 2
menjadi -1 ditolak dengan SQLSTATE 23514 (check_violation), constraint
rekening_saldo_check pada skema lab9, tabel rekening. Setelah ROLLBACK TO
SAVEPOINT, SELECT menunjukkan saldo rekening 2 tetap 1000000.00 dan transaksi
berhasil di-COMMIT. Satu COMMIT tambahan setelah transaksi ditutup menghasilkan
warning SQLSTATE 25P01 (there is no transaction in progress); warning tersebut
berasal dari COMMIT berulang dan tidak mengubah data.

Langkah 2 (Q6 sampai Q11)

Q6 Non-repeatable read
Pada tingkat isolasi bawaan yaitu READ COMMITTED, data yang sama dapat dibaca dengan nilai yang berbeda dalam satu transaksi jika transaksi lain telah mengubah data tersebut dan melakukan COMMIT. Saat Sesi A melakukan SELECT pertama, saldonya 1000000. Setelah Sesi B mengubahnya menjadi 900000 dan melakukan auto-commit, SELECT kedua di Sesi A membaca saldo baru yaitu 900000.

Q7 Perbandingan isolation
Ketika Sesi A menggunakan tingkat isolasi REPEATABLE READ, data akan ditahan dalam sebuah snapshot sejak kueri pertama dijalankan. Walaupun Sesi B berhasil melakukan UPDATE dan COMMIT menjadi 800000, Sesi A akan tetap membaca nilai 1000000 pada SELECT keduanya. Perbedaan mendasarnya adalah REPEATABLE READ menjamin data yang dibaca tetap konsisten sepanjang transaksi berlangsung.

Q8 Phantom read
Pada READ COMMITTED, Sesi A mengalami phantom read. Saat Sesi A menghitung baris di tengah transaksi, Sesi B memasukkan baris baru. Pembacaan kedua oleh Sesi A melihat baris "siluman" tersebut. Namun, saat diuji menggunakan REPEATABLE READ, Sesi A tidak melihat baris baru yang dimasukkan Sesi B. Hal ini membuktikan bahwa arsitektur MVCC pada PostgreSQL mampu mencegah phantom read pada level REPEATABLE READ, membuat level ini jauh lebih kuat dari standar SQL tradisional.

Q9 Dirty read
Sesi B mencoba membaca data dengan mengatur isolasi menjadi READ UNCOMMITTED. Saat Sesi A mengubah data tanpa melakukan COMMIT, Sesi B ternyata tidak dapat melihat perubahan tersebut. Perilaku ini terjadi karena mesin PostgreSQL dirancang untuk tidak mendukung Dirty Read sama sekali. Level READ UNCOMMITTED di dalam PostgreSQL otomatis dieksekusi sebagai READ COMMITTED.

Q10 Lost update
Lost update berhasil direproduksi ketika dua transaksi membaca nilai yang sama, memproses kalkulasi secara terpisah di luar database, lalu menuliskannya kembali sebagai nilai absolut. Sesi A ingin mengurangi 100000 dan Sesi B ingin mengurangi 50000. Keduanya mengira saldo awal 1000000, sehingga Sesi A menembak angka 900000 dan Sesi B menembak angka 950000. Karena Sesi B dieksekusi belakangan (setelah lock Sesi A dilepas), tulisan Sesi A sebesar 900000 hilang ditelan oleh tulisan Sesi B sebesar 950000.

Q11 Tabel Ringkasan Anomali
1. Non-repeatable read: Sesi A baca, Sesi B update+commit, Sesi A baca lagi nilainya beda. Isolation level yang diamati adalah READ COMMITTED. Cara mencegahnya adalah dengan menaikkan isolasi ke REPEATABLE READ.
2. Phantom read: Sesi A hitung baris, Sesi B insert+commit, Sesi A hitung lagi jumlahnya bertambah. Isolation level yang diamati adalah READ COMMITTED. Cara mencegahnya adalah menggunakan REPEATABLE READ.
3. Dirty read: Sesi A update (tanpa commit), Sesi B baca data. Di PostgreSQL tidak bisa diamati karena dicegah otomatis secara internal, meskipun Sesi B menggunakan READ UNCOMMITTED.
4. Lost update: Sesi A dan B baca data bersamaan, lalu update dengan nilai absolut secara berurutan menimpa satu sama lain. Isolation level yang diamati adalah READ COMMITTED. Cara mencegahnya adalah dengan melakukan update relatif (saldo = saldo - x) di level database, menggunakan SELECT FOR UPDATE, atau menaikkan level ke REPEATABLE READ/SERIALIZABLE.

Langkah 3 (Q12 sampai Q17)

Q12 Perbaikan Lost Update (Atomic Update)
Menghitung berdasarkan nilai kolom di database (misal: saldo = saldo - 10000) jauh lebih aman daripada membaca nilai, menghitung di aplikasi, lalu menulis nilai absolut (misal: saldo = 900000). Atomic update memastikan bahwa database menggunakan nilai terakhir yang ada di disk tepat pada saat UPDATE dieksekusi, sehingga perubahan dari transaksi lain yang masuk sepersekian detik sebelumnya tidak tertimpa begitu saja.

Q13 SELECT ... FOR UPDATE (Pessimistic Locking)
Ketika Sesi A mengeksekusi SELECT ... FOR UPDATE, Sesi B yang menjalankan perintah serupa akan langsung berstatus *waiting* (menunggu). Sesi B baru akan melanjutkan proses pencarian dan pengunciannya segera setelah Sesi A mengeksekusi COMMIT atau ROLLBACK. Cara ini sangat efektif untuk skenario antrean di mana kita ingin memastikan hanya satu transaksi yang dapat memanipulasi baris tertentu pada satu waktu.

Q14 Optimistic Locking dengan Kondisi Nilai
Jika tidak ingin menggunakan FOR UPDATE yang menahan transaksi (blocking), kita bisa menambahkan kondisi nilai yang dibaca pada klausa WHERE (misalnya WHERE rekening_id = 2 AND saldo = 950000). Jika transaksi lain sudah mengubah saldo tersebut, kueri UPDATE ini akan mengembalikan "UPDATE 0". Aplikasi kemudian mengetahui bahwa data sudah berubah, lalu dapat melakukan pembatalan atau mengulangi proses (retry).

Q15 MVCC (Multi-Version Concurrency Control)
Secara konseptual, saat terjadi UPDATE, PostgreSQL tidak menimpa data asli di tempat. Alih-alih, ia membuat "versi baru" dari baris tersebut. Transaksi yang sedang berjalan (Sesi A) melihat versi baru ini. Transaksi lain (Sesi B) yang melakukan SELECT akan diarahkan untuk membaca "versi lama" yang masih valid untuk snapshot mereka. Inilah sebabnya pembaca (SELECT) tidak perlu menunggu penulis (UPDATE) selesai.

Q16 Metadata xmin dan xmax
Kolom xmin menyimpan ID transaksi yang menciptakan (INSERT/UPDATE) versi baris tersebut, sedangkan xmax menyimpan ID transaksi yang menghapus atau menimpa (UPDATE/DELETE) baris tersebut. Keduanya adalah metadata internal mesin PostgreSQL. Satu nilai saja tidak cukup untuk mendiagnosis visibilitas karena kita harus mencocokkannya dengan daftar transaksi yang sedang aktif (pg_stat_activity) untuk mengetahui apakah xmax tersebut berasal dari transaksi yang sudah di-commit atau masih menggantung.

Q17 Manfaat MVCC dan Vacuum
Manfaat utama MVCC adalah performa konkurensi yang sangat tinggi karena operasi baca dan tulis tidak saling mengunci. Namun, karena UPDATE membuat versi baris baru, versi baris lama (dead tuples) akan terus menumpuk di dalam disk (tabel bloat). Oleh karena itu, proses VACUUM sangat diperlukan untuk menyapu bersih versi-versi baris lama yang sudah tidak lagi terlihat oleh transaksi mana pun, agar ruang penyimpanannya bisa digunakan kembali.

Langkah 4 (Q18 sampai Q23)

Q18 Perbandingan row lock
FOR UPDATE: kunci terkuat. Dipakai saat baris akan di-UPDATE/DELETE atau kunci/kolom kuncinya bisa berubah. Memblokir transaksi lain yang mau UPDATE, DELETE, FOR UPDATE, FOR NO KEY UPDATE, FOR SHARE, maupun FOR KEY SHARE pada baris yang sama.
FOR NO KEY UPDATE: seperti FOR UPDATE tetapi lebih lemah; dipakai saat baris akan diubah tanpa mengubah kolom kunci (PRIMARY KEY/UNIQUE yang dirujuk FK). Tidak memblokir FOR KEY SHARE, jadi insert pada tabel anak (FK) tetap bisa jalan. Ini kunci yang diambil UPDATE biasa.
FOR SHARE: kunci bersama; beberapa transaksi boleh memegang FOR SHARE sekaligus, dipakai agar baris tidak berubah selama dibaca. Memblokir UPDATE, DELETE, FOR UPDATE, FOR NO KEY UPDATE.
FOR KEY SHARE: kunci terlemah, hanya menjaga kunci baris tidak berubah/terhapus (dipakai internal oleh foreign key). Hanya diblokir oleh FOR UPDATE (dan DELETE / UPDATE yang mengubah kunci).

Q19 FOR UPDATE pada baris yang sama
Sesi A BEGIN lalu SELECT rekening 1 FOR UPDATE: langsung berhasil. Sesi B menjalankan perintah yang sama dan menggantung (menunggu), tidak ada hasil dan tidak ada error. Setelah Sesi A COMMIT, Sesi B langsung mendapat hasil dan memegang kunci. Artinya satu baris hanya bisa dikunci satu transaksi dalam satu waktu.

Q20 Deadlock
Sesi A mengunci rekening 1, Sesi B mengunci rekening 2. Sesi A minta rekening 2 (menunggu B), Sesi B minta rekening 1 (menunggu A): saling menunggu, tidak ada yang bisa maju. Setelah deadlock_timeout (1 detik) PostgreSQL mendeteksi siklus ini dan membatalkan Sesi B dengan ERROR: deadlock detected, SQLSTATE 40P01. Sesi B di-ROLLBACK; Sesi A lalu memperoleh lock rekening 2 dan kedua sesi di-ROLLBACK setelah percobaan.

Q21 Urutan penguncian konsisten
Jika semua sesi mengunci dari rekening_id terkecil ke terbesar (1 lalu 2), Sesi B akan menunggu di rekening 1 dan tidak memegang rekening 2 saat menunggu. Tidak ada siklus tunggu, jadi tidak terjadi deadlock; B hanya menunggu sebentar lalu lanjut setelah A COMMIT. Deadlock dapat dihindari pada skenario ini.

Q22 Deadlock vs antrean lock panjang
Deadlock: siklus saling tunggu, tidak akan selesai sendiri; PostgreSQL memutus dengan membatalkan satu transaksi (40P01). Antrean lock panjang: tidak ada siklus; sesi menunggu transaksi lain yang masih menahan lock (misalnya transaksi yang di-BEGIN, UPDATE, lalu dibiarkan terbuka tanpa COMMIT). Tidak ada error; sesi lain menggantung selama pemegang lock belum selesai. Pada percobaan, Sesi A UPDATE rekening 1 tanpa COMMIT, Sesi B UPDATE baris yang sama menggantung, dan pg_blocking_pids menunjukkan B diblokir oleh pid A. Selesai begitu A COMMIT/ROLLBACK. Mitigasi: transaksi dibuat singkat, lock_timeout, idle_in_transaction_session_timeout.

Q23 Perbandingan timeout
lock_timeout: batas waktu menunggu untuk mendapatkan lock; lewat dari itu perintah dibatalkan (55P03). Default 0 (tanpa batas).
statement_timeout: batas waktu eksekusi satu pernyataan secara keseluruhan; lewat dari itu dibatalkan (57014). Default 0.
idle_in_transaction_session_timeout: batas waktu sesi yang sudah BEGIN tetapi diam tanpa perintah; sesi diputus (25P03). Berguna melawan transaksi yang lupa COMMIT dan menahan lock.
deadlock_timeout: berapa lama sesi menunggu lock sebelum PostgreSQL mulai memeriksa apakah terjadi deadlock (default 1 detik). Ini bukan batas membatalkan permintaan lock biasa, hanya pemicu pemeriksaan deadlock.

Langkah 5 (Q24 sampai Q29)

Q24 SKIP LOCKED
Sesi A mengunci baris id=1 (FOR UPDATE). Sesi B menjalankan SELECT ... FOR UPDATE SKIP LOCKED LIMIT 1 dan langsung mendapat baris id=2; baris id=1 yang terkunci dilewati, tanpa menunggu. Kegunaan: worker antrean. Banyak worker bisa mengambil pekerjaan berbeda secara paralel tanpa saling menunggu dan tanpa mengambil pekerjaan yang sama.

Q25 NOWAIT
Sesi B menjalankan SELECT ... FOR UPDATE NOWAIT pada baris id=1 yang dikunci Sesi A: langsung gagal dengan ERROR: could not obtain lock on row in relation "antrean" (SQLSTATE 55P03), tanpa menunggu. Cocok bila aplikasi lebih baik gagal cepat dan memberi pesan "sedang diproses" daripada menggantung. Transaksi B harus di-ROLLBACK.

Q26 Write skew (REPEATABLE READ)
Aturan: minimal satu dokter aktif. Sesi A dan B sama-sama membaca jumlah dokter aktif = 2. A menonaktifkan dokter 1 lalu COMMIT, B menonaktifkan dokter 2 lalu COMMIT. Keduanya berhasil karena mengubah baris berbeda (tidak ada konflik tulis) dan masing-masing membaca snapshot lama. Hasil akhir: 0 dokter aktif, aturan bisnis dilanggar. Inilah write skew; REPEATABLE READ tidak mencegahnya.

Q27 SERIALIZABLE
Skenario sama dengan SERIALIZABLE: kedua sesi membaca count = 2 sebelum ada yang COMMIT. Sesi B dibatalkan saat menjalankan UPDATE dengan ERROR: could not serialize access due to read/write dependencies among transactions, SQLSTATE 40001, HINT: The transaction might succeed if retried. Sesi B di-ROLLBACK. Hasil akhir hanya satu dokter nonaktif, aturan terjaga. Transaksi yang gagal harus diulang dari awal.

Q28 SIReadLock
SIReadLock adalah predicate lock yang dicatat PostgreSQL pada transaksi SERIALIZABLE untuk melacak apa yang dibaca (tabel/halaman/baris). Ia bukan lock yang memblokir; transaksi lain tidak menunggu karenanya. Gunanya agar PostgreSQL bisa mendeteksi ketergantungan baca-tulis antar transaksi yang membentuk pola berbahaya (pivot), lalu membatalkan salah satu bila hasilnya tidak setara dengan eksekusi serial. Karena itu SERIALIZABLE tidak sama dengan FOR UPDATE: FOR UPDATE benar-benar memblokir, sedangkan SERIALIZABLE hanya mencatat dan mendeteksi (optimistic), sehingga konkurensi tetap tinggi tetapi ada kemungkinan gagal 40001. Bukti: query pg_locks WHERE mode='SIReadLock' menampilkan lock pada tabel dokter_jaga.

Q29 Pseudocode retry
```
MAX_RETRY = 5
BASE_DELAY_MS = 50
for attempt in 1..MAX_RETRY:
    try:
        BEGIN
        ... jalankan seluruh transaksi (SELECT + UPDATE) ...
        COMMIT
        kirim_email()        # efek eksternal hanya SETELAH commit berhasil
        return sukses
    except SQLSTATE in ('40001', '40P01'):
        ROLLBACK
        if attempt == MAX_RETRY: raise error
        delay = BASE_DELAY_MS * 2^(attempt-1)
        sleep(random(0, delay))        # exponential backoff + jitter
    except error_lain:
        ROLLBACK
        raise
```
Seluruh transaksi diulang dari BEGIN (bukan hanya pernyataan yang gagal) karena snapshot dan keputusan sebelumnya sudah tidak valid. Jitter mencegah beberapa sesi mengulang bersamaan dan bentrok lagi. Email/notifikasi dikirim setelah COMMIT karena jika dikirim di dalam transaksi lalu transaksi di-rollback atau di-retry, email sudah terkirim padahal data tidak tersimpan, atau terkirim berkali-kali. ROLLBACK database bisa dibatalkan, email tidak.

Langkah 6 (Q30 sampai Q32)

Q30 Matriks enam anomali

| Anomali | Cara reproduksi / urutan transaksi | Level dan hasil yang diamati | Mitigasi |
|---|---|---|---|
| Dirty read | A mengubah saldo tanpa COMMIT; B membaca saldo saat perubahan A belum di-COMMIT. | A mencoba `READ UNCOMMITTED`; PostgreSQL menampilkan nilai lama, bukan nilai A yang belum di-COMMIT. Tidak terjadi dirty read. | Pertahankan transaksi; PostgreSQL tidak menyediakan dirty read bahkan saat diminta `READ UNCOMMITTED`. |
| Non-repeatable read | A membaca saldo rekening 1; B mengubah saldo dan COMMIT; A membaca baris yang sama lagi. | `READ COMMITTED`: nilai berubah dari 1000000 menjadi 900000 pada Q6. `REPEATABLE READ`: Q7 tetap membaca snapshot awal 1000000. | Gunakan `REPEATABLE READ` bila pembacaan berulang harus konsisten dalam satu transaksi. |
| Phantom read | A menghitung baris yang memenuhi kondisi; B menambahkan baris yang memenuhi kondisi dan COMMIT; A menghitung lagi. | `READ COMMITTED`: jumlah meningkat dari 1 menjadi 2. `REPEATABLE READ`: jumlah tetap pada snapshot awal. | Gunakan `REPEATABLE READ` atau `SERIALIZABLE` sesuai kebutuhan; PostgreSQL menjaga snapshot tetap pada `REPEATABLE READ`. |
| Lost update | A dan B membaca saldo yang sama lalu menghitung nilai absolut masing-masing; A menulis 900000 dan B menulis 950000 setelah menunggu lock A. | Pada skenario `READ COMMITTED` Q10, nilai akhir 950000; pembaruan A tertimpa. | Gunakan pembaruan atomik berbasis kolom (`saldo = saldo - nilai`), `SELECT ... FOR UPDATE`, atau optimistic locking dengan kondisi versi/nilai lama. |
| Write skew | Dua transaksi membaca jumlah dokter aktif = 2 pada snapshot yang sama; masing-masing menonaktifkan dokter berbeda dan COMMIT. | `REPEATABLE READ` Q26: kedua COMMIT berhasil dan jumlah aktif menjadi 0. `SERIALIZABLE` Q27: salah satu transaksi gagal dengan `40001`, hanya satu dokter dinonaktifkan. | Gunakan `SERIALIZABLE` dan retry seluruh transaksi saat `40001`; alternatifnya kunci baris/representasi aturan bersama atau tegakkan invariant dengan desain constraint yang sesuai. |
| Pembacaan tidak konsisten (read skew) | Pembaca memulai transaksi `READ COMMITTED`, membaca rekening 2, lalu transaksi transfer rekening 1→2 dijalankan dan di-COMMIT sebelum pembaca membaca rekening 1. | Teramati: rekening 2 terbaca 1000000.00 sebelum transfer dan rekening 1 terbaca 900000.00 sesudah transfer. Nilai campuran berjumlah 1900000.00, sedangkan transfer mengubah saldo -100000 dan +100000 sehingga total database tetap 2000000.00. | Baca semua baris dalam satu pernyataan snapshot, atau gunakan `REPEATABLE READ`/`SERIALIZABLE` untuk transaksi laporan yang perlu snapshot konsisten. |

Q30 membedakan non-repeatable read (baris yang sama berubah saat dibaca ulang),
phantom read (baris baru memenuhi predikat), dan read skew (pembacaan beberapa
data terkait mencampur snapshot berbeda). Pada uji read skew, pastikan COMMIT
transfer terjadi di antara dua SELECT pembaca. Setelah pembacaan kedua, Sesi
pembaca di-ROLLBACK dan data dipulihkan; SELECT akhir menunjukkan saldo kedua
rekening 1000000.00 dan SUM(saldo) 2000000.00.

Q31 Rekomendasi isolation level
1. Pembacaan sederhana yang boleh melihat perubahan antarpernyataan: `READ
COMMITTED`, level default PostgreSQL. Setiap pernyataan memperoleh snapshot baru,
sehingga hasil SELECT berulang bisa berbeda seperti Q6.
2. Laporan yang membutuhkan snapshot konsisten untuk beberapa pernyataan:
`REPEATABLE READ`. Semua pembacaan transaksi menggunakan snapshot yang stabil,
seperti hasil Q7 dan Q8. Konsekuensinya, laporan tidak melihat perubahan yang
di-COMMIT setelah snapshot terbentuk.
3. Aturan bisnis lintas beberapa baris: `SERIALIZABLE` bila operasi harus
berperilaku setara dengan urutan serial. Q26 menunjukkan bahwa `REPEATABLE READ`
masih memungkinkan write skew; Q27 menunjukkan `SERIALIZABLE` mencegah hasil itu
dengan membatalkan salah satu transaksi. Aplikasi harus siap mengulang seluruh
transaksi untuk SQLSTATE `40001`. Konflik lock masih dapat menghasilkan `40P01`,
yang juga perlu ditangani dengan retry terbatas. Untuk aturan tertentu, row lock
yang dirancang konsisten atau constraint yang tepat dapat menjadi alternatif,
tetapi perlu memastikan seluruh jalur penulisan mematuhi aturan tersebut.

Q32 Tiga pelajaran utama
1. COMMIT menentukan kapan perubahan menjadi terlihat oleh transaksi lain.
Pada Q2, Sesi A melihat 900000 sebelum COMMIT, sedangkan Sesi B tetap membaca
1000000; setelah COMMIT, pembacaan B menjadi 900000.
2. Snapshot konsisten tidak sama dengan perlindungan penuh terhadap aturan
lintas baris. Pada Q26 kedua transaksi REPEATABLE READ membaca dua dokter aktif
dan berhasil menonaktifkan baris berbeda, sehingga hasil akhirnya nol dokter
aktif. Pada Q27 SERIALIZABLE membatalkan Sesi B dengan SQLSTATE 40001 dan hanya
satu dokter menjadi nonaktif.
3. Locking memengaruhi progres transaksi dan urutan lock penting. Q19
memperlihatkan sesi kedua menunggu sampai pemegang lock selesai; Q20 menghasilkan
deadlock SQLSTATE 40P01 karena sesi saling menunggu; Q21 tidak deadlock ketika
keduanya mengambil lock dengan urutan rekening yang sama.
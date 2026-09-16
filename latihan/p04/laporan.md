# Laporan Latihan Kelompok Pertemuan 4
## Identitas Kelompok

| Nama | NIM | Kontribusi | Commit |
|---|---|---|---|
| Muhammad Lukman Toro | `251402105` | Project Manager; langkah 6 dan 7 |  langkah 6 dan 7 |
| Khairunnisa | `251402017` | Langkah 3 |langkah 3: |
| Rumaisha Raghib Syahidah Siregar | `251402034` | Langkah 4 | langkah 4 |
| Muhammad Ihsan Anwar | `251402044` | Langkah 1 dan 2 | Langkah 1 dan 2 |
| Randi Abdiansyah | `251402138` | Langkah 5 | Langkah 5 |


## Q1–Q21

### Q1

**Perintah:** [q01_view_film_murah.sql](q01_view_film_murah.sql).

**Keluaran:** View `lab4.film_murah` berhasil dibuat dan menampilkan film dengan `rental_rate <= 0.99`.

**Alasan:** View membatasi baris yang terlihat tanpa mengubah tabel dasar.

### Q2

**Perintah:** [q02_baris_menghilang.sql](q02_baris_menghilang.sql).

**Keluaran:** Baris dengan harga `4.99` masuk ke tabel dasar, tetapi tidak muncul di view karena tidak memenuhi filter.

**Alasan:** View hanya menampilkan baris yang memenuhi predikatnya.

### Q3

**Perintah:** [q03_check_option.sql](q03_check_option.sql) dengan `WITH CASCADED CHECK OPTION`.

**Keluaran galat utuh:**

```text
ERROR:  new row violates check option for view "film_murah"
DETAIL:  Failing row contains (1002, Film Uji Q3, 4.99, PG).
```

**Alasan:** `CHECK OPTION` menolak insert yang tidak akan terlihat melalui view.

### Q4

**Perintah:** [q04_view_pendapatan_kategori.sql](q04_view_pendapatan_kategori.sql), lalu mencoba `INSERT` ke view agregat.

**Keluaran:**

```text
ERROR:  cannot insert into view "pendapatan_kategori"
DETAIL:  Views containing GROUP BY are not automatically updatable.
HINT:  To enable inserting into the view, provide an INSTEAD OF INSERT trigger or an unconditional ON INSERT DO INSTEAD rule.
```

**Alasan:** Hasil `GROUP BY` tidak memiliki pemetaan satu-ke-satu ke tabel dasar.

### Q5

**Perintah:** [q05_query_dasar_akses.sql](q05_query_dasar_akses.sql) dengan `\timing on`.

**Keluaran:** Agregasi akses per bulan dan kanal selesai dalam `16633.242 ms`.

**Alasan:** Query ini menjadi baseline untuk membandingkan materialized view Q6–Q8.

### Q6

**Perintah:** [q06_buat_matview.sql](q06_buat_matview.sql), membaca materialized view sebelum refresh, lalu refresh biasa.

**Keluaran galat utuh sebelum refresh:**

```text
ERROR:  materialized view "ringkasan_akses" has not been populated
HINT:  Use the REFRESH MATERIALIZED VIEW command.
```

Setelah refresh biasa, view terisi. Waktu: `847.482 ms`.

**Alasan:** `WITH NO DATA` membuat struktur terlebih dahulu tanpa pengisian awal.

### Q7

**Perintah:** [q07_refresh_konkuren.sql](q07_refresh_konkuren.sql) dengan `REFRESH MATERIALIZED VIEW CONCURRENTLY`.

**Keluaran galat utuh sebelum unique index dibuat:**

```text
ERROR:  cannot refresh materialized view "lab4.ringkasan_akses" concurrently
HINT:  Create unique index with no WHERE clause on one or more columns of the materialized view
```

Setelah unique index tanpa `WHERE` dibuat, refresh concurrent berhasil. Waktu: `1272.882 ms`.

**Alasan:** PostgreSQL memerlukan unique index untuk mencocokkan baris lama dan baru saat pembaca tetap dilayani.

### Q8

**Perintah:** [q08_analisis_kinerja.sql](q08_analisis_kinerja.sql) dengan dua sesi psql: sesi pertama menjalankan insert/refresh dan sesi kedua menjalankan `SELECT count(*) FROM lab4.ringkasan_akses;`.

**Keluaran:** Pembaca tetap dapat berjalan selama refresh concurrent; refresh biasa menggunakan lock yang lebih kuat dan dapat membuat pembaca menunggu.

**Alasan:** Dua sesi membuktikan perbedaan blocking secara langsung.

### Q9

**Perintah:** [q09_trigger_audit_baris.sql](q09_trigger_audit_baris.sql).

**Keluaran:** Tabel `audit_harga`, fungsi, dan trigger row-level berhasil dibuat.

**Alasan:** `AFTER UPDATE OF rental_rate` dan `IS DISTINCT FROM` hanya mencatat perubahan harga yang nyata, termasuk perubahan dari/ke `NULL`.

### Q10

**Perintah:** [q10_uji_audit_baris.sql](q10_uji_audit_baris.sql) untuk perubahan harga, penulisan nilai sama, dan perubahan `title`.

**Keluaran:** Hanya perubahan harga ke nilai berbeda yang masuk audit.

**Alasan:** Klausa kolom dan `WHEN` mencegah audit palsu.

### Q11

**Perintah:** [q11_null_pada_trigger.sql](q11_null_pada_trigger.sql) setelah kondisi diganti menjadi `OLD.rental_rate <> NEW.rental_rate`.

**Keluaran:** Perubahan dari/ke `NULL` tidak tercatat.

**Alasan:** Perbandingan dengan `NULL` menghasilkan `UNKNOWN`; `IS DISTINCT FROM` lebih tepat untuk audit.

### Q12

**Perintah:** [q12_biaya_trigger_baris.sql](q12_biaya_trigger_baris.sql) dengan trigger aktif lalu nonaktif.

**Keluaran:**

```text
Dengan trigger aktif: [tempel output \timing]
Dengan trigger nonaktif: [tempel output \timing]
```

**Alasan:** Selisih waktu mengukur overhead row-level trigger pada update massal.

### Q13

**Perintah:** [q13_trigger_pernyataan.sql](q13_trigger_pernyataan.sql) menggunakan transition tables.

**Keluaran:**

```text
Trigger statement-level: [tempel output \timing]
```

**Alasan:** Transition table memungkinkan perubahan massal diproses dalam satu statement.

### Q14

**Perintah:** [q14_check_not_valid.sql](q14_check_not_valid.sql).

**Keluaran:** Constraint `NOT VALID` dapat dipasang saat data lama masih melanggar. Validasi pertama gagal, data diperbaiki, lalu validasi berikutnya berhasil.

**Alasan:** Pemasangan constraint dan validasi dipisahkan untuk mengurangi gangguan pada tabel besar.

### Q15

**Perintah:** [q15_unique_soft_delete.sql](q15_unique_soft_delete.sql).

**Keluaran:** `UNIQUE` biasa tetap menghalangi judul yang sama setelah soft delete; partial unique index dengan `WHERE deleted_at IS NULL` mengizinkan judul aktif baru.

**Alasan:** Keunikan hanya diperlukan di antara data yang belum dihapus secara logis.

### Q16

**Perintah:** [q16_fk_aksi_referensial.sql](q16_fk_aksi_referensial.sql).

**Keluaran:** `NO ACTION` menolak delete parent, `CASCADE` menghapus child, dan `SET NULL` mempertahankan child dengan foreign key `NULL`.

**Alasan:** Aksi referensial dipilih berdasarkan siklus hidup data child.

### Q17

**Perintah:** [q17_exclude_harga.sql](q17_exclude_harga.sql).

**Keluaran:** Insert rentang pertama berhasil, insert yang overlap ditolak, dan rentang berdampingan berhasil.

**Alasan:** `EXCLUDE USING gist` mencegah overlap untuk film dan wilayah yang sama.

### Q18

**Perintah:** [q18_expand_tulis_ganda.sql](q18_expand_tulis_ganda.sql). Sesi pembaca kedua menjalankan:

```sql
SELECT title, rental_rate FROM lab4.film LIMIT 5;
```

**Keluaran:** `harga_film` dan trigger `film_tulis_ganda_harga` dibuat. Update `rental_rate` pada bentuk lama mencerminkan harga wilayah `ID`.

**Alasan:** Struktur baru dan dual-write dipasang sebelum backfill agar perubahan selama migrasi tidak hilang.

### Q19

**Perintah:** [q19_backfill_bertahap.sql](q19_backfill_bertahap.sql).

**Keluaran:** Backfill dilakukan per rentang 1000 film. Verifikasi harus menghasilkan:

```text
film_belum_backfill
-------------------
0
```

**Alasan:** `NOT EXISTS` membuat proses idempoten dan batch 1000 membatasi ukuran pekerjaan.

### Q20

**Perintah:** [q20_contract_view_fasad.sql](q20_contract_view_fasad.sql) setelah Q19 menghasilkan nol, sementara sesi pembaca tetap aktif.

**Keluaran:** Dual-write dihentikan, tabel fisik diubah menjadi `film_data`, lalu `lab4.film` dibuat sebagai view fasad yang menyediakan `rental_rate` dari `harga_film` wilayah `ID`. Query pembaca lama tetap menggunakan nama `lab4.film`.

**Catatan:** Jika pembaca dijalankan setelah kolom fisik dihapus tetapi sebelum view fasad dibuat, pembaca gagal. Urutan yang benar adalah membuat dan membuktikan view fasad terlebih dahulu, baru menjalankan Q21/0046.

### Q21

**Perintah:** Jalankan migration secara berurutan dari `migrations/`: 0041 struktur baru, 0042 dual-write, 0043 backfill, 0044 verifikasi, 0045 view fasad, dan 0046 drop kolom lama.

**Keluaran:** Keenam migration memiliki pasangan `.up.sql` dan `.down.sql`.

**Alasan:** Versi terpisah membuat tahapan dapat diaudit. `0046.down.sql` hanya menambahkan kembali kolom kosong; isi `rental_rate` lama tidak dapat dipulihkan.

## Refleksi A–E

### Refleksi A
Sebuah tim menempatkan seluruh akses aplikasi melalui view dengan alasan lebih aman dan lebih rapi. Sebutkan dua keuntungan, dua kerugian, dan satu keadaan konkret ketika pendekatan ini justru mempersulit tim berdasarkan pengamatan Q1–Q4.

Dua keuntungan:
1.⁠ ⁠Meningkatkan keamanan, karena view dapat membatasi data yang dapat diakses aplikasi, seperti Q1 yang hanya menampilkan film dengan rental_rate <= 0.99.
2.⁠ ⁠Menyederhanakan akses data, karena aplikasi tidak perlu berinteraksi langsung dengan tabel-tabel dasar yang kompleks.

Dua kerugian:
1.⁠ ⁠Data dapat tidak terlihat melalui view, seperti pada Q2, ketika film dengan rental_rate = 4.99 berhasil masuk ke tabel dasar tetapi tidak muncul pada view.
2.⁠ ⁠Tidak semua view dapat dimodifikasi, seperti Q4 yang menggunakan GROUP BY dan SUM(), sehingga tidak dapat digunakan untuk INSERT secara langsung.

Keadaan konkret:
Pendekatan ini mempersulit tim ketika aplikasi perlu memasukkan data yang tidak memenuhi kondisi view. Pada Q3, misalnya, film dengan rental_rate = 4.99 ditolak karena view menggunakan WITH CASCADED CHECK OPTION, sehingga aplikasi tidak dapat memasukkan data tersebut melalui view.

### Refleksi B
Tim keuangan menginginkan laporan yang selalu mutakhir sekaligus selalu cepat. Jelaskan trade-off materialized view dan usulkan kompromi konkret: batas kebasian, jadwal refresh, dan tindakan saat refresh gagal di tengah jalan.
Jawab:
•⁠  ⁠Trade-off: Kinerja baca sangat cepat, namun data tidak bersifat real-time (terdapat jeda kebasian) dan memerlukan alokasi sumber daya komputasi saat pembaruan.
•⁠  ⁠Batas Kebasian: Tetapkan toleransi keterlambatan data maksimal 1 jam untuk kebutuhan operasional atau 24 jam untuk laporan rekapitulasi harian.
•⁠  ⁠Jadwal Refresh: Lakukan pembaruan otomatis setiap jam di luar jam sibuk menggunakan opsi ⁠ CONCURRENTLY ⁠ agar sistem tidak mengalami hambatan akses (blocking).
•⁠  ⁠Penanganan Kegagalan: Sistem wajib mempertahankan snapshot data lama yang masih valid, menjalankan mekanisme percobaan ulang (retry) secara otomatis, serta mengirimkan pemberitahuan kepada tim teknis.

### Refleksi C

1.⁠ ⁠Kapan trigger per baris (FOR EACH ROW) tetap lebih tepat dipakai walaupun lebih lambat?
Trigger level baris tetap lebih tepat digunakan ketika logika yang dijalankan memerlukan validasi individual yang sangat spesifik per baris, atau saat aplikasi umumnya melakukan modifikasi data secara granular (1–5 baris per transaksi). Selain itu, trigger per baris dibutuhkan saat keputusan pembatalan (RAISE EXCEPTION) harus dievaluasi satu per satu berdasarkan kalkulasi kondisi internal tiap baris data sebelum transaksi dilanjutkan.

2.⁠ ⁠Kemampuan yang tidak dimiliki oleh trigger level pernyataan (FOR EACH STATEMENT):
Trigger level pernyataan tidak memiliki kemampuan BEFORE untuk memodifikasi nilai NEW secara individual per baris sebelum ditulis ke disk (misalnya mengubah format teks atau mengompensasi nilai kolom per baris data secara langsung sebelum INSERT/UPDATE rampung).

3.⁠ ⁠Mengapa mengirim surel secara langsung dari dalam trigger adalah praktik yang buruk saat transaksi di-rollback?
Trigger PostgreSQL berjalan di dalam siklus ACID Transaction. Pengiriman surel (email notification) adalah operasi eksternal (side-effect) yang berada di luar ruang kendali transaksi basis data. Jika trigger memicu pengiriman surel secara langsung di tengah transaksi, lalu transaksi tersebut dibatalkan (ROLLBACK):
•⁠  ⁠Data di tabel basis data akan batal disimpan.
•⁠  ⁠Namun surel sudah terlanjur terkirim ke penerima (phantom notification).

Pendekatan yang tepat: Trigger sebaiknya hanya memasukkan pesan ke tabel antrean (outbox table). Layanan latar belakang (worker) yang akan membaca antrean dan mengirimkan surel hanya setelah transaksi dipastikan sudah di-commit secara permanen.

### Refleksi D

aturan periode harga tidak tumpang tindih dapat ditulis sebagai trigger yang membaca tabel sebelum INSERT. Jelaskan mengapa trigger itu bisa gagal ketika dua transaksi berjalan bersamaan, sedangkan EXCLUDE tidak, dengan bahasa Anda sendiri.

Kalau aturan "periode tidak boleh overlap" ditulis sebagai trigger BEFORE INSERT yang mengecek lewat SELECT dulu, ada jeda waktu antara langkah baca (cek overlap) dan langkah tulis (INSERT). Di level isolasi default PostgreSQL (READ COMMITTED), kalau dua transaksi jalan bersamaan dan sama-sama cek overlap sebelum satu pun dari mereka commit, keduanya bakal sama-sama melihat "belum ada overlap" (karena masing-masing belum lihat baris punya transaksi lain yang belum di-commit), lalu keduanya sama-sama insert dan commit — hasil akhirnya dua baris yang overlap tetap lolos masuk tabel. Ini disebut race condition.

EXCLUDE constraint tidak kena masalah ini karena pengecekannya bukan query terpisah, melainkan langsung ditegakkan oleh index GiST pada saat operasi INSERT itu sendiri — mirip PRIMARY KEY/UNIQUE. Begitu satu transaksi mulai insert, entry index yang relevan "dikawal", jadi transaksi kedua yang overlap akan tertahan menunggu transaksi pertama commit, lalu dicek ulang terhadap data terbaru dan ditolak kalau memang overlap. Cek dan tulisnya jadi satu operasi atomik, bukan dua langkah yang bisa diselingi transaksi lain.

### Refleksi E

Expand–contract menjaga pembaca lama melalui urutan struktur baru, dual-write, backfill, verifikasi, view fasad, lalu drop bentuk lama. Sesi pembaca harus terus menjalankan query lama selama Q18–Q20. Bila pembaca gagal sebelum view fasad terbukti, urutan salah. 0046 hanya boleh dijalankan setelah bukti Q20 terkumpul.

## Ringkasan Waktu

| Tugas | Waktu | Penafsiran |
|---|---:|---|
| Q5 | 16633.242 ms | Agregasi langsung memindai dan mengelompokkan data besar. |
| Q6 | 847.482 ms | Refresh biasa lebih cepat, tetapi lock lebih kuat. |
| Q7 | 1272.882 ms | Refresh concurrent lebih lambat karena pencocokan data dan unique index, tetapi pembaca lebih tersedia. |
| Q12 |  | Bandingkan trigger aktif dan nonaktif untuk mengukur overhead row-level. |
| Q13 |  | Transition table memproses perubahan massal pada level statement. |

Q7 dapat lebih lambat dari Q6 karena PostgreSQL harus mencocokkan hasil lama dan baru menggunakan unique index sambil menjaga konsistensi pembaca.

## Migrasi dan Commit

```text
migrations/
├── 0041_expand_buat_harga_film.up.sql
├── 0041_expand_buat_harga_film.down.sql
├── 0042_expand_trigger_tulis_ganda.up.sql
├── 0042_expand_trigger_tulis_ganda.down.sql
├── 0043_migrate_backfill.up.sql
├── 0043_migrate_backfill.down.sql
├── 0044_migrate_verifikasi.up.sql
├── 0044_migrate_verifikasi.down.sql
├── 0045_contract_view_fasad.up.sql
├── 0045_contract_view_fasad.down.sql
├── 0046_contract_drop_kolom_lama.up.sql
└── 0046_contract_drop_kolom_lama.down.sql
```

**Tangkapan layar struktur:** `[latihan/p04/struktur_migrations.png]`


Commit yang sudah terlihat pada branch ini: `fe292cf` (langkah 1–2), `a829639` (Q5–Q8), `8703612` (langkah 4), dan `017fc5b` (langkah 5/6–7). Hash tersebut bukan commit Q18–Q21 sampai perubahan ini benar-benar di-commit.

### Catatan Sesi Pembaca Tugas E

| Tahap | Catatan |
|---|---|
| Q18 expand | Jalankan `SELECT title, rental_rate FROM lab4.film LIMIT 5;` terus pada sesi kedua saat tabel dan trigger dibuat. |
| Q19 migrate | Query lama tetap dijalankan selama backfill batch; verifikasi harus menghasilkan `0`. |
| Q20 contract | View fasad dibuat sebelum kolom fisik dihapus sehingga nama `rental_rate` tetap tersedia. |
| Q21/0046 | Jangan jalankan sebelum bukti Q20 stabil; rollback hanya membuat kolom kosong. |
| Bukti | Tempel screenshot, output psql, dan URL commit aktual di bagian ini. |

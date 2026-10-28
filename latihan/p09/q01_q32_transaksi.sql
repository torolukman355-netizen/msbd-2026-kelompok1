/*
 * P09 — Q1 sampai Q32: panduan eksekusi transaksi PostgreSQL.
 *
 * JANGAN jalankan seluruh file sekaligus. Salin blok sesuai label [A] dan [B]
 * ke dua koneksi psql yang berbeda, dalam urutan yang ditulis. Jalankan
 * q00_setup.sql sebelum sebuah skenario atau saat ingin mengembalikan data.
 *
 * Untuk menampilkan SQLSTATE di psql:
 *   \set VERBOSITY verbose
 */

-- ===========================================================================
-- Q1 — KONDISI AWAL [A]
-- ===========================================================================
SELECT rekening_id, pemilik, saldo, version_no
FROM lab9.rekening
ORDER BY rekening_id;

SELECT COUNT(*) AS jumlah_rekening, SUM(saldo) AS total_saldo
FROM lab9.rekening;
-- Bukti awal yang diharapkan setelah setup: 2 rekening, total 2000000.00.

-- ===========================================================================
-- Q2 — PERUBAHAN BELUM COMMIT
-- ===========================================================================
-- [A]
BEGIN;
UPDATE lab9.rekening
SET saldo = saldo - 100000.00
WHERE rekening_id = 1;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- A melihat 900000.00, tetapi jangan COMMIT dahulu.

-- [B] jalankan saat A masih terbuka
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- B masih melihat 1000000.00.

-- [A]
COMMIT;

-- [B]
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- B kini melihat 900000.00.

-- ===========================================================================
-- Q3 — COMMIT DAN ROLLBACK
-- ===========================================================================
-- [A] reset agar hasil mudah dibaca.
UPDATE lab9.rekening SET saldo = 1000000.00 WHERE rekening_id = 1;

BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 50000.00 WHERE rekening_id = 1;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
ROLLBACK;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Nilai kembali 1000000.00 karena ROLLBACK.

BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 50000.00 WHERE rekening_id = 1;
COMMIT;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Nilai 950000.00 bertahan karena COMMIT.

-- ===========================================================================
-- Q4 — SAVEPOINT [A]
-- ===========================================================================
UPDATE lab9.rekening
SET saldo = 1000000.00
WHERE rekening_id IN (1, 2);

BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 10000.00 WHERE rekening_id = 1;
SAVEPOINT setelah_rekening_1;
UPDATE lab9.rekening SET saldo = saldo - 20000.00 WHERE rekening_id = 2;
SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;
ROLLBACK TO SAVEPOINT setelah_rekening_1;
SELECT rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;
COMMIT;
-- Rekening 1 = 990000.00, rekening 2 kembali 1000000.00.

-- ===========================================================================
-- Q5 — ATOMICITY DAN CONSISTENCY (CHECK constraint) [A]
-- ===========================================================================
BEGIN;
SAVEPOINT sebelum_pelanggaran;
UPDATE lab9.rekening SET saldo = -1.00 WHERE rekening_id = 2;
-- Diharapkan ERROR SQLSTATE 23514 (check_violation).
ROLLBACK TO SAVEPOINT sebelum_pelanggaran;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 2;
COMMIT;
-- ROLLBACK TO SAVEPOINT membuat transaksi dapat dilanjutkan setelah error.

-- ===========================================================================
-- Q6 — NON-REPEATABLE READ PADA READ COMMITTED
-- ===========================================================================
-- Persiapan [A atau sesi terpisah]
UPDATE lab9.rekening SET saldo = 1000000.00 WHERE rekening_id = 1;

-- [A]
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Hasil pertama: 1000000.00.

-- [B]
BEGIN;
UPDATE lab9.rekening SET saldo = 900000.00 WHERE rekening_id = 1;
COMMIT;

-- [A]
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
COMMIT;
-- Hasil kedua: 900000.00; setiap statement memiliki snapshot baru.

-- ===========================================================================
-- Q7 — SNAPSHOT REPEATABLE READ
-- ===========================================================================
UPDATE lab9.rekening SET saldo = 1000000.00 WHERE rekening_id = 1;

-- [A]
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Hasil pertama: 1000000.00.

-- [B]
BEGIN;
UPDATE lab9.rekening SET saldo = 900000.00 WHERE rekening_id = 1;
COMMIT;

-- [A]
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
COMMIT;
-- Hasil kedua tetap 1000000.00 pada snapshot A.

-- ===========================================================================
-- Q8 — PHANTOM READ
-- ===========================================================================
DELETE FROM lab9.rekening_eksperimen WHERE rekening_id = 104;

-- [A]
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT COUNT(*) AS jumlah_di_atas_500k
FROM lab9.rekening_eksperimen WHERE saldo > 500000.00;
-- Hasil pertama: 2.

-- [B]
INSERT INTO lab9.rekening_eksperimen (rekening_id, pemilik, saldo)
VALUES (104, 'Deni', 700000.00);

-- [A]
SELECT COUNT(*) AS jumlah_di_atas_500k
FROM lab9.rekening_eksperimen WHERE saldo > 500000.00;
COMMIT;
-- Hasil kedua: 3; Deni adalah phantom pada READ COMMITTED.

-- Ulangi urutan yang sama dengan [A] BEGIN ISOLATION LEVEL REPEATABLE READ;
-- (hapus dahulu id 104, lalu B melakukan INSERT setelah SELECT pertama).
-- Kedua COUNT di A akan tetap 2.

-- ===========================================================================
-- Q9 — DIRTY READ TIDAK TERJADI DI POSTGRESQL
-- ===========================================================================
UPDATE lab9.rekening SET saldo = 1000000.00 WHERE rekening_id = 1;

-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = 777000.00 WHERE rekening_id = 1;
-- Jangan COMMIT.

-- [B]
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
COMMIT;
-- B tetap melihat 1000000.00: PostgreSQL memperlakukan READ UNCOMMITTED
-- sebagai READ COMMITTED.

-- [A]
ROLLBACK;

-- ===========================================================================
-- Q10 — LOST UPDATE KARENA NILAI ABSOLUT YANG SUDAH BASI
-- ===========================================================================
UPDATE lab9.rekening SET saldo = 1000000.00 WHERE rekening_id = 1;

-- [A]
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- A menyimpan hasil hitung aplikasi: 900000.00.

-- [B] jalankan sebelum A menulis.
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- B juga menghitung dari nilai lama: 950000.00.

-- [A]
UPDATE lab9.rekening SET saldo = 900000.00 WHERE rekening_id = 1;
COMMIT;

-- [B]
UPDATE lab9.rekening SET saldo = 950000.00 WHERE rekening_id = 1;
COMMIT;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Hasil akhir 950000.00; pengurangan A hilang.

-- ===========================================================================
-- Q11 — RINGKASAN ANOMALI
-- ===========================================================================
-- Q6: non-repeatable read (1000000.00 -> 900000.00).
-- Q8: phantom read (COUNT 2 -> 3).
-- Q9: dirty read dicegah oleh PostgreSQL.
-- Q10: lost update (nilai absolut A tertimpa nilai absolut B).
-- Lihat matriks lengkap Q30 dan laporan.md untuk penyebab, dampak, mitigasi.

-- ===========================================================================
-- Q12 — PEMBARUAN ATOMIK MENGHINDARI LOST UPDATE
-- ===========================================================================
UPDATE lab9.rekening SET saldo = 1000000.00 WHERE rekening_id = 1;

-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000.00 WHERE rekening_id = 1;
-- Tahan sebelum COMMIT bila ingin melihat B menunggu.

-- [B]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 50000.00 WHERE rekening_id = 1;
-- B menunggu lock A, lalu memakai nilai terbaru setelah A COMMIT.

-- [A], lalu [B]
COMMIT;
-- Jalankan COMMIT ini di B setelah UPDATE B selesai.
-- Hasil akhir setelah kedua COMMIT: 850000.00, bukan nilai yang tertimpa.

-- ===========================================================================
-- Q13 — SELECT ... FOR UPDATE
-- ===========================================================================
-- [A]
BEGIN;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- [B]
BEGIN;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- B menunggu sampai A selesai.

-- [A]
COMMIT;
-- [B] SELECT selesai, kemudian jalankan COMMIT di B.

-- ===========================================================================
-- Q14 — OPTIMISTIC LOCKING DENGAN version_no
-- ===========================================================================
UPDATE lab9.rekening
SET saldo = 1000000.00, version_no = 0
WHERE rekening_id = 1;

-- Aplikasi A membaca saldo=1000000.00, version_no=0.
-- Transaksi lain lebih dahulu mengubah versi.
UPDATE lab9.rekening
SET saldo = saldo - 10000.00, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 0;

-- Percobaan A dengan versi lama tidak mengubah baris.
UPDATE lab9.rekening
SET saldo = 900000.00, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 0;
-- Command tag: UPDATE 0. Aplikasi harus membaca ulang dan memutuskan retry.

-- ===========================================================================
-- Q15 — MVCC: PEMBACA BIASA TIDAK MENUNGGU PENULIS
-- ===========================================================================
UPDATE lab9.rekening SET saldo = 1000000.00 WHERE rekening_id = 1;

-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = 990000.00 WHERE rekening_id = 1;

-- [B] saat A belum COMMIT
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- B umumnya langsung mendapat nilai ter-commit lama: 1000000.00.

-- [A] COMMIT; [B] ulangi SELECT dan mendapat 990000.00 pada READ COMMITTED.

-- ===========================================================================
-- Q16 — METADATA xmin DAN xmax
-- ===========================================================================
SELECT rekening_id, saldo, xmin, xmax
FROM lab9.rekening
WHERE rekening_id = 1;
-- xmin adalah XID pembuat versi tuple; xmax berkaitan dengan penghapusan/
-- penggantian versi. Keduanya harus dibaca bersama snapshot, bukan data bisnis.

-- ===========================================================================
-- Q17 — MVCC DAN VACUUM (JALANKAN DI LUAR BEGIN/COMMIT)
-- ===========================================================================
SELECT schemaname, relname, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum
FROM pg_stat_user_tables
WHERE schemaname = 'lab9' AND relname = 'rekening';

VACUUM (VERBOSE, ANALYZE) lab9.rekening;
-- UPDATE/DELETE meninggalkan versi lama yang kelak dibersihkan VACUUM; pembaca
-- masih boleh memakai versi itu selama snapshot mereka membutuhkannya.

-- ===========================================================================
-- Q18 — PERBANDINGAN ROW LOCK
-- ===========================================================================
-- FOR UPDATE: terkuat; memblokir UPDATE/DELETE dan semua row lock konflik.
-- FOR NO KEY UPDATE: UPDATE biasa; masih kompatibel dengan FOR KEY SHARE.
-- FOR SHARE: pembacaan yang mencegah perubahan/penghapusan konflik.
-- FOR KEY SHARE: melindungi kunci referensial dari DELETE/perubahan key.

-- ===========================================================================
-- Q19 — ROW LOCK BLOCKING
-- ===========================================================================
-- [A] BEGIN; SELECT * FROM lab9.rekening WHERE rekening_id=1 FOR UPDATE;
-- [B] BEGIN; SELECT * FROM lab9.rekening WHERE rekening_id=1 FOR UPDATE;
-- B berstatus menunggu. [A] COMMIT membuat SELECT B selesai; lalu B COMMIT.

-- ===========================================================================
-- Q20 — DEADLOCK
-- ===========================================================================
-- [A] BEGIN; SELECT * FROM lab9.rekening WHERE rekening_id=1 FOR UPDATE;
-- [B] BEGIN; SELECT * FROM lab9.rekening WHERE rekening_id=2 FOR UPDATE;
-- [A] SELECT * FROM lab9.rekening WHERE rekening_id=2 FOR UPDATE; -- menunggu
-- [B] SELECT * FROM lab9.rekening WHERE rekening_id=1 FOR UPDATE; -- 40P01
-- PostgreSQL membatalkan satu sesi. ROLLBACK sesi yang gagal; bersihkan sesi lain.

-- ===========================================================================
-- Q21 — MENCEGAH DEADLOCK DENGAN URUTAN LOCK KONSISTEN
-- ===========================================================================
-- Kedua sesi selalu meminta rekening_id=1 lalu rekening_id=2.
-- B menunggu lock pertama A dan belum memegang lock kedua, sehingga tidak ada
-- circular wait. Setelah A COMMIT, B memperoleh 1 lalu 2 dan dapat COMMIT.

-- ===========================================================================
-- Q22 — DEADLOCK VS ANTREAN LOCK PANJANG [O = PENGAMAT]
-- ===========================================================================
SELECT pid, state, wait_event_type, wait_event, pg_blocking_pids(pid) AS diblokir_oleh,
       query
FROM pg_stat_activity
WHERE datname = current_database() AND pid <> pg_backend_pid()
ORDER BY pid;
-- Antrean panjang: B hanya menunggu A tanpa siklus. Deadlock: graf tunggu
-- berbentuk siklus dan server memilih korban dengan SQLSTATE 40P01.

-- ===========================================================================
-- Q23 — TIMEOUT
-- ===========================================================================
-- [A] BEGIN; SELECT * FROM lab9.rekening WHERE rekening_id=1 FOR UPDATE;
-- [B]
BEGIN;
SET LOCAL lock_timeout = '2s';
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- Setelah kira-kira 2 detik: SQLSTATE 55P03. Lalu ROLLBACK di B; COMMIT di A.
ROLLBACK;

BEGIN;
SET LOCAL statement_timeout = '500ms';
SELECT pg_sleep(2);
-- Diharapkan SQLSTATE 57014 (query_canceled), lalu ROLLBACK.
ROLLBACK;
-- idle_in_transaction_session_timeout memutus sesi yang idle dalam transaksi.
-- deadlock_timeout hanya memicu pemeriksaan deadlock, bukan timeout lock biasa.

-- ===========================================================================
-- Q24 — SKIP LOCKED UNTUK WORKER ANTREAN
-- ===========================================================================
TRUNCATE lab9.antrean_pekerjaan;
INSERT INTO lab9.antrean_pekerjaan VALUES (1, 'siap'), (2, 'siap'), (3, 'selesai');

-- [A]
BEGIN;
SELECT id, status FROM lab9.antrean_pekerjaan WHERE id = 1 FOR UPDATE;

-- [B]
BEGIN;
SELECT id, status FROM lab9.antrean_pekerjaan
WHERE status = 'siap' ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED;
-- B menerima id=2, karena id=1 dilewati tanpa menunggu.
UPDATE lab9.antrean_pekerjaan SET status = 'diproses' WHERE id = 2;
COMMIT;
-- [A] COMMIT;

-- ===========================================================================
-- Q25 — NOWAIT
-- ===========================================================================
-- [A] BEGIN; SELECT * FROM lab9.antrean_pekerjaan WHERE id=1 FOR UPDATE;
-- [B] BEGIN; SELECT * FROM lab9.antrean_pekerjaan WHERE id=1 FOR UPDATE NOWAIT;
-- B segera mendapat SQLSTATE 55P03, bukan menunggu. ROLLBACK B; COMMIT A.

-- ===========================================================================
-- Q26 — WRITE SKEW PADA REPEATABLE READ
-- ===========================================================================
TRUNCATE lab9.dokter_jaga;
INSERT INTO lab9.dokter_jaga VALUES (1, 'dr. Andi', TRUE), (2, 'dr. Bunga', TRUE);

-- [A] BEGIN ISOLATION LEVEL REPEATABLE READ;
-- [A] SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif; -- 2
-- [B] BEGIN ISOLATION LEVEL REPEATABLE READ;
-- [B] SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif; -- 2
-- [A] UPDATE lab9.dokter_jaga SET aktif=FALSE WHERE dokter_id=1; COMMIT;
-- [B] UPDATE lab9.dokter_jaga SET aktif=FALSE WHERE dokter_id=2; COMMIT;
SELECT COUNT(*) AS dokter_aktif FROM lab9.dokter_jaga WHERE aktif;
-- Hasil 0: kedua transaksi mengubah baris berbeda dan aturan dilanggar.

-- ===========================================================================
-- Q27 — SERIALIZABLE MENCEGAH WRITE SKEW
-- ===========================================================================
TRUNCATE lab9.dokter_jaga;
INSERT INTO lab9.dokter_jaga VALUES (1, 'dr. Andi', TRUE), (2, 'dr. Bunga', TRUE);

-- Jalankan kedua COUNT sebelum UPDATE mana pun:
-- [A] BEGIN ISOLATION LEVEL SERIALIZABLE;
-- [A] SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif; -- 2
-- [B] BEGIN ISOLATION LEVEL SERIALIZABLE;
-- [B] SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif; -- 2
-- [A] UPDATE lab9.dokter_jaga SET aktif=FALSE WHERE dokter_id=1; COMMIT;
-- [B] UPDATE lab9.dokter_jaga SET aktif=FALSE WHERE dokter_id=2; COMMIT;
-- Satu transaksi gagal dengan SQLSTATE 40001 pada UPDATE atau COMMIT.

-- ===========================================================================
-- Q28 — SIREADLOCK [O]
-- ===========================================================================
-- Saat satu transaksi SERIALIZABLE masih terbuka setelah SELECT dokter_jaga:
SELECT locktype, mode, relation::regclass AS relasi, page, tuple, pid
FROM pg_locks
WHERE mode = 'SIReadLock'
ORDER BY pid, locktype;
-- SIReadLock mencatat pembacaan predicate untuk SSI; ia tidak memblokir penulis
-- seperti FOR UPDATE, tetapi membantu server mendeteksi konflik serialisasi.

-- ===========================================================================
-- Q29 — PSEUDOCODE RETRY
-- ===========================================================================
-- for attempt = 1..5:
--   BEGIN (SERIALIZABLE); jalankan SELURUH read/validasi/write; COMMIT
--   jika sukses: return
--   jika SQLSTATE = 40001 atau 40P01: ROLLBACK; sleep(backoff eksponensial+jitter)
--   selain itu: ROLLBACK; lempar error
-- Ulangi seluruh transaksi, bukan hanya statement gagal, karena snapshot lama
-- dan keputusan bisnisnya sudah tidak valid.

-- ===========================================================================
-- Q30 — MATRIKS ENAM ANOMALI
-- ===========================================================================
SELECT *
FROM (VALUES
    ('dirty read', 'A menulis tanpa COMMIT; B membaca',
     'PostgreSQL menampilkan nilai lama walau READ UNCOMMITTED',
     'MVCC PostgreSQL mencegahnya'),
    ('non-repeatable read', 'A baca; B UPDATE+COMMIT; A baca ulang',
     'Nilai baris sama berubah pada READ COMMITTED', 'REPEATABLE READ'),
    ('phantom read', 'A COUNT predicate; B INSERT+COMMIT; A COUNT ulang',
     'Jumlah berubah pada READ COMMITTED', 'REPEATABLE READ atau SERIALIZABLE'),
    ('lost update', 'A dan B tulis nilai absolut dari bacaan lama',
     'Tulisan terakhir menimpa hasil A', 'UPDATE atomik, lock, atau optimistic lock'),
    ('write skew', 'A dan B cek aturan; ubah baris berbeda',
     'REPEATABLE READ dapat melanggar aturan lintas-baris', 'SERIALIZABLE + retry'),
    ('read skew', 'A baca satu rekening; transfer COMMIT; A baca rekening lain',
     'A mencampur dua snapshot dan total menjadi tidak konsisten',
     'Satu query agregat atau REPEATABLE READ')
) AS matriks(anomali, cara_reproduksi, hasil, mitigasi);

-- ===========================================================================
-- Q31 — REKOMENDASI ISOLATION LEVEL
-- ===========================================================================
SELECT *
FROM (VALUES
    ('Pembacaan sederhana yang menerima perubahan', 'READ COMMITTED',
     'Snapshot baru per statement; risiko hasil antarstatement berubah'),
    ('Laporan beberapa statement dengan snapshot konsisten', 'REPEATABLE READ READ ONLY',
     'Snapshot stabil, tetapi tidak melihat commit baru hingga transaksi selesai'),
    ('Aturan bisnis lintas-baris/predicate', 'SERIALIZABLE',
     'Aman dari write skew, tetapi harus retry SQLSTATE 40001')
) AS rekomendasi(kebutuhan, isolation_level, kompromi_dan_risiko);

-- ===========================================================================
-- Q32 — TIGA PELAJARAN BERBASIS BUKTI
-- ===========================================================================
-- 1. Q6 (1000000 -> 900000) dan Q7 (tetap 1000000) membuktikan perbedaan
--    snapshot per-statement dan snapshot per-transaksi.
-- 2. Q24 mengembalikan id=2 ketika id=1 dikunci; Q25 mengembalikan 55P03.
--    Strategi worker harus memilih lewati-pekerjaan atau gagal-cepat.
-- 3. Q26 berakhir dokter_aktif=0, sedangkan Q27 mengeluarkan 40001 dan
--    mempertahankan dokter aktif. SERIALIZABLE harus diiringi retry penuh.

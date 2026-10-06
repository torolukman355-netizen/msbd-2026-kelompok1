-- ============================================================
-- Q13: EXPRESSION INDEX (Index pada Ekspresi)
-- ============================================================
-- Tujuan:
--   Memahami kapan expression index dipakai dan kapan tidak.
--
-- Apa itu Expression Index?
--   Index yang di-index bukan kolom langsung, tapi HASIL EKSPRESI
--   dari kolom. Contoh: lower(email), upper(nama), (harga * 1.1).
--
-- Aturan utama:
--   Expression index HANYA dipakai kalau expression di query
--   PERSIS SAMA dengan definisi index. Beda dikit saja, tidak dipakai.
--
-- Hasil yang diharapkan:
--   | Query                                  | Index dipakai        |
--   |----------------------------------------|----------------------|
--   | WHERE email = 'user1@example.com'      | ev_email_biasa_idx   |
--   | WHERE lower(email) = 'user1@example.com'| ev_email_lower_idx  |
--
-- Kenapa "WHERE email = ..." tidak bisa pakai ev_email_lower_idx?
--   Karena "email" dan "lower(email)" adalah NILAI YANG BERBEDA.
--   PostgreSQL tidak tahu bahwa email='user1@example.com' setara
--   dengan lower(email)='user1@example.com'.
--
-- Kapan dipakai?
--   - Query case-insensitive: WHERE lower(email) = ...
--   - Transformasi tetap: WHERE (harga * 1.1) > 1000
-- ============================================================

DROP INDEX IF EXISTS lab6.ev_email_lower_idx;
DROP INDEX IF EXISTS lab6.ev_email_biasa_idx;

-- Index biasa pada kolom email
CREATE INDEX ev_email_biasa_idx ON lab6.event_log (email);

-- Expression index pada lower(email)
CREATE INDEX ev_email_lower_idx ON lab6.event_log (lower(email));

-- Query 1: pakai email = '...' -> harus pakai ev_email_biasa_idx
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id 
FROM lab6.event_log 
WHERE email = 'user1@example.com';

-- Query 2: pakai lower(email) = '...' -> harus pakai ev_email_lower_idx
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id 
FROM lab6.event_log 
WHERE lower(email) = 'user1@example.com';
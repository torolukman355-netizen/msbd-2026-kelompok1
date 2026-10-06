\timing on

-- Q27: Perbandingan Waktu INSERT 200.000 baris (Tanpa Index vs 5 Index)
CREATE SCHEMA IF NOT EXISTS lab6;
CREATE TABLE lab6.event_log_q27 (LIKE lab6.event_log INCLUDING ALL);

ALTER TABLE lab6.event_log_q27 DROP CONSTRAINT event_log_q27_pkey;

--Uji 1:
INSERT INTO lab6.event_log_q27 (customer_id, terjadi_pada, status, wilayah, kota, email, idempotency_key, jumlah, tags, payload)
SELECT (random()*59999)::int+1,
  timestamptz '2024-01-01 00:00+07'+(g*interval '13 second'),
  CASE WHEN g%50=0 THEN 'GAGAL' WHEN g%7=0 THEN 'TERTUNDA' ELSE 'SUKSES' END,
  w.nama, w.nama||'-'||((g%9)+1), 'user'||g||'@contoh.ac.id', gen_random_uuid(),
  round((random()*900+10)::numeric,2), ARRAY['kanal:'||(g%4),'sumber:'||(g%3)],
  jsonb_build_object('kanal',g%4,'perangkat',g%6,'promo',(g%25=0))
FROM generate_series(1, 200000) AS s(g)
CROSS JOIN LATERAL (SELECT (ARRAY['SUMUT','JABAR','JATIM','BALI','PAPUA'])[(g%5)+1] AS nama) AS w;

-- HASIL UJI 1: 3043.369 ms (00:03.043) ms


--  Buat 5 Index 
CREATE INDEX idx_q27_1 ON lab6.event_log_q27 (terjadi_pada DESC) WHERE status='GAGAL';
CREATE INDEX idx_q27_2 ON lab6.event_log_q27 (lower(email));
CREATE INDEX idx_q27_3 ON lab6.event_log_q27 (customer_id) INCLUDE (terjadi_pada, jumlah);
CREATE INDEX idx_q27_4 ON lab6.event_log_q27 USING gin (payload jsonb_path_ops);
CREATE INDEX idx_q27_5 ON lab6.event_log_q27 USING gin (tags);


--  UJI 2: 
INSERT INTO lab6.event_log_q27 (customer_id, terjadi_pada, status, wilayah, kota, email, idempotency_key, jumlah, tags, payload)
SELECT (random()*59999)::int+1,
  timestamptz '2024-01-01 00:00+07'+(g*interval '13 second'),
  CASE WHEN g%50=0 THEN 'GAGAL' WHEN g%7=0 THEN 'TERTUNDA' ELSE 'SUKSES' END,
  w.nama, w.nama||'-'||((g%9)+1), 'user'||g||'@contoh.ac.id', gen_random_uuid(),
  round((random()*900+10)::numeric,2), ARRAY['kanal:'||(g%4),'sumber:'||(g%3)],
  jsonb_build_object('kanal',g%4,'perangkat',g%6,'promo',(g%25=0))
FROM generate_series(1, 200000) AS s(g)
CROSS JOIN LATERAL (SELECT (ARRAY['SUMUT','JABAR','JATIM','BALI','PAPUA'])[(g%5)+1] AS nama) AS w;

-- HASIL UJI 2: 10077.532 ms (00:10.078) ms



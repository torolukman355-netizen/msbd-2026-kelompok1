-- Diminta: nama pelanggan yang pernah melakukan pembayaran lebih dari 9.99 dalam satu transaksi.
-- Dipilih: EXISTS berkorelasi karena hanya perlu memeriksa keberadaan transaksi yang memenuhi syarat, tanpa perlu menggabungkan/duplikasi baris.
-- Alternatif: JOIN + DISTINCT; tidak dipilih karena bisa menghasilkan baris duplikat yang harus dibuang manual, dan soal memang meminta menghindari pendekatan ini.

SELECT
    c.first_name,
    c.last_name
FROM customer c
WHERE EXISTS (
    SELECT 1
    FROM payment p
    WHERE p.customer_id = c.customer_id
      AND p.amount > 9.99
);
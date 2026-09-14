-- Diminta: Melakukan refresh materialized view secara konkuren (CONCURRENTLY) dan mencatat waktunya.
-- Dipilih: REFRESH MATERIALIZED VIEW CONCURRENTLY karena memungkinkan pembaruan tanpa mengunci tabel (non-blocking).
-- Alternatif: Refresh biasa (tanpa CONCURRENTLY); tidak dipilih karena mengunci tabel dan membuat akses baca tertahan.

REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;
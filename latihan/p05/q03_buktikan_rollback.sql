-- sebelum
SELECT count(*) AS rental_sebelum FROM lab5.rental_tx;

-- panggil dengan amount negatif (harus gagal di domain positive_amount)
CALL lab5.process_rental(1, 1, 1, -4.99);

-- sesudah
SELECT count(*) AS rental_sesudah FROM lab5.rental_tx;
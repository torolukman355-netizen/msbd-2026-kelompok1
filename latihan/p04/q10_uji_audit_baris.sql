-- Diminta: Menguji 3 skenario UPDATE (mengubah harga, menulis ulang harga sama, mengubah title saja) dan membuktikan hanya perubahan harga yang masuk ke lab4.audit_harga.
-- Dipilih: Mengosongkan tabel audit terlebih dahulu (TRUNCATE), menjalankan 3 instruksi UPDATE berbeda, lalu mengecek hasil SELECT.
-- Alternatif: Menjalankan UPDATE tanpa membersihkan audit terlebih dahulu; tidak dipilih karena membuat jumlah baris hasil pengujian sulit diverifikasi secara presisi.

TRUNCATE TABLE lab4.audit_harga;

-- Skenario 1: Mengubah rental_rate ke nilai baru (Harus mencatat audit)
UPDATE lab4.film 
SET rental_rate = 3.99 
WHERE film_id = 1;

-- Skenario 2: Menulis ulang rental_rate dengan nilai yang persis sama (Harus diabaikan)
UPDATE lab4.film 
SET rental_rate = 3.99 
WHERE film_id = 1;

-- Skenario 3: Mengubah kolom title saja (Harus diabaikan)
UPDATE lab4.film 
SET title = 'ACADEMY DINOSAUR REVISITED' 
WHERE film_id = 1;

-- Bukti Pengujian
SELECT audit_id, film_id, harga_lama, harga_baru, diubah_oleh, diubah_pada 
FROM lab4.audit_harga;

/*
PENJELASAN ELEMEN TRIGGER YANG MENGHALANGI AUDIT PALSU:
1. "OF rental_rate": Memastikan trigger HANYA terpicu jika statement UPDATE menyertakan kolom rental_rate. Hal ini langsung mengeksklusi Skenario 3 (hanya ubah title).
2. "WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)": Klausa kondisi ini mengevaluasi apakah ada perubahan nilai secara faktual. Pada Skenario 2 (nilai baru sama dengan nilai lama), kondisi bernilai FALSE sehingga fungsi trigger tidak dieksekusi sama sekali.
*/
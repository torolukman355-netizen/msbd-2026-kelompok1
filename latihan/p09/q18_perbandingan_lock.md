**Q18. Perbandingan Jenis Row Lock (Penguncian Baris)**

PostgreSQL memiliki empat tingkat penguncian baris eksplisit. Berikut adalah tujuan umum dan kapan transaksi lain akan terhalang (*blocking*):

**1. FOR UPDATE**
* **Tujuan:** Mengunci baris secara eksklusif karena akan diubah (`UPDATE`) kolom kuncinya, atau dihapus (`DELETE`). Ini adalah kunci paling kuat.
* **Transaksi lain terhalang jika mencoba:** Melakukan `UPDATE`, `DELETE`, atau meminta *lock* tipe apa pun (`FOR UPDATE`, `FOR NO KEY UPDATE`, `FOR SHARE`, `FOR KEY SHARE`) pada baris yang sama.

**2. FOR NO KEY UPDATE**
* **Tujuan:** Mengunci baris untuk pembaruan, tetapi memastikan kolom *primary/unique key* **tidak** ikut diubah. PostgreSQL menggunakan ini secara otomatis saat menjalankan perintah `UPDATE` biasa.
* **Transaksi lain terhalang jika mencoba:** Melakukan `UPDATE`, `DELETE`, meminta `FOR UPDATE`, `FOR NO KEY UPDATE`, atau `FOR SHARE`.
* **Pengecualian (diizinkan):** Transaksi lain masih boleh meminta `FOR KEY SHARE`.

**3. FOR SHARE**
* **Tujuan:** Mengunci baris untuk dibaca (*shared lock*). Digunakan untuk memastikan data yang sedang dibaca tidak diubah atau dihapus oleh orang lain sampai transaksi selesai.
* **Transaksi lain terhalang jika mencoba:** Melakukan `UPDATE`, `DELETE`, meminta `FOR UPDATE`, atau `FOR NO KEY UPDATE`.
* **Pengecualian (diizinkan):** Transaksi lain boleh ikut membaca dan mengunci dengan `FOR SHARE` atau `FOR KEY SHARE`.

**4. FOR KEY SHARE**
* **Tujuan:** Kunci paling lemah. Biasanya digunakan otomatis oleh sistem saat memvalidasi *foreign key*, untuk memastikan nilai referensi (kunci) tidak dihapus saat dicek.
* **Transaksi lain terhalang jika mencoba:** Melakukan `DELETE` atau mengubah nilai kolom kunci (`FOR UPDATE`).
* **Pengecualian (diizinkan):** Transaksi lain masih bebas memperbarui kolom non-kunci (`FOR NO KEY UPDATE`), serta meminta `FOR SHARE` dan `FOR KEY SHARE`.
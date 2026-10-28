**Q29. Pseudocode retry transaksi**

Retry harus mengulang **seluruh transaksi**. Setelah `40001` (serialization failure) atau `40P01` (deadlock detected), snapshot atau status transaksi lama tidak lagi aman untuk dipakai; mengulang hanya statement yang gagal dapat menghasilkan keputusan bisnis yang salah.

```text
MAX_PERCOBAAN = 5
JEDA_AWAL_MS = 50
JEDA_MAKS_MS = 1_000

untuk percobaan dari 1 sampai MAX_PERCOBAAN:
    coba:
        mulai transaksi dengan isolation level SERIALIZABLE

        # Semua pembacaan, validasi aturan bisnis, dan penulisan harus berada
        # di dalam blok ini agar snapshot baru dipakai pada setiap percobaan.
        dokter_aktif = SELECT COUNT(*) FROM dokter_jaga WHERE aktif
        jika dokter_aktif <= 1:
            ROLLBACK
            kembalikan "dokter terakhir tidak boleh dinonaktifkan"

        UPDATE dokter_jaga
        SET aktif = FALSE
        WHERE dokter_id = dokter_yang_dipilih

        COMMIT
        kembalikan sukses

    tangkap DatabaseError sebagai error:
        # ROLLBACK aman dipanggil bila transaksi masih terbuka/aborted.
        ROLLBACK jika masih ada transaksi aktif

        jika error.sqlstate bukan "40001" dan bukan "40P01":
            lempar ulang error       # misalnya constraint, sintaks, atau koneksi

        jika percobaan == MAX_PERCOBAAN:
            lempar "gagal setelah retry", penyebab=error

        jeda = minimum(JEDA_AWAL_MS * 2^(percobaan - 1), JEDA_MAKS_MS)
        jitter = angka_acak(0, JEDA_AWAL_MS)
        tunggu(jeda + jitter)

lempar "tidak seharusnya tercapai"
```

Jeda eksponensial dengan *jitter* mengurangi kemungkinan transaksi-transaksi yang sama kembali bertabrakan pada waktu yang identik. Operasi di dalam transaksi juga sebaiknya idempoten atau memakai idempotency key bila transaksi memicu efek eksternal, seperti mengirim pesan atau menagih pembayaran.

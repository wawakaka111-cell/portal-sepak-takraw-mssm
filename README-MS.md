# Portal Sepak Takraw MSSM — Starter Kit

## Kandungan
- `index.html` — portal awam (paparan baca sahaja)
- `admin.html` — panel admin untuk tahun, pasukan, keputusan dan pengumuman
- `schema.sql` — struktur database Supabase, view kedudukan dan polisi keselamatan RLS
- `supabase-config.js` — tempat konfigurasi URL dan anon/publishable key
- `common.js`, `style.css` — fungsi dan gaya bersama

## 1. Cipta projek Supabase
1. Daftar/log masuk di https://supabase.com/
2. Cipta projek baharu.
3. Buka Project Settings > API (atau Data API / API Keys).
4. Salin Project URL dan publishable/anon key. **Jangan gunakan `service_role` key dalam fail website.**

## 2. Cipta database
1. Dalam Supabase, buka SQL Editor.
2. Tampal seluruh kandungan `schema.sql`.
3. Tekan Run dan semak tiada ralat.

## 3. Sambungkan website
Buka `supabase-config.js`, gantikan:
- `PASTE_PROJECT_URL_HERE`
- `PASTE_PUBLISHABLE_OR_ANON_KEY_HERE`

Gunakan URL dan public anon/publishable key sahaja. Jangan masukkan kata laluan database atau service_role key.

## 4. Cipta admin pertama
1. Supabase > Authentication > Users > Add user.
2. Daftarkan e-mel admin dan kata laluan sementara.
3. Salin UUID pengguna tersebut.
4. Supabase > SQL Editor, jalankan (gantikan UUID):
   ```sql
   update public.profiles
   set role = 'admin'
   where id = 'UUID-PENGGUNA-ANDA';
   ```
5. Untuk admin tambahan, ulangi langkah 1–4 bagi setiap pengguna. Sistem menyokong lebih daripada 5 admin.
6. Pastikan hanya orang yang dipercayai diberi role `admin`.

## 5. Jalankan dan terbitkan
Untuk ujian, buka `index.html` dan `admin.html` melalui local web server atau hosting statik. Untuk terbitan, muat naik semua fail ke GitHub Pages/Netlify/hosting pilihan. Konfigurasi URL redirect dan allowed origins di Supabase Authentication mengikut domain sebenar.

## Fungsi yang tersedia dalam starter
- Portal awam: tahun kejohanan, pengumuman terbit, keputusan, pasukan, kedudukan asas, pegawai, galeri dan siaran langsung.
- Admin: login, tambah/tukar tahun aktif, daftar/padam pasukan, rekod/padam keputusan, tambah/padam pengumuman.
- Kedudukan asas: 2 mata untuk menang, 0 mata untuk kalah bagi perlawanan berstatus `Tamat`.

## Nota keselamatan dan skop
- RLS database menghadkan operasi tambah/ubah/padam kepada akaun dengan `profiles.role = 'admin'`.
- Orang awam boleh membaca rekod portal; pengumuman draf tidak dipaparkan pada portal awam.
- Peranan admin perlu ditetapkan secara manual oleh pemilik projek melalui SQL Editor. Jangan bina fungsi pendaftaran awam yang boleh menaikkan role sendiri.
- Upload imej sebenar memerlukan Supabase Storage bucket dan polisi Storage. Starter ini menyimpan URL imej dalam jadual galeri; ia belum memuat naik fail ke Storage.
- Carta kedudukan ini ialah asas; peraturan mata, tie-break, format perlawanan dan pengesahan teknikal perlu disahkan mengikut peraturan kejohanan sebenar.
- Sebelum pelancaran, uji dengan data contoh dan semak polisi akses bersama pentadbir sistem.

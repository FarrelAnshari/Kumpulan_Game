# DOKUMEN ARSITEKTUR & ROADMAP V2.0
## SEPEDA PETUALANG – 3D VEHICLE ADVENTURE RUNNER

**Status:** Dokumen Arsitektur Resmi  
**Engine:** Godot 4.7.2 Stable (Jolt Physics 3D)  
**Programming Language:** GDScript  
**Target Platform:** Android dan Web Demo  
**Target Pemain:** Anak usia 5–10 tahun  
**Orientasi:** Portrait 720 × 1280  
**Genre:** 3D Third-Person Endless Runner / Vehicle Adventure  

---

# BAGIAN 1 – VISI DAN KONSEP GAME

## 1.1 Konsep Utama
Sepeda Petualang dikembangkan menjadi game petualangan kendaraan 3D dengan kamera third-person yang mengikuti karakter dari belakang.
Pemain dapat memilih berbagai kendaraan, mulai dari sepeda biasa, sepeda listrik, motor matic, motor sport, motor off-road, hingga kendaraan futuristik.
Pemain akan melewati berbagai lingkungan, mengumpulkan Gold Coin dan Diamond Gem, mengambil power-up, menghindari rintangan, menghadapi boss, serta membuka kendaraan dan karakter baru.

Fokus mekanik:
- Berpindah jalur (3 lajur).
- Menghindari rintangan.
- Melompat.
- Meluncur atau menunduk (slide).
- Mengambil koin dan gem.
- Mengaktifkan skill kendaraan.
- Menghadapi serangan boss.

## 1.2 Arah Visual
Gaya visual: **POLISHED STYLIZED SEMI-REALISTIC 3D**
- Model kendaraan 3D dengan detail komponen terlihat.
- Proporsi kendaraan dan pengendara natural.
- Material logam, karet, plastik, dan kain dapat dibedakan.
- Pencahayaan dan bayangan memberikan kesan kedalaman.
- Lingkungan 3D terintegrasi, bukan sekadar gambar background.
- Warna cerah menarik tanpa terlihat balita.

---

# BAGIAN 2 – GAMEPLAY UTAMA

## 2.1 Kamera dan Pergerakan
- Kamera third-person di belakang dan sedikit di atas kendaraan.
- Smooth follow horizontal mengikuti perpindahan lajur.
- Mengikuti elevasi tanjakan/turunan.
- Feedback halus saat melompat, mendarat, terkena serangan, atau turbo.

## 2.2 Sistem Tiga Lajur & Lintasan Modular
- Lajur: Kiri (-1), Tengah (0), Kanan (+1).
- Input: Swipe Kiri/Kanan/Atas/Bawah (Slide) serta Keyboard A/D/Space/S.
- Geometri Lintasan (Addendum 3D):
  - Lebar per lajur awal: ~3,5 meter.
  - Bahu jalan (shoulder): ~1,5 meter per sisi.
  - Total lebar lintasan awal: ~13,5 meter (termasuk bahu jalan).
- Variasi modular: Lurus, tikungan, tanjakan, turunan, ramp melompat, jembatan, lintasan bertingkat, arena boss.

## 2.3 Perbedaan Sepeda dan Motor
- Sepeda biasa: Kecepatan lebih rendah, handling lincah, lompat mudah.
- Sepeda listrik: Handling & akselerasi menengah, skill energi.
- Motor: Kecepatan lebih tinggi, ketahanan benturan lebih baik, skill khusus.

---

# BAGIAN 3 – SISTEM KENDARAAN DAN KARAKTER
- Target 100 Kendaraan (60 Motor, 25 Sepeda biasa/sport, 15 Sepeda listrik).
- Target 25 Karakter 3D.
- 5 Tingkat Rarity: Common (40), Rare (25), Epic (20), Legendary (10), Mythic (5).
- Karakter memberikan bonus pasif, kendaraan memiliki skill aktif utama.

---

# BAGIAN 4 – POWER-UP & SKILL
- Item Box gameplay gratis: Shield, Magnet, Turbo, Jump Boost, Repair Kit, Slow Motion.
- Cooldown dan durasi seimbang agar tidak membuat pemain kebal permanen.

---

# BAGIAN 5 – SISTEM HP, RINTANGAN, DAN BOSS
- Durability: 100 HP (benturan ringan -10, sedang -20, boss -25, repair kit +25).
- Invincibility window pasca-benturan.
- Layar gagal ramah anak: "Ayo Coba Lagi!" tanpa kekerasan.
- Boss encounter setiap kelipatan 5 level (total 20 boss encounters dalam 100 level).

---

# BAGIAN 6 – 5 DUNIA & 100 LEVEL
- World 1 (Level 1–20): Desa dan Sawah.
- World 2 (Level 21–40): Pantai dan Kepulauan.
- World 3 (Level 41–60): Pegunungan dan Hutan.
- World 4 (Level 61–80): Kota dan Kawasan Industri.
- World 5 (Level 81–100): Dunia Futuristik.

---

# BAGIAN 7 – EKONOMI & MONETISASI
- Gold Coin: Mata uang utama hasil gameplay untuk kendaraan Common/Rare, warna, upgrade.
- Diamond Gem: Mata uang premium hasil reward achievement, level, dan boss.
- Top-up Gem di masa depan wajib melalui Google Play Billing + Parent Gate.
- Tanpa iklan dan tanpa paid loot box pada versi awal.

---

# BAGIAN 8 – TEKNOLOGI & INFRASTRUKTUR GODOT
- Godot 4.7.2 Stable.
- Jolt Physics 3D (bawaan resmi engine).
- Dual renderer strategy: Mobile (Android) dan Compatibility (Web Demo).
- Format model 3D: GLB/glTF 2.0.

---

# ROADMAP 12 FASE PENGEMBANGAN
1. Fase 1 – Migrasi dan Setup 3D (Baseline, scene bootstrap 3D, input, renderer).
2. Fase 2 – Track 3D dan Kamera (Lintasan 3 lajur modular, camera follow).
3. Fase 3 – Pemain, Sepeda dan Motor (Controller, animasi, perpindahan lajur).
4. Fase 4 – Rintangan, Collectible dan HP (100 HP, collision, koin/gem).
5. Fase 5 – Power-Up dan Skill (Item box, shield, magnet, turbo).
6. Fase 6 – Boss System (Prototype boss encounter).
7. Fase 7 – Progression dan 100 Level (LevelData, 5 dunia, bintang).
8. Fase 8 – Garage dan Katalog Koleksi (Katalog 100 kendaraan & 25 karakter).
9. Fase 9 – Gold, Gem, Shop dan Save (Ekonomi & save system).
10. Fase 10 – UI, Audio dan Pengalaman Pengguna (Menu, HUD, audio, lokalisasi ID/EN).
11. Fase 11 – Optimasi dan Web Demo (Profiling, export web, playtesting).
12. Fase 12 – Monetisasi dan Rilis Play Store (AAB, Google Play Families, Store listing).

---

# BAGIAN 16 – STANDAR PEMROGRAMAN, DATA, DAN PENYIMPANAN

1. **Bahasa Pemrograman Utama:**
   GDScript menjadi bahasa utama pengembangan seluruh logika gameplay, controller, dan antarmuka.
2. **Arsitektur Data-Driven (.tres / .res):**
   Gunakan Godot Resource (`.tres` atau `.res`) untuk mendefinisikan data statis game: `VehicleData`, `CharacterData`, `LevelData`, `BossData`, `SkillData`, dan `PowerUpData`.
3. **Penyimpanan Lokal Pemain:**
   Gunakan `user://save_data.json` untuk menyimpan progres pemain secara offline pada perangkat lokal.
4. **Pemisahan Referensi Aset & Save Data:**
   Data unlock kendaraan dan karakter hanya menyimpan ID dan status kepemilikan (misalnya string ID atau integer). Dilarang menggandakan model 3D, mesh, tekstur, atau data audio ke dalam file save JSON.
5. **Keandalan & Skema SaveManager:**
   `SaveManager` wajib memiliki schema version, sistem validasi data saat pemuatan, nilai default fallback, serta mekanisme pemulihan (recovery) jika file penyimpanan lokal rusak atau tidak terbaca.
6. **Tanpa Backend Eksternal pada Tahap Awal:**
   Jangan menambahkan MySQL, Firebase, Supabase, atau backend eksternal pada tahap awal tanpa persetujuan resmi.
7. **Kesiapan Cloud Save:**
   Rancang struktur data agar dapat dikembangkan menjadi Cloud Save dan integrasi verifikasi pembelian melalui backend di masa depan.
8. **Optimasi Ukuran Aplikasi:**
   Optimalkan model 3D, tekstur, animasi, audio, dan aset lingkungan agar ukuran aplikasi terkendali dan ringan diunduh.
9. **Pemisahan Aset Bawaan vs Progres Pemain:**
   Bedakan secara tegas data aset bawaan game (read-only di `res://`) dengan data progres dinamis pemain (read-write di `user://`).
10. **Integritas Hak Pembelian Berbayar:**
    Saldo dan hak pembelian berbayar tidak boleh hanya mengandalkan JSON lokal sebagai sumber kebenaran.

# DOKUMEN ARSITEKTUR & ROADMAP V2.0
## SEPEDA PETUALANG – 3D VEHICLE ADVENTURE RUNNER

**Status:** Dokumen Arsitektur & Spesifikasi Resmi Proyek  
**Engine:** Godot 4.7.2 Stable (Jolt Physics 3D)  
**Programming Language:** GDScript  
**Target Platform:** Android dan Web Demo  
**Target Pemain:** Anak usia 5–10 tahun  
**Orientasi:** Portrait 720 × 1280 (`canvas_items`, `expand`)  
**Genre:** 3D Third-Person Endless Runner / Vehicle Adventure  

---

# BAGIAN 1 – VISI DAN KONSEP GAME

## 1.1 Konsep Utama
Sepeda Petualang dikembangkan menjadi game petualangan kendaraan 3D dengan kamera third-person yang mengikuti karakter dari belakang.

Pemain dapat memilih berbagai kendaraan, mulai dari sepeda biasa, sepeda listrik, motor matic, motor sport, motor off-road, hingga kendaraan futuristik.

Pemain akan melewati berbagai lingkungan, mengumpulkan Gold Coin dan Diamond Gem, mengambil power-up, menghindari rintangan, menghadapi boss, serta membuka kendaraan dan karakter baru.

Game menggunakan sistem perjalanan otomatis ke depan. Pemain berfokus pada:
- Berpindah jalur (3 lajur).
- Menghindari rintangan.
- Melompat.
- Meluncur atau menunduk (slide) untuk melewati rintangan rendah.
- Mengambil koin dan gem.
- Mengaktifkan skill kendaraan.
- Menghadapi serangan boss.

Game bukan simulator motor realistis yang mengharuskan pemain mengatur kopling, rem, dan transmisi. Fokus utamanya adalah gameplay arcade yang mudah dipelajari tetapi tetap memiliki tantangan.

## 1.2 Arah Visual
Gaya visual: **POLISHED STYLIZED SEMI-REALISTIC 3D**

Karakteristik:
- Model kendaraan 3D dengan detail komponen yang terlihat.
- Proporsi kendaraan dan pengendara natural.
- Material logam, karet, plastik, dan kain dapat dibedakan.
- Pencahayaan dan bayangan memberikan kesan kedalaman.
- Animasi kendaraan dan karakter tidak kaku.
- Lingkungan memiliki objek 3D yang terintegrasi, bukan sekadar gambar background.
- Warna cerah dan menarik tanpa terlihat seperti kartun balita.
- Efek skill dan boss memiliki kualitas visual yang konsisten.

Referensi pengalaman gameplay:
- **Subway Surfers:** Kamera mengikuti karakter dan pola runner.
- **Temple Run:** Perjalanan melewati lingkungan dengan kedalaman.
- **Mario Kart:** Item box dan power-up.
- **Stumble Guys:** Rarity dan koleksi karakter.

Referensi tersebut hanya untuk inspirasi mekanik. Model, identitas visual, karakter, dan aset harus orisinal.

Nama *Sepeda Petualang* masih dipertahankan sebagai nama kerja. Penyesuaian nama menjadi lebih umum seperti *Petualang Roda* dapat dipertimbangkan karena sekarang motor dan sepeda sama-sama menjadi kendaraan utama.

---

# BAGIAN 2 – GAMEPLAY UTAMA

## 2.1 Kamera dan Pergerakan
Gunakan kamera third-person di belakang kendaraan.

Struktur kamera:
- Kamera berada di belakang dan sedikit di atas pengendara.
- Kamera mengikuti kendaraan menggunakan smoothing.
- Pergerakan kamera horizontal mengikuti perpindahan lajur.
- Kamera mengikuti elevasi ketika kendaraan naik atau turun.
- Kamera tidak berguncang secara berlebihan.
- Tambahkan sedikit feedback kamera ketika melompat, mendarat, terkena serangan, atau menggunakan turbo.

Targetnya adalah kamera terasa hidup seperti game runner 3D komersial.

## 2.2 Sistem Tiga Lajur
Pertahankan sistem tiga lajur sebagai dasar gameplay.

| Lajur | Fungsi | Posisi Relatif |
|---|---|---|
| Kiri | Jalur kiri | $X = -3,5\text{ m}$ |
| Tengah | Jalur tengah | $X = 0,0\text{ m}$ |
| Kanan | Jalur kanan | $X = +3,5\text{ m}$ |

Input:
- **Swipe Kiri:** Pindah kiri.
- **Swipe Kanan:** Pindah kanan.
- **Swipe Atas:** Lompat.
- **Swipe Bawah:** Slide atau menunduk.
- **Tombol Keyboard A / D:** Perpindahan lajur.
- **Space / W:** Lompat.
- **S:** Slide.

Pergerakan harus halus menggunakan interpolasi.

## 2.3 Sistem Lintasan 3D
Jalan tidak lagi menggunakan trapesium pseudo-perspective 2D. Gunakan sistem modular 3D Track Segment.

Jenis lintasan:
1. Jalan lurus.
2. Tikungan.
3. Tanjakan.
4. Turunan.
5. Ramp untuk melompat.
6. Jembatan.
7. Lintasan bertingkat.
8. Jalur alternatif atas dan bawah.
9. Jalan sempit.
10. Lintasan khusus boss.

Kendaraan berjalan otomatis mengikuti lintasan. Konstruksi lintasan harus dapat digabung menjadi rangkaian level melalui konfigurasi LevelData.

## 2.4 Perbedaan Sepeda dan Motor
Keduanya merupakan kendaraan yang dapat dimainkan.

**Sepeda Biasa:**
- Kecepatan dasar lebih rendah.
- Kontrol lincah.
- Lompatan relatif mudah.
- Ketahanan benturan lebih rendah.

**Sepeda Listrik:**
- Kecepatan dan handling menengah.
- Memiliki karakteristik akselerasi berbeda.
- Dapat mempunyai skill energi.

**Motor:**
- Kecepatan dasar lebih tinggi.
- Ketahanan kendaraan lebih baik.
- Karakteristik handling menyesuaikan jenis motor.
- Dapat memiliki skill kendaraan tertentu.

Statistik harus tetap seimbang. Rarity tinggi tidak boleh otomatis membuat kendaraan menjadi wajib untuk menyelesaikan level.

---

# BAGIAN 3 – SISTEM KENDARAAN DAN KARAKTER

## 3.1 Katalog Kendaraan
Target rilis: 100 kendaraan.

Kategori kendaraan yang direncanakan:
1. City Scooter.
2. Sport Motorcycle.
3. Racing Motorcycle.
4. Off-road Motorcycle.
5. Adventure Motorcycle.
6. Tactical Motorcycle.
7. Futuristic Motorcycle.
8. Standard Bicycle.
9. Mountain Bike.
10. BMX Bicycle.
11. Electric Bicycle.

Target distribusi awal yang diusulkan:

| Jenis | Jumlah |
|---|---:|
| Motor berbagai kategori | 60 |
| Sepeda biasa dan sport | 25 |
| Sepeda listrik | 15 |
| **Total** | **100** |

## 3.2 Rarity Kendaraan
Target 100 kendaraan dibagi menjadi 5 tingkat kelangkaan:

| Rarity | Jumlah | Karakteristik |
|---|---:|---|
| **Common** | 40 | Kendaraan standar, variasi warna dan aksesori, tanpa skill khusus. |
| **Rare** | 25 | Desain unik, bonus pasif ringan (misal handling atau bonus koin kecil). |
| **Epic** | 20 | Mulai memiliki skill aktif (Coin Magnet, Shield, Turbo). |
| **Legendary** | 10 | Skill lebih kuat, durasi/efek lebih baik, animasi & efek visual eksklusif. |
| **Mythic** | 5 | Ultimate skill dengan identitas eksklusif masing-masing kendaraan. |
| **Total** | **100** | |

Semua skill memiliki batasan cooldown dan durasi agar keseimbangan gameplay tetap terjaga.

## 3.3 Katalog Karakter
Target rilis: 25 karakter.

| Rarity | Jumlah |
|---|---:|
| Common | 10 |
| Rare | 7 |
| Epic | 4 |
| Legendary | 3 |
| Mythic | 1 |
| **Total** | **25** |

Karakter memiliki:
- Model 3D pengendara.
- Animasi mengendarai, melompat, terkena benturan, dan aktivasi skill.
- Berbagai helm, pakaian, dan aksesori.
- Karakter menggunakan skeleton dan sistem animasi bersama yang dapat digunakan kembali.

Sistem karakter dan kendaraan dipisahkan: Karakter memberikan satu bonus pasif, sedangkan kendaraan mempunyai skill aktif utama. Efek gabungan tetap dibatasi.

## 3.4 Strategi Produksi 3D
Produksi 125 aset utama (25 karakter + 100 kendaraan) merupakan pekerjaan besar.
Untuk membuatnya realistis:
- Gunakan Blender untuk produksi model 3D.
- Gunakan GLB/glTF 2.0 sebagai format pertukaran aset ke Godot.
- Buat beberapa keluarga rangka kendaraan modular (roda, rangka, bodi, setang, aksesori).
- Gunakan material dan decal untuk variasi visual yang tetap memiliki identitas kuat.
- Buat Level of Detail (LOD) untuk aset yang terlihat dari jauh.

---

# BAGIAN 4 – SISTEM SKILL DAN POWER-UP

## 4.1 Item Box
Item box merupakan objek gameplay gratis yang dapat diambil di jalan untuk memperoleh power-up (bukan pembelian berbayar):

| Item | Fungsi |
|---|---|
| **Shield** | Melindungi dari satu benturan |
| **Magnet** | Menarik Gold Coin dan gem di sekitar |
| **Turbo** | Menambah kecepatan sementara |
| **Jump Boost** | Membantu melompati rintangan tertentu |
| **Repair Kit** | Memulihkan HP kendaraan (+25 HP) |
| **Slow Motion** | Memperlambat gerakan rintangan sementara |

Item box dan skill kendaraan tidak boleh bertumpuk sehingga membuat pemain kebal permanen.

## 4.2 Efek Visual Skill
Skill harus memiliki animasi yang jelas:
- Shield: Lapisan energi mengelilingi kendaraan.
- Magnet: Efek tarikan partikel koin menuju kendaraan.
- Turbo: Efek api/energi di belakang kendaraan.
- Jump Boost: Efek dorongan energi di roda.
- Repair: Efek kilau cahaya pemulihan.

---

# BAGIAN 5 – SISTEM HP, RINTANGAN, DAN BOSS

## 5.1 Durability Kendaraan (100 HP)
Gunakan sistem HP 100:
- Benturan ringan: -10 HP.
- Benturan sedang: -20 HP.
- Serangan boss: -25 HP.
- Repair Kit: +25 HP (maksimal 100 HP).
- Invincibility window singkat pasca-benturan untuk mencegah pengurangan HP berulang.

Ketika HP mencapai nol:
- Kendaraan berhenti secara aman.
- Tampilkan animasi gagal yang ramah anak dengan pesan "Ayo Coba Lagi!".
- Tanpa kekerasan, luka, atau kehancuran yang menakutkan.

## 5.2 Variasi Rintangan
- **Rintangan Jalan:** Batu besar, kardus, lubang jalan, genangan air, penghalang jalan, kendaraan parkir.
- **Rintangan Bergerak:** Hewan menyeberang, kendaraan melintas, rintangan kiri-kanan, gerbang buka-tutup.
- **Rintangan Lingkungan:** Cabang pohon rendah, terowongan, ramp, jembatan rusak, jalur sempit.
- **Serangan Boss:** Gelombang kejut, benda dijatuhkan, barrier energi, serangan jalur target.

## 5.3 Sistem Boss
- Boss muncul setiap 5 level (Level 5, 10, 15, ..., 100) = **Total 20 boss encounters**.
- 5 Identitas boss utama (satu per dunia) dengan 4 variasi pola serangan yang meningkat.
- Boss dapat berupa kendaraan besar, robot, atau mesin fiktif (pertanian fiktif, mesin pantai, penjelajah gunung, mesin konstruksi, kendaraan futuristik).
- Kemenangan boss tidak harus dengan senjata; pemain dapat menghindar dan bertahan hingga objective selesai.

---

# BAGIAN 6 – SISTEM LEVEL DAN DUNIA

## 6.1 Struktur 100 Level & 5 Dunia
- **World 1 (Level 1–20) – Desa dan Sawah:** Desa tradisional, persawahan, perkampungan, jalan pedesaan, perkebunan. Boss: Mesin pertanian fiktif raksasa.
- **World 2 (Level 21–40) – Pantai dan Kepulauan:** Pantai tropis, pelabuhan, pulau kecil, jalan pesisir, kawasan wisata. Boss: Kendaraan laut/mesin pantai fiktif.
- **World 3 (Level 41–60) – Pegunungan dan Hutan:** Hutan pinus, jalan pegunungan, air terjun, terowongan, lintasan tebing. Boss: Kendaraan penjelajah besar.
- **World 4 (Level 61–80) – Kota dan Kawasan Industri:** Kota kecil, jalan perkotaan, kawasan industri, jembatan kota, area konstruksi. Boss: Mesin konstruksi / robotik.
- **World 5 (Level 81–100) – Dunia Futuristik:** Jalan futuristik, kota neon, gurun teknologi, kawasan energi, sci-fi. Boss: Kendaraan mesin futuristik canggih.

## 6.2 Progres Level & Kesulitan
- Setiap level memiliki nomor, dunia, lokasi, tingkat kesulitan, target jarak/durasi, target Gold/Gem, rangkaian track, rintangan, boss encounter, dan hadiah bintang (1–3).
- Pemain dapat melanjutkan ke level berikutnya tanpa harus meraih 100% target koleksi dalam satu kali bermain.
- Kesulitan meningkat bertahap melalui variasi rintangan dan kompleksitas track, bukan semata-mata menaikkan kecepatan secara ekstrem.

---

# BAGIAN 7 – SISTEM EKONOMI

## 7.1 Gold Coin
- Diperoleh dari: Lintasan jalan, penyelesaian level, misi harian, reward boss.
- Penggunaan: Kendaraan Common/Rare, variasi warna, aksesori, upgrade komponen.

## 7.2 Diamond Gem
- Diperoleh dari: Pencapaian (achievements), penyelesaian level tertentu, hadiah boss, misi khusus.
- Penggunaan: Kendaraan Epic/Legendary/Mythic, karakter tertentu, aksesori eksklusif.

## 7.3 Top-up Gem & Monetisasi Anak
- Hanya melalui Google Play Billing resmi untuk rilis Play Store.
- Top-up dinonaktifkan pada Web Demo.
- Pembelian harus melalui gerbang orang tua (**Parent Gate**) dan konfirmasi jelas.
- Tanpa timer manipulatif, tanpa tekanan emosional, tanpa paid loot box.

---

# BAGIAN 8 – ARSITEKTUR TEKNIS GODOT 3D

## 8.1 Teknologi Inti
- Godot 4.7.2 Stable.
- GDScript murni.
- Node3D, CharacterBody3D (arcade runner controller), Camera3D, Area3D.
- Jolt Physics 3D sebagai physics engine default bawaan engine.
- GLB / glTF 2.0 untuk aset model 3D.

## 8.2 Strategi Renderer
- Android: Mobile renderer (Vulkan) sebagai kandidat utama.
- Web: Compatibility renderer (WebGL).
- Pengujian material dan pencahayaan dilakukan konsisten agar kompatibel di kedua renderer.

## 8.3 Struktur Folder Proyek
```text
res://
├── assets/
│   ├── models/ (vehicles/, characters/, bosses/, environment/, obstacles/, collectibles/)
│   ├── materials/
│   ├── textures/
│   ├── animations/
│   ├── audio/
│   └── ui/
├── scenes/
│   ├── bootstrap_3d.tscn
│   ├── main_menu/
│   ├── garage/
│   ├── gameplay/
│   ├── vehicles/
│   ├── characters/
│   ├── obstacles/
│   ├── powerups/
│   ├── bosses/
│   ├── worlds/
│   └── ui/
├── scripts/
│   ├── autoload/ (game_state.gd, save_manager.gd, audio_manager.gd, economy_manager.gd)
│   ├── gameplay/
│   ├── player/
│   ├── vehicles/
│   ├── characters/
│   ├── obstacles/
│   ├── powerups/
│   ├── bosses/
│   ├── progression/
│   └── ui/
├── resources/
│   ├── vehicles/
│   ├── characters/
│   ├── skills/
│   ├── levels/
│   ├── bosses/
│   └── powerups/
├── translations/
├── reference/
│   └── Game 1.py
├── archive/
│   └── 2d_prototype/
├── docs/
│   └── ARCHITECTURE_V2.md
├── ASSETS_CREDITS.md
└── project.godot
```

## 8.4 Resource Data (Data-Driven)
Gunakan Godot Resource: `VehicleData`, `CharacterData`, `SkillData`, `LevelData`, `BossData`, `PowerUpData`.

## 8.5 Autoload Terpusat
Autoload yang direncanakan: `GameState`, `SaveManager`, `AudioManager`, `EconomyManager`, `InventoryManager`. Sistem gameplay lainnya dikelola oleh scene dan controller lokal.

---

# BAGIAN 9 – PENYIMPANAN DATA

Gunakan `user://save_data.json` sebagai rancangan penyimpanan lokal:
- Data yang disimpan: Level terbuka, perolehan bintang, Gold, Gem gratis, inventaris kendaraan & karakter yang dimiliki, kendaraan/karakter aktif, upgrade, preferensi audio, bahasa, dan kontrol.
- Ketentuan teknis:
  - Menggunakan versi skema data (schema version).
  - Validasi data saat dimuat.
  - Nilai default fallback jika data belum tersedia.
  - Mekanisme backup dan pemulihan saat file rusak.
  - Saldo pembelian digital tidak boleh hanya bersandar pada JSON lokal.

---

# BAGIAN 10 – PERFORMA DAN POLISHING

- Target: 60 FPS pada perangkat Android kelas menengah; minimal 30 FPS stabil pada Android spek rendah.
- Strategi:
  1. Model polygon terkendali (stylized semi-realistic budget).
  2. Level of Detail (LOD) untuk objek jauh.
  3. Object pooling untuk rintangan, koin, gem, dan track segment.
  4. MultiMeshInstance3D untuk vegetasi/lingkungan berulang.
  5. Membatasi lampu real-time (1 DirectionalLight3D utama dengan bayangan teroptimasi).
  6. Mengurangi transparansi tumpang tindih.
  7. Kompresi tekstur VRAM efisien (ETC2/ASTC).
  8. Profiling langsung pada perangkat fisik nyata.

---

# BAGIAN 11 – GOOGLE PLAY DAN KEAMANAN ANAK

Target pemain anak usia 5–10 tahun:
- Kepatuhan mutlak terhadap Google Play Families Policy.
- Tanpa kekerasan realistis, darah, atau luka.
- Tanpa iklan pada versi rilis awal.
- Tanpa obrolan publik (chat).
- Tidak mengumpulkan data pribadi anak.
- Menyediakan Privacy Policy resmi.
- Fitur transaksi berbayar dilindungi oleh Parent Gate.
- Deklarasi Data Safety dan Target Audience secara akurat.

---

# BAGIAN 12 – ROADMAP 12 FASE PENGEMBANGAN

- **Fase 1 – Migrasi dan Setup 3D:** Baseline repositori, scene bootstrap 3D, input touch/keyboard, evaluasi renderer, kalibrasi kamera dasar.
- **Fase 2 – Track 3D dan Kamera:** Lintasan 3 lajur modular, sistem kamera follow third-person, tanjakan, turunan, tikungan, dan lingkungan 3D awal.
- **Fase 3 – Pemain, Sepeda dan Motor:** Controller CharacterBody3D, 1 karakter, 1 sepeda, 1 motor, perpindahan lajur halus, lompat, slide.
- **Fase 4 – Rintangan, Collectible dan HP:** Gold Coin, Gem, rintangan statis & bergerak, sistem HP 100, damage, repair, dan collision.
- **Fase 5 – Power-Up dan Skill:** Item box, shield, magnet, turbo, jump boost, slow motion, dan sistem cooldown skill.
- **Fase 6 – Boss System:** Prototype boss encounter pertama, pola serangan, encounter logic, animasi, dan reward.
- **Fase 7 – Progression dan 100 Level:** LevelData, 5 dunia, 25 lokasi, 100 level, bintang, misi, dan 20 boss encounters.
- **Fase 8 – Garage dan Katalog Koleksi:** Garage 3D preview, katalog 100 kendaraan, 25 karakter, 5 tingkat rarity, dan sistem unlock.
- **Fase 9 – Gold, Gem, Shop dan Save:** Dompet koin/gem, toko dalam game, upgrade, penyimpanan aman `save_data.json`.
- **Fase 10 – UI, Audio dan Pengalaman Pengguna:** Menu utama, Garage UI, HUD, Result screen, Pause, tutorial visual, multi-bahasa ID/EN, SFX/BGM.
- **Fase 11 – Optimasi dan Web Demo:** Profiling performa HP, build Web export, pengujian demo via browser / itch.io, perbaikan bug.
- **Fase 12 – Monetisasi dan Rilis Play Store:** Integrasi Google Play Billing (IAP terlindungi), Parent Gate, Privacy Policy, AAB export, Store listing Google Play.

---

# BAGIAN 13 – GITHUB DAN VERSI PENGEMBANGAN

Repository: `https://github.com/FarrelAnshari/Kumpulan_Game.git`  
Branch Utama: `main`  
Branch Migrasi: `game-3d-migration`  

Aturan:
1. Periksa Git status sebelum mengubah file.
2. Pertahankan seluruh riwayat repository (no force push).
3. Hapus `Game 1.py` di root melalui commit biasa setelah salinan di `reference/Game 1.py` terverifikasi aman.
4. Buat branch baru untuk setiap fase dari `main` terbaru (`game-3d-fase-1`, `game-3d-fase-2`, dst).
5. Buat Pull Request dan tunggu persetujuan sebelum merge ke `main`.
6. Jangan upload folder `.godot/`, cache, atau file kredensial/kunci privat.

---

# BAGIAN 14 – PRINSIP PENGERJAAN

1. Kerjakan SATU fase dalam satu waktu.
2. Jangan melangkah ke fase berikutnya tanpa persetujuan resmi.
3. Gunakan dokumentasi resmi Godot 4.7.2; jangan mengarang API.
4. Jangan merusak fitur yang telah selesai.
5. Jangan menambahkan addon/plugin tanpa izin.
6. Uji setiap fitur di Godot Editor dan laporkan status secara jujur.
7. Lakukan commit dan push terstruktur sesuai alur GitHub.

---

# BAGIAN 15 – KRITERIA KEBERHASILAN PRODUK AKHIR

Produk dinyatakan selesai dan siap diajukan ke Google Play Store apabila:
- Gameplay runner 3D berjalan stabil pada 60 FPS di perangkat acuan.
- Sepeda dan motor dapat dimainkan dengan kontrol responsif.
- Kamera third-person mengikuti pergerakan dengan mulus.
- 100 level, 25 lokasi, dan 20 boss encounters selesai dibangun.
- Sistem HP 100, item box power-up, dan skill kendaraan berfungsi.
- Katalog 100 kendaraan dan 25 karakter tersedia dengan 5 rarity.
- Ekonomi Gold & Gem, Garage, Shop, dan Save system lokal berfungsi normal.
- Tampilan UI anak lengkap, mendukung Bahasa Indonesia dan Inggris.
- Memenuhi seluruh Families Policy Google Play Store.

---

# ADDENDUM ARSITEKTUR V2.0 – DESAIN LINTASAN 3D

Addendum ini mengatur spesifikasi teknis desain lintasan 3D agar memiliki ukuran luas, variasi tinggi, dan gameplay yang adil:

1. **Dimensi Tiga Lajur Utama:**
   - Lebar awal pengujian: **3,5 meter per lajur** (total 3 lajur = 10,5 meter).
   - Bahu jalan (shoulder): **1,5 meter pada setiap sisi** (kiri dan kanan).
   - **Total lebar awal lintasan: 13,5 meter** (termasuk bahu jalan).
   - Ukuran akhir dapat disesuaikan proporsional terhadap model kendaraan, rintangan, dan sudut kamera.
2. **Sistem Modular 3D Track Segment:**
   - Lintasan dibangun dari potongan segmen modular 3D yang dapat disambung secara berulang dan konsisten.
   - Sambungan antarsegmen wajib rapat **tanpa celah (no gap)** agar roda tidak tersangkut.
   - Kendaraan tidak boleh menembus permukaan lintasan (*clipping*).
3. **Variasi Geometri Lintasan:**
   - Jalan lurus lebar.
   - Jalan berkelok (tikungan halus).
   - Tanjakan dan turunan dengan transisi elevasi mulus.
   - Ramp untuk aksi melompat di udara.
   - Jembatan tinggi dan lintasan bertingkat.
   - Jalur alternatif atas dan bawah.
   - Arena boss dengan area ruang gerak yang lebih luas.
4. **Interaksi Kendaraan, Kamera, dan Lintasan:**
   - Kendaraan mengikuti perubahan elevasi dan arah lintasan secara natural.
   - Perpindahan 3 lajur tetap stabil dan responsif saat lintasan menanjak atau menikung.
   - Kamera mengikuti kendaraan dengan redaman (*smoothing*) tanpa getaran berlebih.
   - Rintangan dan collectible terikat pada koordinat geometri lintasan.
   - Jalur memiliki batas keselamatan visual yang jelas (curb / barrier) agar pemain memahami batas lintasan.
   - Tidak ada perubahan lebar jalan mendadak yang merugikan pemain secara tidak adil.

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

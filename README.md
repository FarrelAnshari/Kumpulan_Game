# Sepeda Petualang (Petualang Roda) 🚲🏍️
### 3D Third-Person Vehicle Adventure Runner for Kids (Ages 5–10)

Game petualangan kendaraan 3D (*third-person endless runner*) bertema Indonesia dan dunia futuristik ceria, dikembangkan menggunakan **Godot Engine 4.7.2 Stable (GDScript)** dengan **Jolt Physics 3D**.

---

## 🎮 Gambaran Game
- **Genre:** 3D Third-Person Vehicle Runner / Arcade Adventure
- **Target Platform:** Android (Google Play Store) & Web Demo
- **Resolusi:** Portrait 720 × 1280 (`canvas_items`, `expand`)
- **Gaya Visual:** *Polished Stylized Semi-Realistic 3D*
- **Kontrol:** 3 Lajur (Swipe Kiri/Kanan, Lompat/Swipe Atas, Slide/Swipe Bawah) & Keyboard (A, D, Space, S)

---

## 🛠️ Spesifikasi Teknis
- **Game Engine:** Godot 4.7.2 Stable
- **3D Physics Engine:** Jolt Physics 3D (bawaan resmi Godot)
- **Renderer:** Dual-strategy (Mobile renderer untuk Android, GL Compatibility untuk Web)
- **Geometri Lintasan:** Lebar total 13,5 meter (3 lajur @ 3,5 m + bahu jalan 2 × 1,5 m)

---

## 📁 Struktur Direktori Repository

```text
Bike/ (Root Proyek Godot 3D)
├── assets/                  # Model 3D, material, tekstur, audio, font
├── archive/
│   └── 2d_prototype/        # Arsip kode & scene eksperimen 2D terdahulu
├── docs/
│   └── ARCHITECTURE_V2.md   # Dokumen spesifikasi lengkap Arsitektur V2.0
├── reference/
│   └── Game 1.py            # Salinan referensi prototipe Pygame awal
├── resources/               # Data-driven resources (LevelData, VehicleData, dll)
├── scenes/
│   └── bootstrap_3d.tscn    # Scene baseline pengujian 3D (kamera & lintasan)
├── scripts/
│   ├── autoload/            # GameState, SaveManager, AudioManager
│   └── ui/                  # TouchController (Swipe & Tap)
├── translations/            # File lokalisasi multi-bahasa
├── ASSETS_CREDITS.md        # Catatan lisensi aset bebas hak cipta
├── project.godot            # Konfigurasi utama engine
└── README.md
```

---

## 🚀 Cara Menjalankan Proyek di Editor
1. Buka **Godot Engine 4.7.2**.
2. Pilih **Import** dan arahkan ke folder ini (`Bike/project.godot`).
3. Tekan **Play Project (F5)** untuk menjalankan `scenes/bootstrap_3d.tscn`.
4. Anda dapat menguji kalibrasi kamera dan framing lintasan 13,5 m di layar portrait menggunakan tombol:
   - `[Q / E]` : Atur ketinggian kamera ($Y$)
   - `[Panah Atas / Bawah]` : Atur jarak kamera ($Z$)
   - `[R / F]` : Atur kemiringan kamera (*pitch tilt*)
   - `[Z / C]` : Atur sudut pandang horizontal (HFOV)
   - `[Spasi]` : Reset kamera ke parameter default awal.

---

## 📖 Dokumentasi Lengkap
Lihat file [docs/ARCHITECTURE_V2.md](docs/ARCHITECTURE_V2.md) untuk perincian lengkap visi gameplay, sistem 100 kendaraan, 25 karakter, sistem 100 level, item box, dan kepatuhan Google Play Families Policy.

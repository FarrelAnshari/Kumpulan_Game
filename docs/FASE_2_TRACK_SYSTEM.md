# FASE 2 — MODULAR 3D TRACK SYSTEM, WORLD ENVIRONMENT FOUNDATION & THIRD-PERSON CAMERA

**Proyek:** Sepeda Petualang V2.0  
**Engine:** Godot 4.7.2 Stable  
**Bahasa:** GDScript  
**Branch:** `game-3d-fase-2`  

---

## 1. Ringkasan Fase 2

Fase 2 membangun sistem lintasan modular 3D, kamera third-person, dan fondasi lingkungan visual. Perubahan utama dari Fase 1:

- **Orientasi layar**: Portrait (720×1280) → **Landscape (1280×720)**
- **Main scene**: `bootstrap_3d.tscn` → **`scenes/gameplay/track_test.tscn`**
- **7 jenis segmen lintasan modular** yang dapat disambung tanpa celah
- **Chase camera** yang mengikuti target secara halus
- **Test rig** untuk pengujian lintasan sebelum kendaraan pemain (Fase 3)

---

## 2. Perubahan Orientasi

| Parameter | Fase 1 (Portrait) | Fase 2 (Landscape) |
|---|---|---|
| `viewport_width` | 720 | 1280 |
| `viewport_height` | 1280 | 720 |
| `window_width_override` | 405 | 1280 |
| `window_height_override` | 720 | 720 |
| `handheld/orientation` | 1 (portrait) | 0 (landscape) |

Stretch mode tetap `canvas_items` dengan aspect `expand`.

---

## 3. Dimensi Lintasan Standar

Semua segmen menggunakan dimensi lintasan yang konsisten:

| Komponen | Lebar (meter) |
|---|---|
| Lajur (× 3) | 3,5 m |
| Total aspal | 10,5 m |
| Bahu jalan (× 2) | 1,5 m |
| **Total lebar** | **13,5 m** |

### Posisi Lajur (Sumbu X)

| Lajur | Indeks | Posisi X |
|---|---|---|
| Kiri | 0 | -3,5 m |
| Tengah | 1 | 0,0 m |
| Kanan | 2 | +3,5 m |

### Konvensi Koordinat

- **Sumbu X**: Lebar lintasan (kiri ↔ kanan)
- **Sumbu Y**: Ketinggian (atas ↔ bawah)
- **Sumbu Z**: Arah maju kendaraan (**-Z = maju**, sesuai konvensi Godot)

---

## 4. Jenis Segmen Lintasan

### 4.1 TrackStraight (Lurus)

- Segmen dasar tanpa perubahan arah atau elevasi
- Panjang default: 20 meter (dapat diubah via `segment_length`)
- File: `scripts/gameplay/track_straight.gd`

### 4.2 TrackCurveLeft (Belok Kiri)

- Belok ke kiri menggunakan pendekatan busur (arc)
- Parameter: `curve_angle_deg` (default 30°), `curve_radius` (default 40m)
- Dibentuk dari 12 sub-segmen untuk kelengkungan halus
- File: `scripts/gameplay/track_curve_left.gd`

### 4.3 TrackCurveRight (Belok Kanan)

- Cerminan dari TrackCurveLeft pada sumbu X
- Parameter dan resolusi sama
- File: `scripts/gameplay/track_curve_right.gd`

### 4.4 TrackUphill (Tanjakan)

- Permukaan jalan miring naik secara bertahap
- Parameter: `elevation_gain` (default 3m)
- 8 sub-segmen pembentuk kemiringan
- File: `scripts/gameplay/track_uphill.gd`

### 4.5 TrackDownhill (Turunan)

- Kebalikan dari TrackUphill
- Parameter: `elevation_drop` (default 3m)
- File: `scripts/gameplay/track_downhill.gd`

### 4.6 TrackRamp (Ramp Lompat)

- Tanjakan pendek → datar di puncak → turun kembali
- Parameter: `ramp_height` (2,5m), `ramp_up_length` (8m), `ramp_flat_length` (4m), `ramp_down_length` (8m)
- Entry dan exit pada ketinggian yang sama
- File: `scripts/gameplay/track_ramp.gd`

### 4.7 TrackBridge (Jembatan)

- Jalur naik → bentangan datar terangkat → jalur turun
- Dilengkapi pilar penyangga dan pagar pengaman
- Parameter: `bridge_height` (4m), `bridge_span_length` (24m), `approach_length` (8m)
- File: `scripts/gameplay/track_bridge.gd`

---

## 5. Sistem Penyambungan Segmen

### TrackManager (`scripts/gameplay/track_manager.gd`)

TrackManager mengelola rantai segmen lintasan:

1. **Entry/Exit Points**: Setiap segmen memiliki titik masuk dan keluar dengan posisi dan arah (forward vector)
2. **Penyambungan otomatis**: Segmen baru diposisikan agar `entry_point`-nya tepat di `exit_point` segmen sebelumnya
3. **Rotasi otomatis**: Arah `entry_forward` segmen baru disejajarkan dengan `exit_forward` segmen sebelumnya
4. **Tanpa celah**: Penyambungan menggunakan transformasi global yang presisi

### Metode Utama

```gdscript
# Menambahkan segmen ke ujung rantai
track_manager.append_segment(segment)

# Membangun lintasan dari urutan data
track_manager.build_from_sequence([
    {"type": "straight", "length": 30.0},
    {"type": "curve_left", "angle": 30.0, "radius": 40.0},
    {"type": "uphill", "length": 20.0, "elevation": 3.0},
])

# Menghapus semua segmen
track_manager.clear_all_segments()
```

---

## 6. Chase Camera (`scripts/gameplay/chase_camera.gd`)

Kamera third-person dengan fitur:

| Parameter | Default | Keterangan |
|---|---|---|
| `follow_distance` | 10,0 m | Jarak di belakang target |
| `follow_height` | 5,0 m | Ketinggian di atas target |
| `look_ahead_offset` | 5,0 m | Jarak pandang ke depan |
| `position_smoothing` | 5,0 | Kecepatan interpolasi posisi |
| `rotation_smoothing` | 4,0 | Kecepatan interpolasi rotasi |
| `base_fov` | 65° | Field of view dasar |

Kamera mengikuti target (test rig atau kendaraan) secara halus menggunakan `lerp` untuk posisi dan `slerp` untuk rotasi.

---

## 7. Test Rig (`scripts/gameplay/track_test_rig.gd`)

Objek uji sederhana yang menggantikan kendaraan pemain pada Fase 2:

- Bergerak maju otomatis dengan kecepatan 12 m/s
- Mendukung perpindahan lajur (A/D atau swipe)
- Menampilkan visual placeholder kotak oranye
- Akan digantikan oleh controller kendaraan pada Fase 3

---

## 8. Scene Pengujian (`scenes/gameplay/track_test.tscn`)

Scene utama Fase 2 yang mendemonstrasikan:

- 13 segmen terhubung: lurus → belok kiri → lurus → tanjakan → lurus → belok kanan → lurus → ramp → lurus → turunan → lurus → jembatan → lurus
- Test rig bergerak maju otomatis
- Chase camera mengikuti test rig
- HUD diagnostik menampilkan info lintasan, kamera, posisi rig, dan orientasi viewport
- TouchController dari Fase 1 tetap aktif

---

## 9. TrackSequenceData (`scripts/resources/track_sequence_data.gd`)

Resource class (`.tres`) untuk menyimpan urutan segmen:

```gdscript
# Contoh penggunaan
var data: TrackSequenceData = TrackSequenceData.new()
data.sequence_name = "Level 1 - Kota"
data.segments = [
    {"type": "straight", "length": 30.0},
    {"type": "curve_left", "angle": 30.0, "radius": 40.0},
]
```

---

## 10. Cara Menambah Segmen Baru

1. Buat file `.gd` baru yang extends `TrackSegment`
2. Tambahkan tipe baru di `SegmentType` enum
3. Override `_calculate_connection_points()` untuk entry/exit
4. Override `_build_segment_geometry()` untuk tampilan visual
5. Override `_build_collision()` untuk collision
6. Daftarkan di `TrackManager._create_segment_from_data()`

---

## 11. Catatan Konflik Spesifikasi Jumlah World

| Dokumen | Jumlah World | Total Level |
|---|---|---|
| ARCHITECTURE_V2.md (Bagian 3) | 5 world | 100 level |
| Prompt Fase 2 (Bagian F) | 4 world | 100 level |

**Keputusan**: Mengikuti prompt Fase 2 (4 world × 25 level). Pembaruan arsitektur dilakukan pada fase selanjutnya setelah konfirmasi.

---

## 12. Struktur File Fase 2

```
scripts/
├── gameplay/
│   ├── track_segment.gd        # Base class segmen lintasan
│   ├── track_straight.gd       # Segmen lurus
│   ├── track_curve_left.gd     # Belok kiri
│   ├── track_curve_right.gd    # Belok kanan
│   ├── track_uphill.gd         # Tanjakan
│   ├── track_downhill.gd       # Turunan
│   ├── track_ramp.gd           # Ramp lompat
│   ├── track_bridge.gd         # Jembatan
│   ├── track_manager.gd        # Pengelola rantai segmen
│   ├── track_test_rig.gd       # Objek uji bergerak
│   └── chase_camera.gd         # Kamera third-person
├── resources/
│   └── track_sequence_data.gd  # Resource urutan segmen
scenes/
├── gameplay/
│   ├── track_test.tscn          # Scene pengujian Fase 2
│   └── track_test.gd            # Script scene pengujian
docs/
└── FASE_2_TRACK_SYSTEM.md       # Dokumentasi ini
```

---

## 13. Fase 1 yang Dipertahankan

- `scenes/bootstrap_3d.tscn` & `.gd` — tidak diubah, tersedia sebagai referensi
- `scripts/autoload/game_state.gd` — tidak diubah
- `scripts/autoload/save_manager.gd` — tidak diubah
- `scripts/autoload/audio_manager.gd` — tidak diubah
- `scripts/input/touch_controller.gd` — tidak diubah, digunakan di scene pengujian
- `archive/2d_prototype/` — tidak disentuh
- `reference/Game 1.py` — tidak disentuh

---

## 14. Langkah Berikutnya (Fase 3)

> **Belum dikerjakan — menunggu persetujuan.**

- Vehicle Controller 3D (CharacterBody3D atau RigidBody3D)
- Obstacle system
- Collision response (tabrakan, lompat, slide)
- Integrasi kendaraan dengan lintasan modular

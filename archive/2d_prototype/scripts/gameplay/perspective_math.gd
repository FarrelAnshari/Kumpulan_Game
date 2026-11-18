class_name PerspectiveMath
extends RefCounted

# PerspectiveMath: Sumber kebenaran tunggal untuk seluruh perhitungan
# perspektif semu (pseudo-3D) pada game Sepeda Petualang.
# Digunakan bersama oleh Jalan (Road), Dekorasi (Decoration), Pemain (Player),
# Rintangan (Obstacle), dan Koin (Collectible).

# Nilai default acuan resolusi dasar portrait 720 x 1280
const DEFAULT_CENTER_X: float = 360.0
const DEFAULT_HORIZON_Y: float = 460.0
const DEFAULT_GROUND_Y: float = 1280.0
const DEFAULT_FAR_WIDTH: float = 70.0
const DEFAULT_NEAR_WIDTH: float = 620.0
const DEFAULT_MIN_SCALE: float = 0.15
const DEFAULT_MAX_SCALE: float = 1.20
const DEFAULT_EXPONENT: float = 1.80


## Menghitung nilai kurva terpadu k(t) = t^p
## t bernilai [0.0 = horizon, 1.0 = dekat pemain]
static func curve(t: float, p: float = DEFAULT_EXPONENT) -> float:
	var clamped_t: float = clampf(t, 0.0, 1.0)
	return pow(clamped_t, p)


## Posisi vertikal y(t) = horizon_y + k(t) * (ground_y - horizon_y)
static func get_y(
	t: float,
	horizon_y: float = DEFAULT_HORIZON_Y,
	ground_y: float = DEFAULT_GROUND_Y,
	p: float = DEFAULT_EXPONENT
) -> float:
	return horizon_y + curve(t, p) * (ground_y - horizon_y)


## Lebar jalan pada kedalaman t
static func get_road_width(
	t: float,
	far_w: float = DEFAULT_FAR_WIDTH,
	near_w: float = DEFAULT_NEAR_WIDTH,
	p: float = DEFAULT_EXPONENT
) -> float:
	return far_w + curve(t, p) * (near_w - far_w)


## Posisi pusat lajur (-1 = Kiri, 0 = Tengah, 1 = Kanan)
## lane_x = center_x + lane_index * (road_width / 3)
static func get_lane_x(
	t: float,
	lane_index: float,
	center_x: float = DEFAULT_CENTER_X,
	far_w: float = DEFAULT_FAR_WIDTH,
	near_w: float = DEFAULT_NEAR_WIDTH,
	p: float = DEFAULT_EXPONENT
) -> float:
	var w: float = get_road_width(t, far_w, near_w, p)
	return center_x + lane_index * (w / 3.0)


## Posisi garis marka pembatas lajur (-1 = batas kiri/tengah, 1 = batas tengah/kanan)
## divider_x = center_x + divider_side * (road_width / 6)
static func get_divider_x(
	t: float,
	divider_side: int,
	center_x: float = DEFAULT_CENTER_X,
	far_w: float = DEFAULT_FAR_WIDTH,
	near_w: float = DEFAULT_NEAR_WIDTH,
	p: float = DEFAULT_EXPONENT
) -> float:
	var w: float = get_road_width(t, far_w, near_w, p)
	return center_x + float(divider_side) * (w / 6.0)


## Tepi kiri dan kanan jalan pada kedalaman t (Vector2.x = kiri, Vector2.y = kanan)
static func get_road_edges(
	t: float,
	center_x: float = DEFAULT_CENTER_X,
	far_w: float = DEFAULT_FAR_WIDTH,
	near_w: float = DEFAULT_NEAR_WIDTH,
	p: float = DEFAULT_EXPONENT
) -> Vector2:
	var half_w: float = get_road_width(t, far_w, near_w, p) * 0.5
	return Vector2(center_x - half_w, center_x + half_w)


## Skala objek pada kedalaman t
static func get_scale(
	t: float,
	min_s: float = DEFAULT_MIN_SCALE,
	max_s: float = DEFAULT_MAX_SCALE,
	p: float = DEFAULT_EXPONENT
) -> float:
	return min_s + curve(t, p) * (max_s - min_s)


## Posisi horizontal untuk dekorasi sisi jalan
## side = -1 (kiri jalan), side = 1 (kanan jalan)
## offset_distance adalah jarak tambahan dari tepi jalan pada t = 1.0
static func get_decoration_x(
	t: float,
	side: int,
	offset_distance: float = 40.0,
	center_x: float = DEFAULT_CENTER_X,
	far_w: float = DEFAULT_FAR_WIDTH,
	near_w: float = DEFAULT_NEAR_WIDTH,
	p: float = DEFAULT_EXPONENT
) -> float:
	var edges: Vector2 = get_road_edges(t, center_x, far_w, near_w, p)
	var scaled_offset: float = offset_distance * get_scale(t, DEFAULT_MIN_SCALE, DEFAULT_MAX_SCALE, p)

	if side < 0:
		return edges.x - scaled_offset
	else:
		return edges.y + scaled_offset

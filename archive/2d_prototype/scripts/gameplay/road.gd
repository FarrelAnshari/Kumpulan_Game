class_name Road
extends Node2D

# Road: Bertanggung jawab menggambar jalan aspal perspektif 3 lajur,
# garis batas jalan, dan marka jalan bergerak yang mulus.
# Semua geometri bersandar pada PerspectiveMath.

@export var road_speed: float = 280.0 # Kecepatan pergerakan marka (piksel/detik)
@export var marker_count: int = 10     # Jumlah potongan marka per garis lajur
@export var marker_ratio: float = 0.05 # Panjang relatif satu marka dalam nilai t

# Warna elemen jalan
const COLOR_ASPHALT: Color = Color(0.24, 0.22, 0.22)       # Aspal abu-abu gelap
const COLOR_SHOULDER: Color = Color(0.35, 0.32, 0.32)      # Bahu jalan
const COLOR_BORDER_LINE: Color = Color(0.95, 0.95, 0.95)   # Garis putih tepi
const COLOR_LANE_MARKER: Color = Color(1.0, 1.0, 1.0, 0.9) # Marka putih pembatas lajur

var road_offset: float = 0.0


func _process(delta: float) -> void:
	# Pergerakan marka menggunakan delta agar konsisten di semua FPS
	# Siklus offset berulang dari 0.0 sampai 1.0
	road_offset += (road_speed * delta) / 900.0
	road_offset = fposmod(road_offset, 1.0)
	queue_redraw()


func _draw() -> void:
	_draw_road_surface()
	_draw_road_borders()
	_draw_lane_markers(-1) # Pembatas lajur kiri-tengah
	_draw_lane_markers(1)  # Pembatas lajur tengah-kanan


## Menggambar permukaan aspal utama berbentuk trapesium perspektif
func _draw_road_surface() -> void:
	var top_edges: Vector2 = PerspectiveMath.get_road_edges(0.0)
	var bottom_edges: Vector2 = PerspectiveMath.get_road_edges(1.0)
	var top_y: float = PerspectiveMath.get_y(0.0)
	var bottom_y: float = PerspectiveMath.get_y(1.0)

	# 1. Bahu jalan luar (sedikit lebih lebar dari aspal)
	var shoulder_margin: float = 24.0
	var shoulder_poly: PackedVector2Array = PackedVector2Array([
		Vector2(top_edges.x - 4.0, top_y),
		Vector2(top_edges.y + 4.0, top_y),
		Vector2(bottom_edges.y + shoulder_margin, bottom_y),
		Vector2(bottom_edges.x - shoulder_margin, bottom_y)
	])
	draw_polygon(shoulder_poly, PackedColorArray([COLOR_SHOULDER]))

	# 2. Aspal utama 3 lajur
	var asphalt_poly: PackedVector2Array = PackedVector2Array([
		Vector2(top_edges.x, top_y),
		Vector2(top_edges.y, top_y),
		Vector2(bottom_edges.y, bottom_y),
		Vector2(bottom_edges.x, bottom_y)
	])
	draw_polygon(asphalt_poly, PackedColorArray([COLOR_ASPHALT]))


## Menggambar garis tepi putih di sisi kiri dan kanan jalan
func _draw_road_borders() -> void:
	var top_edges: Vector2 = PerspectiveMath.get_road_edges(0.0)
	var bottom_edges: Vector2 = PerspectiveMath.get_road_edges(1.0)
	var top_y: float = PerspectiveMath.get_y(0.0)
	var bottom_y: float = PerspectiveMath.get_y(1.0)

	# Garis tepi kiri
	draw_line(
		Vector2(top_edges.x, top_y),
		Vector2(bottom_edges.x, bottom_y),
		COLOR_BORDER_LINE,
		6.0,
		true
	)

	# Garis tepi kanan
	draw_line(
		Vector2(top_edges.y, top_y),
		Vector2(bottom_edges.y, bottom_y),
		COLOR_BORDER_LINE,
		6.0,
		true
	)


## Menggambar marka garis putus-putus untuk satu pembatas lajur
## divider_side = -1 (antara lajur kiri & tengah), 1 (antara lajur tengah & kanan)
func _draw_lane_markers(divider_side: int) -> void:
	for i in range(marker_count):
		# Posisi awal marka dengan pembagian jarak merata + offset gerak
		var t_start: float = fposmod((float(i) / float(marker_count)) + road_offset, 1.0)
		var t_end: float = t_start + marker_ratio

		if t_end <= 1.0:
			# Segmen marka normal
			_draw_single_marker_segment(divider_side, t_start, t_end)
		else:
			# Segmen marka yang melintasi ujung bawah -> tersambung halus ke horizon
			_draw_single_marker_segment(divider_side, t_start, 1.0)
			var wrapped_end: float = t_end - 1.0
			if wrapped_end > 0.001:
				_draw_single_marker_segment(divider_side, 0.0, wrapped_end)


## Menggambar satu ruas marka berdasarkan rentang kedalaman t1 ke t2
func _draw_single_marker_segment(divider_side: int, t1: float, t2: float) -> void:
	# Hindari menggambar tepat di horizon jika terlalu tipis
	if t2 <= 0.02:
		return

	var y1: float = PerspectiveMath.get_y(t1)
	var y2: float = PerspectiveMath.get_y(t2)
	var x1: float = PerspectiveMath.get_divider_x(t1, divider_side)
	var x2: float = PerspectiveMath.get_divider_x(t2, divider_side)

	# Ketebalan marka membesar seiring mendekati pemain (2px di horizon s/d 9px di bawah)
	var line_width: float = maxf(2.0, PerspectiveMath.get_scale(t1) * 8.5)

	draw_line(
		Vector2(x1, y1),
		Vector2(x2, y2),
		COLOR_LANE_MARKER,
		line_width,
		true
	)

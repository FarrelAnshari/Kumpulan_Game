extends Node2D

# Background: Mengatur tampilan latar belakang sunset yang hangat dan indah.
# Meneruskan nuansa visual dari prototipe BIKE RUSH, namun dibangun
# secara statis (tanpa redraw per frame) agar hemat baterai dan CPU HP.

@export var horizon_y: float = PerspectiveMath.DEFAULT_HORIZON_Y

# Warna palet sunset khas BIKE RUSH (diperhalus agar ramah anak)
const COLOR_SKY_TOP: Color = Color(0.32, 0.16, 0.42)       # Ungu senja
const COLOR_SKY_MID_HIGH: Color = Color(0.78, 0.28, 0.42)  # Magenta hangat
const COLOR_SKY_MID_LOW: Color = Color(0.98, 0.54, 0.22)   # Oranye cerah
const COLOR_SKY_HORIZON: Color = Color(1.00, 0.84, 0.48)   # Kuning keemasan
const COLOR_SUN: Color = Color(1.00, 0.92, 0.55)           # Matahari bulat lembut
const COLOR_SUN_GLOW: Color = Color(1.00, 0.70, 0.30, 0.35)# Pendaran cahaya matahari
const COLOR_MOUNTAINS_FAR: Color = Color(0.42, 0.22, 0.38) # Siluet gunung jauh
const COLOR_MOUNTAINS_NEAR: Color = Color(0.30, 0.15, 0.28)# Siluet gunung dekat
const COLOR_TERRAIN: Color = Color(0.88, 0.60, 0.38)       # Tanah gurun / padang hangat


func _ready() -> void:
	_build_sky()
	_build_sun()
	_build_mountains()
	_build_ground()


## Membuat gradien langit menggunakan TextureRect statis
func _build_sky() -> void:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 0.75, 1.0])
	gradient.colors = PackedColorArray([
		COLOR_SKY_TOP,
		COLOR_SKY_MID_HIGH,
		COLOR_SKY_MID_LOW,
		COLOR_SKY_HORIZON
	])

	var grad_tex: GradientTexture2D = GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.width = 64
	grad_tex.height = 256
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)

	var sky_rect: TextureRect = TextureRect.new()
	sky_rect.texture = grad_tex
	sky_rect.position = Vector2(0, 0)
	sky_rect.size = Vector2(720, horizon_y)
	sky_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sky_rect)


## Membuat matahari terbenam tepat di atas horizon
func _build_sun() -> void:
	var sun_center: Vector2 = Vector2(360.0, horizon_y - 45.0)

	# Lingkaran pendaran cahaya (glow)
	var glow: Polygon2D = Polygon2D.new()
	glow.color = COLOR_SUN_GLOW
	glow.polygon = _generate_circle_points(sun_center, 95.0, 32)
	add_child(glow)

	# Lingkaran inti matahari
	var sun: Polygon2D = Polygon2D.new()
	sun.color = COLOR_SUN
	sun.polygon = _generate_circle_points(sun_center, 65.0, 32)
	add_child(sun)


## Membuat dua lapis siluet pegunungan senja
func _build_mountains() -> void:
	# Lapis 1: Pegunungan jauh
	var mountains_far: Polygon2D = Polygon2D.new()
	mountains_far.color = COLOR_MOUNTAINS_FAR
	var far_points: PackedVector2Array = PackedVector2Array([
		Vector2(0, horizon_y),
		Vector2(0, horizon_y - 70),
		Vector2(110, horizon_y - 130),
		Vector2(220, horizon_y - 75),
		Vector2(350, horizon_y - 145),
		Vector2(480, horizon_y - 80),
		Vector2(600, horizon_y - 135),
		Vector2(720, horizon_y - 65),
		Vector2(720, horizon_y)
	])
	mountains_far.polygon = far_points
	add_child(mountains_far)

	# Lapis 2: Pegunungan dekat (lebih gelap dan kontras)
	var mountains_near: Polygon2D = Polygon2D.new()
	mountains_near.color = COLOR_MOUNTAINS_NEAR
	var near_points: PackedVector2Array = PackedVector2Array([
		Vector2(0, horizon_y),
		Vector2(0, horizon_y - 40),
		Vector2(80, horizon_y - 85),
		Vector2(180, horizon_y - 35),
		Vector2(280, horizon_y - 95),
		Vector2(420, horizon_y - 30),
		Vector2(540, horizon_y - 85),
		Vector2(660, horizon_y - 40),
		Vector2(720, horizon_y - 50),
		Vector2(720, horizon_y)
	])
	mountains_near.polygon = near_points
	add_child(mountains_near)


## Membuat hamparan tanah di bawah horizon
func _build_ground() -> void:
	var ground: ColorRect = ColorRect.new()
	ground.color = COLOR_TERRAIN
	ground.position = Vector2(0, horizon_y)
	ground.size = Vector2(720, 1280.0 - horizon_y)
	add_child(ground)


## Helper untuk membuat koordinat lingkaran
func _generate_circle_points(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var angle: float = (float(i) / float(segments)) * TAU
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

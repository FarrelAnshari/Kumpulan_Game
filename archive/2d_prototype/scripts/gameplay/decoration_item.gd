class_name DecorationItem
extends Node2D

# DecorationItem: Satu unit dekorasi procedural sisi jalan.
# Digunakan berulang kali oleh DecorationManager (Object Pooling).
# Menampilkan 4 variasi visual: Kaktus, Batu, Semak, dan Pohon.

enum Type {
	CACTUS = 0,
	ROCK = 1,
	BUSH = 2,
	TREE = 3
}

var deco_type: Type = Type.CACTUS:
	set(val):
		deco_type = val
		queue_redraw()

var t: float = 0.0          # Posisi kedalaman (0.0 = horizon, 1.0 = depan)
var side: int = -1          # -1 = Kiri jalan, 1 = Kanan jalan
var lateral_offset: float = 40.0 # Jarak di luar aspal pada t=1.0


func _draw() -> void:
	match deco_type:
		Type.CACTUS:
			_draw_cactus()
		Type.ROCK:
			_draw_rock()
		Type.BUSH:
			_draw_bush()
		Type.TREE:
			_draw_tree()


## 1. Kaktus ceria gurun/sunset (variasi dari prototype lama)
func _draw_cactus() -> void:
	var color_main: Color = Color(0.22, 0.60, 0.32)
	var color_dark: Color = Color(0.16, 0.48, 0.25)

	# Batang utama
	draw_rect(Rect2(-10, -50, 20, 50), color_main)
	draw_circle(Vector2(0, -50), 10, color_main)

	# Cabang kiri
	draw_rect(Rect2(-24, -34, 16, 8), color_dark)
	draw_rect(Rect2(-24, -44, 8, 18), color_dark)
	draw_circle(Vector2(-20, -44), 4, color_dark)

	# Cabang kanan
	draw_rect(Rect2(8, -26, 16, 8), color_dark)
	draw_rect(Rect2(16, -36, 8, 18), color_dark)
	draw_circle(Vector2(20, -36), 4, color_dark)


## 2. Batu pinggir jalan bulat ramah anak
func _draw_rock() -> void:
	var color_rock: Color = Color(0.55, 0.48, 0.42)
	var color_light: Color = Color(0.70, 0.62, 0.54)

	# Poligon batu membulat
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(-24, 0),
		Vector2(-20, -18),
		Vector2(-6, -28),
		Vector2(14, -26),
		Vector2(26, -12),
		Vector2(22, 0)
	])
	draw_polygon(points, PackedColorArray([color_rock]))

	# Sorotan cahaya di bagian atas batu
	var highlight: PackedVector2Array = PackedVector2Array([
		Vector2(-14, -16),
		Vector2(-4, -24),
		Vector2(10, -22),
		Vector2(6, -14)
	])
	draw_polygon(highlight, PackedColorArray([color_light]))


## 3. Semak hijau rimbun
func _draw_bush() -> void:
	var color_base: Color = Color(0.28, 0.58, 0.22)
	var color_top: Color = Color(0.38, 0.72, 0.28)

	draw_circle(Vector2(-14, -12), 16, color_base)
	draw_circle(Vector2(14, -12), 16, color_base)
	draw_circle(Vector2(0, -22), 20, color_top)


## 4. Pohon sederhana
func _draw_tree() -> void:
	var color_trunk: Color = Color(0.48, 0.32, 0.20)
	var color_leaf_dark: Color = Color(0.18, 0.46, 0.24)
	var color_leaf_light: Color = Color(0.25, 0.60, 0.30)

	# Batang pohon
	draw_rect(Rect2(-7, -24, 14, 24), color_trunk)

	# Tajuk daun (lingkaran bertingkat)
	draw_circle(Vector2(0, -38), 24, color_leaf_dark)
	draw_circle(Vector2(0, -56), 18, color_leaf_light)

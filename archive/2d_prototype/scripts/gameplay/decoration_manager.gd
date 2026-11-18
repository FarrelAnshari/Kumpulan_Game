class_name DecorationManager
extends Node2D

# DecorationManager: Mengelola kumpulan dekorasi sisi jalan (Object Pooling).
# Menjamin dekorasi bergerak mulus dari horizon ke bawah, membesar secara proporsional,
# dan berada di luar aspal jalan dengan konsistensi PerspectiveMath.

@export var road_speed: float = 280.0 # Sinkron dengan kecepatan Road
@export var items_per_side: int = 6   # 6 di kiri, 6 di kanan = 12 total objek hemat CPU

var decoration_pool: Array[DecorationItem] = []


func _ready() -> void:
	_initialize_pool()


## Menginisialisasi pool dekorasi dengan posisi kedalaman t yang terdistribusi merata
func _initialize_pool() -> void:
	var total_items: int = items_per_side * 2
	var stride: float = 1.0 / float(items_per_side)

	for side in [-1, 1]:
		for i in range(items_per_side):
			var item: DecorationItem = DecorationItem.new()
			item.side = side
			# Distribusi awal bertahap di sepanjang jalan
			item.t = (float(i) * stride) + randf_range(0.01, 0.04)
			item.lateral_offset = randf_range(25.0, 55.0)
			item.deco_type = randi() % 4 as DecorationItem.Type

			add_child(item)
			decoration_pool.append(item)

	_update_item_transforms()


func _process(delta: float) -> void:
	# Menggerakkan objek ke arah pemain dengan kecepatan yang sama persis dengan marka jalan
	var delta_t: float = (road_speed * delta) / 900.0

	for item: DecorationItem in decoration_pool:
		item.t += delta_t

		# Jika sudah melewati bawah layar, gunakan kembali (recycle) ke horizon
		if item.t >= 1.06:
			item.t -= 1.0
			# Acak kembali jenis objek dan jarak tepinya agar pemandangan bervariasi
			item.deco_type = randi() % 4 as DecorationItem.Type
			item.lateral_offset = randf_range(25.0, 55.0)

	_update_item_transforms()


## Memperbarui koordinat, skala, dan kedalaman z-index seluruh dekorasi
func _update_item_transforms() -> void:
	for item: DecorationItem in decoration_pool:
		# Jangan tampilkan jika tepat berada di atas horizon
		if item.t < 0.02:
			item.visible = false
			continue

		item.visible = true
		var pos_x: float = PerspectiveMath.get_decoration_x(item.t, item.side, item.lateral_offset)
		var pos_y: float = PerspectiveMath.get_y(item.t)
		var s: float = PerspectiveMath.get_scale(item.t)

		item.position = Vector2(pos_x, pos_y)
		item.scale = Vector2(s, s)
		# Objek yang lebih dekat (t besar) digambar di atas objek yang lebih jauh
		item.z_index = int(item.t * 50.0)

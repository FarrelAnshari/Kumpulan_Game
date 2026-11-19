class_name TrackSegment
extends Node3D

# TrackSegment: Kelas dasar untuk semua jenis segmen lintasan modular.
# Setiap segmen memiliki titik masuk (entry) dan titik keluar (exit),
# dimensi lebar standar 13,5m (3 lajur @ 3,5m + 2 bahu @ 1,5m),
# serta permukaan collision untuk kendaraan.

## Jenis segmen lintasan yang tersedia
enum SegmentType {
	STRAIGHT,       # Lurus
	CURVE_LEFT,     # Belok kiri
	CURVE_RIGHT,    # Belok kanan
	UPHILL,         # Tanjakan
	DOWNHILL,       # Turunan
	RAMP,           # Ramp lompat
	BRIDGE,         # Jembatan
}

# --- Konstanta dimensi lintasan standar (meter) ---
const LANE_WIDTH: float = 3.5          # Lebar setiap lajur
const LANE_COUNT: int = 3              # Jumlah lajur
const SHOULDER_WIDTH: float = 1.5      # Lebar bahu jalan per sisi
const ROAD_WIDTH: float = 10.5         # Lebar aspal (3 × 3,5)
const TOTAL_WIDTH: float = 13.5        # Total lebar termasuk bahu (10,5 + 2 × 1,5)
const DEFAULT_LENGTH: float = 20.0     # Panjang default segmen lurus
const ROAD_THICKNESS: float = 0.18     # Ketebalan visual permukaan jalan
const LINE_WIDTH: float = 0.18         # Lebar marka jalan
const LINE_HEIGHT_OFFSET: float = 0.01 # Ketinggian marka di atas aspal

# --- Posisi lajur (sumbu X, tengah jalan = 0) ---
const LANE_POSITIONS: Array[float] = [-3.5, 0.0, 3.5]

# --- Properti yang bisa diatur di Inspector ---
@export var segment_type: SegmentType = SegmentType.STRAIGHT
@export var segment_length: float = DEFAULT_LENGTH

## Titik masuk dan keluar segmen (koordinat lokal)
## Entry = ujung depan segmen (arah datangnya kendaraan)
## Exit = ujung belakang segmen (arah kendaraan keluar)
var entry_point: Vector3 = Vector3.ZERO
var entry_forward: Vector3 = Vector3.FORWARD  # -Z dalam koordinat Godot
var exit_point: Vector3 = Vector3.ZERO
var exit_forward: Vector3 = Vector3.FORWARD

# Node referensi internal
var road_mesh: MeshInstance3D
var collision_body: StaticBody3D
var collision_shape: CollisionShape3D


func _ready() -> void:
	_calculate_connection_points()
	_build_segment_geometry()
	_build_collision()


## Menghitung titik masuk dan keluar berdasarkan jenis segmen.
## Override di subclass untuk segmen non-lurus.
func _calculate_connection_points() -> void:
	# Default: segmen lurus sepanjang sumbu -Z
	entry_point = Vector3(0.0, 0.0, 0.0)
	entry_forward = Vector3(0.0, 0.0, -1.0)
	exit_point = Vector3(0.0, 0.0, -segment_length)
	exit_forward = Vector3(0.0, 0.0, -1.0)


## Membangun geometri visual (mesh) segmen lintasan.
## Override di subclass untuk tampilan khusus.
func _build_segment_geometry() -> void:
	_build_road_surface()
	_build_shoulders()
	_build_lane_markings()


## Membuat permukaan aspal utama
func _build_road_surface() -> void:
	road_mesh = MeshInstance3D.new()
	road_mesh.name = "RoadSurface"

	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(ROAD_WIDTH, ROAD_THICKNESS, segment_length)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.22, 0.25, 1.0)
	mat.roughness = 0.7
	box.material = mat

	road_mesh.mesh = box
	# Posisikan di tengah segmen
	road_mesh.position = Vector3(0.0, 0.0, -segment_length * 0.5)
	add_child(road_mesh)


## Membuat bahu jalan kiri dan kanan
func _build_shoulders() -> void:
	var shoulder_mat: StandardMaterial3D = StandardMaterial3D.new()
	shoulder_mat.albedo_color = Color(0.45, 0.38, 0.35, 1.0)
	shoulder_mat.roughness = 0.8

	for side in [-1.0, 1.0]:
		var shoulder: MeshInstance3D = MeshInstance3D.new()
		shoulder.name = "Shoulder_" + ("Left" if side < 0 else "Right")

		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(SHOULDER_WIDTH, ROAD_THICKNESS * 0.85, segment_length)
		box.material = shoulder_mat
		shoulder.mesh = box

		# Posisi: di luar tepi aspal
		var x_offset: float = side * (ROAD_WIDTH * 0.5 + SHOULDER_WIDTH * 0.5)
		shoulder.position = Vector3(x_offset, 0.0, -segment_length * 0.5)
		add_child(shoulder)


## Membuat garis marka lajur (garis pembatas & garis pembagi lajur)
func _build_lane_markings() -> void:
	var line_mat: StandardMaterial3D = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.95, 0.95, 0.95, 1.0)
	line_mat.roughness = 0.4

	# Garis tepi kiri dan kanan
	var border_positions: Array[float] = [-ROAD_WIDTH * 0.5, ROAD_WIDTH * 0.5]
	for i in range(border_positions.size()):
		var border: MeshInstance3D = MeshInstance3D.new()
		border.name = "BorderLine_" + str(i)
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(LINE_WIDTH, ROAD_THICKNESS + LINE_HEIGHT_OFFSET, segment_length)
		box.material = line_mat
		border.mesh = box
		border.position = Vector3(border_positions[i], LINE_HEIGHT_OFFSET, -segment_length * 0.5)
		add_child(border)

	# Garis pembagi antar lajur (2 garis antara 3 lajur)
	var divider_positions: Array[float] = [-LANE_WIDTH * 0.5, LANE_WIDTH * 0.5]
	# Koreksi: pembagi ada di x = -1.75 dan x = +1.75
	divider_positions = [-LANE_WIDTH, LANE_WIDTH]
	# Sebenarnya: lajur di -3.5, 0, +3.5 → pembagi di -1.75 dan +1.75
	divider_positions = [-(LANE_WIDTH * 0.5), (LANE_WIDTH * 0.5)]
	for i in range(divider_positions.size()):
		var divider: MeshInstance3D = MeshInstance3D.new()
		divider.name = "LaneDivider_" + str(i)
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(LINE_WIDTH, ROAD_THICKNESS + LINE_HEIGHT_OFFSET, segment_length)
		box.material = line_mat
		divider.mesh = box
		divider.position = Vector3(divider_positions[i], LINE_HEIGHT_OFFSET, -segment_length * 0.5)
		add_child(divider)


## Membuat collision agar kendaraan bisa berdiri di atas jalan
func _build_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "RoadCollision"

	collision_shape = CollisionShape3D.new()
	collision_shape.name = "RoadShape"

	var shape: BoxShape3D = BoxShape3D.new()
	# Collision mencakup seluruh lebar termasuk bahu
	shape.size = Vector3(TOTAL_WIDTH, ROAD_THICKNESS, segment_length)
	collision_shape.shape = shape

	collision_body.add_child(collision_shape)
	collision_body.position = Vector3(0.0, 0.0, -segment_length * 0.5)
	add_child(collision_body)


## Menghitung posisi dunia (global) sumbu X untuk lajur tertentu.
## lane_index: 0 = kiri, 1 = tengah, 2 = kanan.
func get_lane_world_position(lane_index: int) -> Vector3:
	var local_x: float = LANE_POSITIONS[clampi(lane_index, 0, LANE_COUNT - 1)]
	return to_global(Vector3(local_x, ROAD_THICKNESS * 0.5, 0.0))


## Mendapatkan titik masuk dalam koordinat global
func get_global_entry_point() -> Vector3:
	return to_global(entry_point)


## Mendapatkan arah masuk dalam koordinat global
func get_global_entry_forward() -> Vector3:
	return global_basis * entry_forward


## Mendapatkan titik keluar dalam koordinat global
func get_global_exit_point() -> Vector3:
	return to_global(exit_point)


## Mendapatkan arah keluar dalam koordinat global
func get_global_exit_forward() -> Vector3:
	return global_basis * exit_forward

class_name TrackTestRig
extends Node3D

# TrackTestRig: Objek uji sederhana yang bergerak maju otomatis di lintasan.
# Mendukung perpindahan lajur menggunakan input kiri/kanan (A/D atau swipe).
# Digunakan untuk menguji TrackManager dan ChaseCamera sebelum Fase 3.

## Kecepatan maju otomatis (meter per detik)
@export var move_speed: float = 12.0
## Kecepatan perpindahan lajur (meter per detik)
@export var lane_change_speed: float = 8.0

# Posisi lajur saat ini: 0 = kiri, 1 = tengah, 2 = kanan
var current_lane: int = 1
var target_x: float = 0.0
var total_distance: float = 0.0  # Total jarak yang sudah ditempuh

# Visual placeholder kendaraan
var vehicle_mesh: MeshInstance3D


func _ready() -> void:
	_build_visual()
	target_x = TrackSegment.LANE_POSITIONS[current_lane]


func _process(delta: float) -> void:
	_handle_lane_input()
	_move_forward(delta)
	_update_lane_position(delta)


## Membangun visual placeholder kendaraan (kotak oranye)
func _build_visual() -> void:
	vehicle_mesh = MeshInstance3D.new()
	vehicle_mesh.name = "TestVehicle"

	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.8, 1.1, 1.8)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.45, 0.15, 1.0)
	mat.metallic = 0.4
	mat.roughness = 0.3
	box.material = mat

	vehicle_mesh.mesh = box
	vehicle_mesh.position = Vector3(0.0, 0.6, 0.0)  # Angkat di atas permukaan jalan
	add_child(vehicle_mesh)


## Mendeteksi input perpindahan lajur
func _handle_lane_input() -> void:
	if Input.is_action_just_pressed("move_left"):
		change_lane(-1)
	elif Input.is_action_just_pressed("move_right"):
		change_lane(1)


## Pindah lajur ke kiri (-1) atau kanan (+1)
func change_lane(direction: int) -> void:
	current_lane = clampi(current_lane + direction, 0, TrackSegment.LANE_COUNT - 1)
	target_x = TrackSegment.LANE_POSITIONS[current_lane]


## Bergerak maju secara otomatis (sumbu -Z)
func _move_forward(delta: float) -> void:
	var forward: Vector3 = -global_basis.z.normalized()
	global_position += forward * move_speed * delta
	total_distance += move_speed * delta


## Interpolasi perpindahan lajur secara halus
func _update_lane_position(delta: float) -> void:
	var current_local_x: float = position.x
	position.x = lerpf(current_local_x, target_x, lane_change_speed * delta)


## Mendapatkan nama lajur saat ini (untuk debugging)
func get_lane_name() -> String:
	match current_lane:
		0: return "Kiri"
		1: return "Tengah"
		2: return "Kanan"
		_: return "?"

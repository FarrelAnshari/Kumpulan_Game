class_name TrackTestRig
extends Node3D

# TrackTestRig: Objek uji pergerakan yang mengikuti lintasan modular (Path Following).
# Bergerak maju berdasarkan jarak kumulatif di sepanjang rangkaian segmen TrackManager,
# menyesuaikan posisi 3D, orientasi hadap (tangent), kemiringan lereng (pitch),
# dan perpindahan lajur lokal (lane offset) secara presisi.

## Referensi ke TrackManager pengelola lintasan
@export var track_manager: TrackManager

## Kecepatan maju otomatis di sepanjang lintasan (meter per detik)
@export var move_speed: float = 12.0
## Kecepatan perpindahan lajur (meter per detik)
@export var lane_change_speed: float = 8.0
## Apakah mengulang lintasan dari awal setelah mencapai ujung
@export var loop_track: bool = true

# Posisi lajur saat ini: 0 = kiri (-3.5m), 1 = tengah (0.0m), 2 = kanan (+3.5m)
var current_lane: int = 1
var current_lane_offset: float = 0.0
var target_lane_offset: float = 0.0
var total_distance: float = 0.0  # Total jarak yang sudah ditempuh sepanjang lintasan

# Visual placeholder kendaraan
var vehicle_mesh: MeshInstance3D


func _ready() -> void:
	_build_visual()
	if track_manager == null:
		track_manager = get_node_or_null("../TrackManager")
	current_lane_offset = TrackSegment.LANE_POSITIONS[current_lane]
	target_lane_offset = current_lane_offset
	_update_transform_on_track(0.0)


func _process(delta: float) -> void:
	_handle_lane_input()
	_update_lane_offset(delta)
	_advance_along_track(delta)


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
	# Posisi visual: dinaikkan 0.55m agar dasar kotak pas menempel di atas permukaan aspal
	vehicle_mesh.position = Vector3(0.0, 0.55, 0.0)
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
	target_lane_offset = TrackSegment.LANE_POSITIONS[current_lane]


## Interpolasi perpindahan lajur secara halus dalam koordinat lokal lintasan
func _update_lane_offset(delta: float) -> void:
	current_lane_offset = lerpf(current_lane_offset, target_lane_offset, lane_change_speed * delta)


## Memajukan posisi di sepanjang lintasan berdasarkan kecepatan dan delta waktu
func _advance_along_track(delta: float) -> void:
	if track_manager == null or track_manager.get_segment_count() == 0:
		return

	total_distance += move_speed * delta

	# Loop lintasan jika diaktifkan dan sudah melewati ujung
	var total_len: float = track_manager.get_total_length()
	if loop_track and total_len > 0.0 and total_distance >= total_len:
		total_distance = fmod(total_distance, total_len)

	_update_transform_on_track(delta)


## Mengambil Transform3D dari TrackManager dan memperbarui transform dunia test rig
func _update_transform_on_track(_delta: float) -> void:
	if track_manager == null:
		return

	var track_tf: Transform3D = track_manager.get_transform_at_distance(total_distance, current_lane_offset)
	global_transform = track_tf


## Mendapatkan informasi segmen tempat test rig berada saat ini
func get_current_segment_info() -> Dictionary:
	if track_manager:
		return track_manager.get_segment_info_at_distance(total_distance)
	return {"segment": null, "index": -1, "local_dist": 0.0, "segment_length": 0.0}


## Mendapatkan nama lajur saat ini (untuk debugging)
func get_lane_name() -> String:
	match current_lane:
		0: return "Kiri (-3.5m)"
		1: return "Tengah (0.0m)"
		2: return "Kanan (+3.5m)"
		_: return "?"

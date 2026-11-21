class_name PlayerController
extends CharacterBody3D

## PlayerController: Controller utama pemain untuk Sepeda Petualang.
## Bertanggung jawab atas pengelolaan unit gameplay (pemain + kendaraan),
## pergerakan otomatis (Auto-Forward) di sepanjang lintasan modular 3D (TrackManager),
## pergerakan lateral mulus (Smooth Lateral Movement) dengan kemiringan visual (leaning),
## lompat (Jump) track-relative dengan ketinggian yang memuaskan (1.6 - 1.8m),
## serta meluncur (Slide) dengan aksi Low Side-Skid bergaya adventure runner.

const MotorcycleBasicScript = preload("res://scripts/vehicles/motorcycle_basic.gd")
const PoncoRiderScript = preload("res://scripts/characters/ponco_rider.gd")

@export_group("Track & Forward Movement")
## Referensi ke TrackManager pengelola lintasan
@export var track_manager: TrackManager
## Kecepatan maju otomatis di sepanjang lintasan (meter per detik)
@export var forward_speed: float = 14.0
## Apakah pergerakan maju otomatis aktif
@export var is_auto_forward: bool = true

@export_group("Lateral Movement")
## Kecepatan maksimum pergerakan lateral (meter per detik)
@export var max_lateral_speed: float = 7.5
## Akselerasi lateral saat kemudi digerakkan (meter per detik kuadrat)
@export var lateral_acceleration: float = 24.0
## Deselerasi / redaman saat kemudi dilepas (meter per detik kuadrat)
@export var lateral_damping: float = 14.0
## Batas maksimum offset lateral dari garis tengah aspal (meter).
## Lebar aspal = 10.5m (setengah lebar 5.25m). Batas 4.8m menyisakan margin aman 0.45m dari tepi aspal.
@export var max_lateral_offset: float = 4.8
## Sudut kemiringan visual maksimum motor saat berbelok (derajat)
@export var max_lean_angle_deg: float = 14.0
## Kecepatan interpolasi kemiringan visual motor
@export var lean_smoothing: float = 9.0
## Kekuatan impuls lateral yang diberikan saat menerima gestur swipe layar
@export var swipe_impulse_strength: float = 5.5

@export_group("Jump")
## Kecepatan awal ke atas saat lompat (meter per detik) -> 7.8 m/s menghasilkan apex ~1.69m
@export var jump_initial_velocity: float = 7.8
## Gravitasi yang menarik kembali ke bawah saat di udara (meter per detik kuadrat)
@export var jump_gravity: float = 18.0

@export_group("Slide")
## Durasi meluncur (detik) — setelah selesai, postur kembali normal
@export var slide_duration: float = 0.85
## Kecepatan pemulihan postur dari posisi slide ke normal (satuan per detik)
@export var slide_recovery_speed: float = 6.0

@export_group("Player Components")
@export var default_rider_scene: PackedScene = preload("res://scenes/characters/ponco_rider.tscn")

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var vehicle_mount: Node3D = $VehicleMount

# --- State Machine Pergerakan ---
enum MoveState { NORMAL, JUMPING, SLIDING }
var move_state: MoveState = MoveState.NORMAL

# --- State Lompat (Jump) ---
## Ketinggian lompatan saat ini relatif terhadap permukaan lintasan (meter)
var jump_height: float = 0.0
## Kecepatan vertikal lompatan saat ini (positif = naik, negatif = turun)
var jump_vertical_velocity: float = 0.0
## Efek kompresi suspensi sesaat saat mendarat (meter)
var landing_squash: float = 0.0

# --- State Meluncur (Slide) ---
## Waktu tersisa untuk animasi meluncur (detik)
var slide_timer: float = 0.0
## Rasio postur slide saat ini (0.0 = normal, 1.0 = posisi slide penuh)
var slide_posture_t: float = 0.0

# --- Dimensi Collider Asli (disimpan saat _ready) ---
var _original_capsule_height: float = 1.35
var _original_capsule_offset_y: float = 0.675

# --- State Pergerakan Lintasan ---
## Total jarak tempuh kumulatif di sepanjang lintasan (meter)
var total_distance: float = 0.0
## Posisi offset lateral relatif terhadap garis tengah lintasan (meter)
## Negatif = ke kiri, Positif = ke kanan, 0.0 = tengah
var lateral_offset: float = 0.0
## Kecepatan lateral saat ini (meter per detik)
var lateral_velocity: float = 0.0
## Sudut kemiringan visual motor saat ini (radian)
var current_lean_angle: float = 0.0
## Apakah pemain telah mencapai ujung akhir lintasan
var is_track_completed: bool = false
## Sudut akumulasi rotasi roda (radian)
var wheel_rotation_angle: float = 0.0

# Referensi modular ke kendaraan dan pengendara aktif
var motorcycle: Node3D
var rider: Node3D


func _ready() -> void:
	_resolve_child_components()
	_ensure_rider_mounted()
	# Simpan dimensi collider asli sebelum ada modifikasi
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var cap: CapsuleShape3D = collision_shape.shape
		_original_capsule_height = cap.height
		_original_capsule_offset_y = collision_shape.position.y
		# Duplikasi shape agar tidak berbagi resource dengan scene lain
		collision_shape.shape = cap.duplicate()
	if track_manager == null:
		track_manager = get_node_or_null("../TrackManager")
	if track_manager:
		_update_transform_on_track()


func _physics_process(delta: float) -> void:
	if not is_auto_forward or is_track_completed:
		return

	if track_manager == null or track_manager.get_segment_count() == 0:
		return

	# Redam efek kompresi suspensi landing secara cepat
	if landing_squash > 0.0:
		landing_squash = move_toward(landing_squash, 0.0, 0.6 * delta)

	# Tangani input (Jump & Slide hanya dari state NORMAL saat di tanah)
	_handle_jump_input()
	_handle_slide_input()

	# Update fisika state aktif
	_update_jump(delta)
	_update_slide(delta)

	# Pergerakan lateral aktif di semua state (termasuk udara & slide)
	_handle_lateral_movement(delta)
	_update_visual_lean(delta)

	# Update visual animasi kendaraan & rider
	_update_action_visuals(delta)

	_advance_along_track(delta)


## Menangani input lompat — hanya dari state NORMAL dan saat di tanah
func _handle_jump_input() -> void:
	if move_state != MoveState.NORMAL:
		return
	if jump_height > 0.0:
		return
	if Input.is_action_just_pressed("jump"):
		move_state = MoveState.JUMPING
		jump_vertical_velocity = jump_initial_velocity
		jump_height = 0.0
		landing_squash = 0.0
		print("🦘 JUMP dimulai! Kecepatan awal: %.1fm/s (Target Apex: 1.6-1.8m)" % jump_initial_velocity)


## Update fisika lompatan — gravitasi lintasan-relatif
func _update_jump(delta: float) -> void:
	if move_state != MoveState.JUMPING:
		return

	# Terapkan gravitasi ke kecepatan vertikal
	jump_vertical_velocity -= jump_gravity * delta

	# Integrasi kecepatan ke ketinggian
	jump_height += jump_vertical_velocity * delta

	# Pendaratan: ketinggian turun ke 0 atau di bawah
	if jump_height <= 0.0:
		jump_height = 0.0
		jump_vertical_velocity = 0.0
		move_state = MoveState.NORMAL
		# Efek suspensi mendarat: kompresi sasis sesaat (rebound)
		landing_squash = 0.08
		print("🛬 JUMP selesai — mendarat halus di lintasan dengan efek suspensi.")


## Menangani input slide — hanya dari state NORMAL dan saat di tanah
func _handle_slide_input() -> void:
	if move_state != MoveState.NORMAL:
		return
	if jump_height > 0.0:
		return
	if Input.is_action_just_pressed("slide"):
		move_state = MoveState.SLIDING
		slide_timer = slide_duration
		slide_posture_t = 0.0
		_apply_slide_collider(true)
		print("🏂 LOW SIDE-SKID SLIDE dimulai! Durasi: %.2fs" % slide_duration)


## Update animasi dan timer slide
func _update_slide(delta: float) -> void:
	if move_state != MoveState.SLIDING:
		# Jika bukan sliding, kembalikan postur secara halus
		if slide_posture_t > 0.0:
			slide_posture_t = move_toward(slide_posture_t, 0.0, slide_recovery_speed * delta)
			if slide_posture_t <= 0.01:
				slide_posture_t = 0.0
				_apply_slide_collider(false)
		return

	# Fase slide aktif: transisi cepat masuk ke postur slide penuh (t = 1.0)
	var active_ratio: float = clampf(1.0 - (slide_timer / slide_duration), 0.0, 1.0)
	slide_posture_t = lerpf(slide_posture_t, 1.0, minf(active_ratio * 4.0 + 0.2, 1.0))

	slide_timer -= delta
	if slide_timer <= 0.0:
		slide_timer = 0.0
		move_state = MoveState.NORMAL
		print("🏁 SLIDE selesai — kembali ke postur normal secara mulus.")


## Memperbarui efek visual jump pitch, landing squash, putaran roda, dan low side-skid
func _update_action_visuals(_delta: float) -> void:
	# 1. Rotasi roda kontinu berdasarkan jarak tempuh (radius roda 0.28m)
	wheel_rotation_angle = fmod(total_distance / 0.28, TAU)
	if motorcycle and motorcycle.has_method("set_wheel_rotation"):
		motorcycle.set_wheel_rotation(wheel_rotation_angle)

	# 2. Visualisasi Jump & Landing
	if motorcycle and motorcycle.has_method("set_jump_visual"):
		motorcycle.set_jump_visual(jump_vertical_velocity, jump_height, landing_squash)

	# 3. Visualisasi Slide (Low Side-Skid)
	var steer_ratio: float = lateral_velocity / maxf(0.1, max_lateral_speed)
	if motorcycle and motorcycle.has_method("set_slide_visual"):
		motorcycle.set_slide_visual(slide_posture_t, steer_ratio)

	if rider and rider.has_method("set_crouch_ratio"):
		rider.set_crouch_ratio(slide_posture_t)


## Memperkecil atau mengembalikan CapsuleShape3D untuk state slide
## height minimum = 2 * radius = 0.70m (Godot capsule constraint)
func _apply_slide_collider(active: bool) -> void:
	if collision_shape == null or not (collision_shape.shape is CapsuleShape3D):
		return
	var cap: CapsuleShape3D = collision_shape.shape
	if active:
		# Kecilkan tinggi dari 1.35 → 0.72 (aman: 2 * radius=0.35 + margin 0.02)
		var slide_height: float = 0.72
		cap.height = slide_height
		# Sesuaikan offset Y agar alas capsule tetap tepat di permukaan jalan
		collision_shape.position.y = cap.radius + (slide_height - 2.0 * cap.radius) * 0.5
	else:
		# Kembalikan ke dimensi asli
		cap.height = _original_capsule_height
		collision_shape.position.y = _original_capsule_offset_y


## Menangani input kemudi dan kalkulasi fisika pergerakan lateral mulus
func _handle_lateral_movement(delta: float) -> void:
	var steer_input: float = 0.0
	if Input.is_action_pressed("move_left"):
		steer_input -= 1.0
	if Input.is_action_pressed("move_right"):
		steer_input += 1.0

	# Akselerasi menuju kecepatan target saat input aktif, atau deselerasi bertahap saat input netral
	if steer_input != 0.0:
		lateral_velocity = move_toward(
			lateral_velocity,
			steer_input * max_lateral_speed,
			lateral_acceleration * delta
		)
	else:
		lateral_velocity = move_toward(
			lateral_velocity,
			0.0,
			lateral_damping * delta
		)

	# Integrasi kecepatan lateral ke offset posisi
	lateral_offset += lateral_velocity * delta

	# Pembatasan batas aman jalan (Boundary Clamping)
	if lateral_offset < -max_lateral_offset:
		lateral_offset = -max_lateral_offset
		if lateral_velocity < 0.0:
			lateral_velocity = 0.0
	elif lateral_offset > max_lateral_offset:
		lateral_offset = max_lateral_offset
		if lateral_velocity > 0.0:
			lateral_velocity = 0.0


## Menerapkan dorongan kecepatan manuver lateral dari gestur swipe layar sentuh (Mobile)
func apply_lateral_impulse(direction: float) -> void:
	if direction < 0.0:
		lateral_velocity = clampf(lateral_velocity - swipe_impulse_strength, -max_lateral_speed, max_lateral_speed)
	elif direction > 0.0:
		lateral_velocity = clampf(lateral_velocity + swipe_impulse_strength, -max_lateral_speed, max_lateral_speed)


## Mengatur kemiringan visual (lean) motor dan rider secara halus berdasarkan kecepatan lateral
func _update_visual_lean(delta: float) -> void:
	var max_lean_rad: float = deg_to_rad(max_lean_angle_deg)
	var target_lean: float = - (lateral_velocity / maxf(0.1, max_lateral_speed)) * max_lean_rad
	current_lean_angle = lerpf(current_lean_angle, target_lean, lean_smoothing * delta)

	# Jika tidak sedang slide, set lean normal ke motor dan rider
	if slide_posture_t <= 0.01:
		if motorcycle and motorcycle.has_method("set_lean_angle"):
			motorcycle.set_lean_angle(current_lean_angle)
		if rider and rider.has_method("set_lean_angle"):
			rider.set_lean_angle(current_lean_angle)


## Memajukan jarak tempuh di sepanjang lintasan berdasarkan forward_speed dan delta waktu
func _advance_along_track(delta: float) -> void:
	var total_len: float = track_manager.get_total_length()

	total_distance += forward_speed * delta

	# Penanganan ujung akhir lintasan (Finite track handling)
	if total_len > 0.0 and total_distance >= total_len:
		total_distance = total_len
		is_track_completed = true
		lateral_velocity = 0.0
		print("🏁 Player mencapai ujung lintasan (Jarak: %.1fm). Berhenti dengan aman." % total_distance)

	_update_transform_on_track()


## Mengambil Transform3D dari TrackManager dan memperbarui posisi & orientasi PlayerController di dunia
## Jika sedang lompat, posisi digeser ke atas mengikuti sumbu Y lintasan (track-relative jump)
func _update_transform_on_track() -> void:
	if track_manager == null:
		return

	var track_tf: Transform3D = track_manager.get_transform_at_distance(total_distance, lateral_offset)

	if jump_height > 0.0:
		# Geser posisi ke atas mengikuti sumbu lokal lintasan (basis.y = track UP)
		# Ini memastikan lompatan benar di tanjakan, turunan, ramp, dan jembatan
		global_transform = Transform3D(track_tf.basis, track_tf.origin + track_tf.basis.y * jump_height)
	else:
		global_transform = track_tf


## Mereset posisi pemain kembali ke awal lintasan dan membersihkan semua state
func reset_to_start() -> void:
	total_distance = 0.0
	lateral_offset = 0.0
	lateral_velocity = 0.0
	current_lean_angle = 0.0
	is_track_completed = false
	# Reset state Jump
	move_state = MoveState.NORMAL
	jump_height = 0.0
	jump_vertical_velocity = 0.0
	landing_squash = 0.0
	# Reset state Slide
	slide_timer = 0.0
	slide_posture_t = 0.0
	_apply_slide_collider(false)
	if motorcycle and motorcycle.has_method("set_lean_angle"):
		motorcycle.set_lean_angle(0.0)
	if rider and rider.has_method("set_crouch_ratio"):
		rider.set_crouch_ratio(0.0)
	_update_transform_on_track()
	print("🔄 Player di-reset ke titik awal lintasan.")


## Mengambil referensi ke kendaraan dan pengendara dari hirarki scene
func _resolve_child_components() -> void:
	if vehicle_mount:
		for child in vehicle_mount.get_children():
			if child.is_class("Node3D") and child.get_script() == MotorcycleBasicScript:
				motorcycle = child
				break
	
	if motorcycle and motorcycle.has_method("get_rider_mount"):
		var mount: Node3D = motorcycle.get_rider_mount()
		if mount:
			for child in mount.get_children():
				if child.is_class("Node3D") and child.get_script() == PoncoRiderScript:
					rider = child
					break


## Memastikan pengendara terpasang di atas jok kendaraan
func _ensure_rider_mounted() -> void:
	if motorcycle and rider == null and default_rider_scene:
		if motorcycle.has_method("get_rider_mount"):
			var mount: Node3D = motorcycle.get_rider_mount()
			if mount:
				var rider_instance: Node = default_rider_scene.instantiate()
				mount.add_child(rider_instance)
				rider = rider_instance


## Mendapatkan informasi segmen tempat pemain berada saat ini
func get_current_segment_info() -> Dictionary:
	if track_manager:
		return track_manager.get_segment_info_at_distance(total_distance)
	return {"segment": null, "index": -1, "local_dist": 0.0, "segment_length": 0.0}


## Mendapatkan nama state pergerakan aktif (untuk diagnostik HUD)
func get_move_state() -> String:
	match move_state:
		MoveState.NORMAL:
			return "Normal"
		MoveState.JUMPING:
			return "LOMPAT 🦘 (H=%.2fm, V=%.1fm/s)" % [jump_height, jump_vertical_velocity]
		MoveState.SLIDING:
			return "LOW SIDE-SKID SLIDE 🏂 (%.2fs)" % slide_timer
	return "?"


## Mendapatkan ketinggian lompatan saat ini (meter di atas permukaan lintasan)
func get_jump_height() -> float:
	return jump_height


## Mendapatkan kecepatan vertikal lompatan saat ini (meter per detik)
func get_jump_vertical_velocity() -> float:
	return jump_vertical_velocity


## Mendapatkan waktu tersisa slide saat ini (detik)
func get_slide_timer() -> float:
	return slide_timer


## Mendapatkan nilai offset lateral saat ini
func get_lateral_offset() -> float:
	return lateral_offset


## Mendapatkan nilai kecepatan lateral saat ini
func get_lateral_velocity() -> float:
	return lateral_velocity


## Mendapatkan sudut kemiringan visual saat ini dalam derajat (steering lean)
func get_lean_angle_deg() -> float:
	return rad_to_deg(current_lean_angle)


## Mendapatkan sudut roll/bank visual aktual dari VisualPivot kendaraan (derajat)
func get_actual_bank_deg() -> float:
	if motorcycle and motorcycle.has_method("get_actual_roll_deg"):
		return motorcycle.get_actual_roll_deg()
	return rad_to_deg(current_lean_angle)


## Mendapatkan instance kendaraan aktif
func get_motorcycle() -> Node3D:
	return motorcycle


## Mendapatkan instance pengendara aktif
func get_rider() -> Node3D:
	return rider

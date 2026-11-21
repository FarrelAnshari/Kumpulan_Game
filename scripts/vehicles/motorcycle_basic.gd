class_name MotorcycleBasic
extends Node3D

## MotorcycleBasic: Model visual dan struktur motor petualang.
## Menggunakan visual primitives modular yang merepresentasikan sasis motor, roda, stang, dan jok.
## Mendukung rotasi roda, lean berbelok, jump pitch/rebound, dan low side-skid slide.

@onready var visual_pivot: Node3D = $VisualPivot
@onready var front_wheel: Node3D = $VisualPivot/FrontWheel
@onready var rear_wheel: Node3D = $VisualPivot/RearWheel
@onready var rider_mount: Node3D = $VisualPivot/RiderMount

# Referensi bagian-bagian sasis / bodi motor (untuk kompresi suspensi tanpa menenggelamkan roda)
var chassis_parts: Array[Node3D] = []
var base_part_positions: Dictionary = {}
var base_front_wheel_pos: Vector3 = Vector3.ZERO
var base_rear_wheel_pos: Vector3 = Vector3.ZERO

# State visual dinamis
var current_lean_z: float = 0.0
var jump_pitch_x: float = 0.0
var landing_squash_y: float = 0.0


func _ready() -> void:
	if visual_pivot:
		if front_wheel:
			base_front_wheel_pos = front_wheel.position
		if rear_wheel:
			base_rear_wheel_pos = rear_wheel.position

		# Catat semua node di VisualPivot yang merupakan sasis/bodi (selain roda)
		for child in visual_pivot.get_children():
			if child is Node3D and child != front_wheel and child != rear_wheel:
				chassis_parts.append(child)
				base_part_positions[child] = child.position


## Mendapatkan node mount tempat pengendara diposisikan
func get_rider_mount() -> Node3D:
	return rider_mount if rider_mount else self


## Memutar roda motor berdasarkan jarak tempuh
func set_wheel_rotation(angle_rad: float) -> void:
	if front_wheel:
		front_wheel.rotation.x = angle_rad
	if rear_wheel:
		rear_wheel.rotation.x = angle_rad


## Memiringkan motor saat berbelok / manuver lateral (state NORMAL)
func set_lean_angle(angle_rad: float) -> void:
	current_lean_z = angle_rad
	if visual_pivot:
		visual_pivot.rotation.z = angle_rad
		visual_pivot.rotation.y = 0.0
		visual_pivot.rotation.x = jump_pitch_x


## Efek visual saat lompat: sedikit pitch up saat takeoff, pitch down saat descending, dan suspension compression saat landing
func set_jump_visual(vertical_velocity: float, _jump_height: float, landing_squash: float) -> void:
	# Pitch dinamis saat di udara: naik = pitch up (+), turun = pitch down (-)
	if vertical_velocity > 1.0:
		jump_pitch_x = deg_to_rad(6.0 * clampf(vertical_velocity / 7.8, 0.0, 1.0))
	elif vertical_velocity < -1.0:
		jump_pitch_x = deg_to_rad(-4.5 * clampf(-vertical_velocity / 7.8, 0.0, 1.0))
	else:
		jump_pitch_x = 0.0

	landing_squash_y = landing_squash

	# Terapkan kompresi landing pada sasis (roda tetap menapak tanah)
	_apply_chassis_compression(landing_squash_y)

	if visual_pivot:
		visual_pivot.rotation.x = jump_pitch_x


## Efek visual Low Side-Skid Slide:
## - Kompresi sasis ke bawah (0.15 - 0.22m) TANPA menenggelamkan roda ke aspal
## - Bank/roll miring menyamping (18 - 22 derajat)
## - Yaw side-skid/drift (5 - 8 derajat) merespons kemudi lateral
func set_slide_visual(t: float, steer_val: float) -> void:
	if visual_pivot == null:
		return

	# 1. Kompresi sasis (0.18m pada t = 1.0)
	var compression: float = 0.18 * t
	_apply_chassis_compression(compression)

	# 2. Sudut Bank (Roll) dan Yaw (Side-Skid)
	var target_bank_deg: float = 20.0
	var target_yaw_deg: float = 6.5

	var active_bank: float = 0.0
	var active_yaw: float = 0.0

	if steer_val < -0.15:
		# Belok kiri saat slide: miring ke kiri (roll positif), nose counter-skid (yaw negatif)
		active_bank = deg_to_rad(target_bank_deg)
		active_yaw = -deg_to_rad(target_yaw_deg)
	elif steer_val > 0.15:
		# Belok kanan saat slide: miring ke kanan (roll negatif), nose counter-skid (yaw positif)
		active_bank = -deg_to_rad(target_bank_deg)
		active_yaw = deg_to_rad(target_yaw_deg)
	else:
		# Netral: default low side-skid miring ke kanan sedikit (bergaya Subway Surfers)
		active_bank = -deg_to_rad(18.5)
		active_yaw = deg_to_rad(5.5)

	# Interpolasi dari normal lean ke slide bank & yaw
	visual_pivot.rotation.z = lerpf(current_lean_z, active_bank, t)
	visual_pivot.rotation.y = lerpf(0.0, active_yaw, t)
	visual_pivot.rotation.x = lerpf(jump_pitch_x, deg_to_rad(-6.0), t)


## Kompatibilitas dengan pemanggil lama
func set_slide_posture(t: float) -> void:
	set_slide_visual(t, 0.0)


## Menurunkan bagian sasis/bodi mendekati as roda TANPA menurunkan roda
func _apply_chassis_compression(offset_y: float) -> void:
	for part in chassis_parts:
		if is_instance_valid(part) and base_part_positions.has(part):
			var base_pos: Vector3 = base_part_positions[part]
			part.position.y = base_pos.y - offset_y

	# Pastikan roda tetap kokoh di posisi aslinya (Y = 0.28m menapak aspal)
	if front_wheel and base_front_wheel_pos != Vector3.ZERO:
		front_wheel.position.y = base_front_wheel_pos.y
	if rear_wheel and base_rear_wheel_pos != Vector3.ZERO:
		rear_wheel.position.y = base_rear_wheel_pos.y

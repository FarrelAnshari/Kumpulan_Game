class_name ChaseCamera
extends Camera3D

# ChaseCamera: Kamera third-person yang mengikuti target secara halus.
# Mendukung penyesuaian offset, kecepatan follow, dan elevasi lintasan.
# Digunakan untuk mengikuti kendaraan pemain atau test rig.

## Target yang diikuti oleh kamera
@export var target_path: NodePath
var target: Node3D

# --- Parameter kamera yang bisa disesuaikan di Inspector ---
@export_group("Camera Offset")
@export var follow_distance: float = 10.0   # Jarak di belakang target (meter)
@export var follow_height: float = 5.0      # Ketinggian di atas target (meter)
@export var look_ahead_offset: float = 5.0  # Jarak pandang ke depan target (meter)

@export_group("Smoothing")
@export var position_smoothing: float = 5.0   # Kecepatan interpolasi posisi
@export var rotation_smoothing: float = 4.0   # Kecepatan interpolasi rotasi

@export_group("Field of View")
@export var base_fov: float = 65.0  # FOV dasar (derajat)

# Posisi kamera yang dihitung
var desired_position: Vector3 = Vector3.ZERO
var desired_look_at: Vector3 = Vector3.ZERO


func _ready() -> void:
	# Ambil referensi target berdasarkan NodePath
	if target_path:
		target = get_node_or_null(target_path)

	# Set FOV awal
	fov = base_fov
	keep_aspect = Camera3D.KEEP_WIDTH

	# Jika target sudah tersedia, langsung posisikan kamera
	if target:
		_snap_to_target()


func _process(delta: float) -> void:
	if target == null:
		# Coba ambil target jika belum tersedia
		if target_path:
			target = get_node_or_null(target_path)
		return

	_update_camera(delta)


## Langsung menempatkan kamera di posisi ideal (tanpa interpolasi)
func _snap_to_target() -> void:
	if target == null:
		return

	_calculate_desired_transform()
	global_position = desired_position
	look_at(desired_look_at, Vector3.UP)


## Menghitung posisi dan arah pandang ideal kamera
func _calculate_desired_transform() -> void:
	var target_pos: Vector3 = target.global_position
	var target_forward: Vector3 = -target.global_basis.z.normalized()

	# Posisi kamera: di belakang dan di atas target
	desired_position = target_pos - target_forward * follow_distance
	desired_position.y = target_pos.y + follow_height

	# Titik pandang: sedikit di depan target
	desired_look_at = target_pos + target_forward * look_ahead_offset
	desired_look_at.y = target_pos.y


## Memperbarui posisi dan rotasi kamera dengan interpolasi halus
func _update_camera(delta: float) -> void:
	_calculate_desired_transform()

	# Interpolasi posisi
	global_position = global_position.lerp(desired_position, position_smoothing * delta)

	# Interpolasi rotasi (look_at menghasilkan transform baru, lalu slerp)
	var current_basis: Basis = global_basis
	# Hitung basis tujuan dengan melihat ke target
	var direction: Vector3 = (desired_look_at - global_position).normalized()
	if direction.length_squared() > 0.001:
		var target_basis: Basis = Basis.looking_at(direction, Vector3.UP)
		global_basis = current_basis.slerp(target_basis, rotation_smoothing * delta)


## Mengatur target baru untuk kamera
func set_target(new_target: Node3D) -> void:
	target = new_target
	if target:
		_snap_to_target()


## Mengatur jarak follow secara runtime
func set_follow_distance(dist: float) -> void:
	follow_distance = maxf(3.0, dist)


## Mengatur ketinggian follow secara runtime
func set_follow_height(height: float) -> void:
	follow_height = maxf(1.0, height)

class_name PoncoRider
extends Node3D

## PoncoRider: Karakter pengendara utama (Ponco).
## Menggunakan visual primitives modular yang merepresentasikan pengendara petualang.
## Mendukung kemiringan tubuh saat berbelok dan postur merunduk rendah (Low Crouch) saat slide.

@onready var visual_pivot: Node3D = $VisualPivot
@onready var torso_mesh: MeshInstance3D = $VisualPivot/Torso
@onready var head_mesh: MeshInstance3D = $VisualPivot/Head
@onready var left_arm: MeshInstance3D = $VisualPivot/LeftArm
@onready var right_arm: MeshInstance3D = $VisualPivot/RightArm

# Posisi dan rotasi dasar saat mengendarai normal
var base_torso_pos: Vector3 = Vector3(0, 0.32, -0.06)
var base_torso_rot_x: float = -0.21
var base_head_pos: Vector3 = Vector3(0, 0.58, -0.12)
var base_head_rot_x: float = 0.0

var base_left_arm_pos: Vector3 = Vector3(-0.22, 0.42, -0.28)
var base_right_arm_pos: Vector3 = Vector3(0.22, 0.42, -0.28)


func _ready() -> void:
	if torso_mesh:
		base_torso_pos = torso_mesh.position
		base_torso_rot_x = torso_mesh.rotation.x
	if head_mesh:
		base_head_pos = head_mesh.position
		base_head_rot_x = head_mesh.rotation.x
	if left_arm:
		base_left_arm_pos = left_arm.position
	if right_arm:
		base_right_arm_pos = right_arm.position


## Menyesuaikan kemiringan badan pengendara saat berbelok / lateral lean
func set_lean_angle(angle_rad: float) -> void:
	if visual_pivot:
		visual_pivot.rotation.z = angle_rad * 0.7


## Menyesuaikan postur merunduk rendah (Low Crouch) saat Slide (Subway Surfers style adaptation)
## ratio = 0.0 (tegak normal) hingga 1.0 (merunduk penuh menempel stang)
func set_crouch_ratio(ratio: float) -> void:
	if torso_mesh:
		# Badan melipat ke depan secara tajam mendekati tangki motor
		torso_mesh.rotation.x = lerpf(base_torso_rot_x, -0.92, ratio)
		torso_mesh.position.y = lerpf(base_torso_pos.y, 0.16, ratio)
		torso_mesh.position.z = lerpf(base_torso_pos.z, -0.15, ratio)

	if head_mesh:
		# Kepala ikut merunduk rendah dan maju mendekati stang
		head_mesh.position.y = lerpf(base_head_pos.y, 0.36, ratio)
		head_mesh.position.z = lerpf(base_head_pos.z, -0.27, ratio)
		head_mesh.rotation.x = lerpf(base_head_rot_x, -0.32, ratio)

	# Lengan ikut turun agar tangan tetap sejajar memegang stang
	if left_arm:
		left_arm.position.y = lerpf(base_left_arm_pos.y, 0.27, ratio)
		left_arm.position.z = lerpf(base_left_arm_pos.z, -0.34, ratio)
	if right_arm:
		right_arm.position.y = lerpf(base_right_arm_pos.y, 0.27, ratio)
		right_arm.position.z = lerpf(base_right_arm_pos.z, -0.34, ratio)

class_name TrackRamp
extends TrackSegment

# TrackRamp: Segmen ramp lompat.
# Terdiri dari tanjakan pendek yang berakhir di ujung tajam untuk lompatan.

@export var ramp_height: float = 2.5     # Tinggi puncak ramp (meter)
@export var ramp_up_length: float = 8.0  # Panjang bagian naik
@export var ramp_flat_length: float = 4.0  # Panjang bagian datar di puncak
@export var ramp_down_length: float = 8.0  # Panjang bagian turun / pendaratan

const RAMP_RESOLUTION: int = 6


func _ready() -> void:
	segment_type = SegmentType.RAMP
	segment_length = ramp_up_length + ramp_flat_length + ramp_down_length
	super._ready()


func _calculate_connection_points() -> void:
	entry_point = Vector3.ZERO
	entry_forward = Vector3(0.0, 0.0, -1.0)

	# Ramp naik lalu turun → keluar di ketinggian yang sama dengan masuk
	exit_point = Vector3(0.0, 0.0, -segment_length)
	exit_forward = Vector3(0.0, 0.0, -1.0)


func _build_segment_geometry() -> void:
	var asphalt_mat: StandardMaterial3D = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.22, 0.22, 0.25, 1.0)
	asphalt_mat.roughness = 0.7

	var ramp_mat: StandardMaterial3D = StandardMaterial3D.new()
	ramp_mat.albedo_color = Color(0.35, 0.3, 0.28, 1.0)
	ramp_mat.roughness = 0.6

	var shoulder_mat: StandardMaterial3D = StandardMaterial3D.new()
	shoulder_mat.albedo_color = Color(0.45, 0.38, 0.35, 1.0)
	shoulder_mat.roughness = 0.8

	# Bagian naik (upward slope)
	var up_slope: float = atan2(ramp_height, ramp_up_length)
	var up_step_len: float = ramp_up_length / float(RAMP_RESOLUTION)
	var up_step_h: float = ramp_height / float(RAMP_RESOLUTION)

	for i in range(RAMP_RESOLUTION):
		var z_pos: float = -up_step_len * (float(i) + 0.5)
		var y_pos: float = up_step_h * (float(i) + 0.5)
		_add_road_piece("RampUp_" + str(i), ramp_mat, shoulder_mat,
			Vector3(0.0, y_pos, z_pos), up_slope, up_step_len * 1.02)

	# Bagian datar di puncak
	var flat_z_start: float = -ramp_up_length
	var flat_step: float = ramp_flat_length / 2.0
	for i in range(2):
		var z_pos: float = flat_z_start - flat_step * (float(i) + 0.5)
		_add_road_piece("RampFlat_" + str(i), asphalt_mat, shoulder_mat,
			Vector3(0.0, ramp_height, z_pos), 0.0, flat_step * 1.02)

	# Bagian turun (downward slope)
	var down_z_start: float = -(ramp_up_length + ramp_flat_length)
	var down_slope: float = atan2(-ramp_height, ramp_down_length)
	var down_step_len: float = ramp_down_length / float(RAMP_RESOLUTION)
	var down_step_h: float = ramp_height / float(RAMP_RESOLUTION)

	for i in range(RAMP_RESOLUTION):
		var z_pos: float = down_z_start - down_step_len * (float(i) + 0.5)
		var y_pos: float = ramp_height - down_step_h * (float(i) + 0.5)
		_add_road_piece("RampDown_" + str(i), ramp_mat, shoulder_mat,
			Vector3(0.0, y_pos, z_pos), down_slope, down_step_len * 1.02)


func _add_road_piece(piece_name: String, road_mat: StandardMaterial3D,
		shoulder_mat: StandardMaterial3D, pos: Vector3,
		slope_angle: float, piece_length: float) -> void:
	# Aspal
	var road: MeshInstance3D = MeshInstance3D.new()
	road.name = piece_name
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(ROAD_WIDTH, ROAD_THICKNESS, piece_length)
	box.material = road_mat
	road.mesh = box
	road.position = pos
	road.rotation.x = slope_angle
	add_child(road)

	# Bahu
	for side in [-1.0, 1.0]:
		var shoulder: MeshInstance3D = MeshInstance3D.new()
		shoulder.name = piece_name + "_Shoulder_" + ("L" if side < 0 else "R")
		var sbox: BoxMesh = BoxMesh.new()
		sbox.size = Vector3(SHOULDER_WIDTH, ROAD_THICKNESS * 0.85, piece_length)
		sbox.material = shoulder_mat
		shoulder.mesh = sbox
		shoulder.position = pos + Vector3(
			side * (ROAD_WIDTH * 0.5 + SHOULDER_WIDTH * 0.5), 0.0, 0.0
		)
		shoulder.rotation.x = slope_angle
		add_child(shoulder)


func _build_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "RoadCollision"
	add_child(collision_body)

	# Collision bagian naik
	var up_slope: float = atan2(ramp_height, ramp_up_length)
	var up_step_len: float = ramp_up_length / float(RAMP_RESOLUTION)
	var up_step_h: float = ramp_height / float(RAMP_RESOLUTION)
	for i in range(RAMP_RESOLUTION):
		_add_collision_piece("RampUpCol_" + str(i),
			Vector3(0.0, up_step_h * (float(i) + 0.5), -up_step_len * (float(i) + 0.5)),
			up_slope, up_step_len * 1.02)

	# Collision bagian datar
	var flat_z_start: float = -ramp_up_length
	var flat_step: float = ramp_flat_length / 2.0
	for i in range(2):
		_add_collision_piece("RampFlatCol_" + str(i),
			Vector3(0.0, ramp_height, flat_z_start - flat_step * (float(i) + 0.5)),
			0.0, flat_step * 1.02)

	# Collision bagian turun
	var down_z_start: float = -(ramp_up_length + ramp_flat_length)
	var down_slope: float = atan2(-ramp_height, ramp_down_length)
	var down_step_len: float = ramp_down_length / float(RAMP_RESOLUTION)
	var down_step_h: float = ramp_height / float(RAMP_RESOLUTION)
	for i in range(RAMP_RESOLUTION):
		_add_collision_piece("RampDownCol_" + str(i),
			Vector3(0.0, ramp_height - down_step_h * (float(i) + 0.5),
				down_z_start - down_step_len * (float(i) + 0.5)),
			down_slope, down_step_len * 1.02)


func _add_collision_piece(piece_name: String, pos: Vector3,
		slope_angle: float, piece_length: float) -> void:
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	shape_node.name = piece_name
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(TOTAL_WIDTH, ROAD_THICKNESS, piece_length)
	shape_node.shape = shape
	shape_node.position = pos
	shape_node.rotation.x = slope_angle
	collision_body.add_child(shape_node)

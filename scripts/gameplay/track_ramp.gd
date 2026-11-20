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

	# 1. Bagian naik kontinu tunggal (upward slope)
	var up_slope: float = atan2(ramp_height, ramp_up_length)
	var up_len: float = sqrt(ramp_up_length * ramp_up_length + ramp_height * ramp_height)
	var up_pos: Vector3 = Vector3(0.0, ramp_height * 0.5, -ramp_up_length * 0.5)
	_add_road_piece("RampUp", ramp_mat, shoulder_mat, up_pos, up_slope, up_len)

	# 2. Bagian datar di puncak kontinu tunggal (flat peak)
	var flat_pos: Vector3 = Vector3(0.0, ramp_height, -(ramp_up_length + ramp_flat_length * 0.5))
	_add_road_piece("RampFlat", asphalt_mat, shoulder_mat, flat_pos, 0.0, ramp_flat_length)

	# 3. Bagian turun kontinu tunggal (downward slope)
	var down_slope: float = atan2(-ramp_height, ramp_down_length)
	var down_len: float = sqrt(ramp_down_length * ramp_down_length + ramp_height * ramp_height)
	var down_pos: Vector3 = Vector3(0.0, ramp_height * 0.5, -(ramp_up_length + ramp_flat_length + ramp_down_length * 0.5))
	_add_road_piece("RampDown", ramp_mat, shoulder_mat, down_pos, down_slope, down_len)


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

	# Marka lajur
	var line_mat: StandardMaterial3D = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.95, 0.95, 0.95, 1.0)
	line_mat.roughness = 0.4
	var line_x_positions: Array[float] = [
		-ROAD_WIDTH * 0.5, -LANE_WIDTH * 0.5,
		LANE_WIDTH * 0.5, ROAD_WIDTH * 0.5,
	]
	for lx in range(line_x_positions.size()):
		var line_piece: MeshInstance3D = MeshInstance3D.new()
		line_piece.name = piece_name + "_Line_" + str(lx)
		var lbox: BoxMesh = BoxMesh.new()
		lbox.size = Vector3(LINE_WIDTH, ROAD_THICKNESS + LINE_HEIGHT_OFFSET, piece_length)
		lbox.material = line_mat
		line_piece.mesh = lbox
		line_piece.position = pos + Vector3(line_x_positions[lx], LINE_HEIGHT_OFFSET, 0.0)
		line_piece.rotation.x = slope_angle
		add_child(line_piece)


func _build_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "RoadCollision"
	add_child(collision_body)

	# 1. Collision bagian naik
	var up_slope: float = atan2(ramp_height, ramp_up_length)
	var up_len: float = sqrt(ramp_up_length * ramp_up_length + ramp_height * ramp_height)
	var up_pos: Vector3 = Vector3(0.0, ramp_height * 0.5, -ramp_up_length * 0.5)
	_add_collision_piece("RampUpCol", up_pos, up_slope, up_len)

	# 2. Collision bagian datar puncak
	var flat_pos: Vector3 = Vector3(0.0, ramp_height, -(ramp_up_length + ramp_flat_length * 0.5))
	_add_collision_piece("RampFlatCol", flat_pos, 0.0, ramp_flat_length)

	# 3. Collision bagian turun
	var down_slope: float = atan2(-ramp_height, ramp_down_length)
	var down_len: float = sqrt(ramp_down_length * ramp_down_length + ramp_height * ramp_height)
	var down_pos: Vector3 = Vector3(0.0, ramp_height * 0.5, -(ramp_up_length + ramp_flat_length + ramp_down_length * 0.5))
	_add_collision_piece("RampDownCol", down_pos, down_slope, down_len)


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


## Menghitung posisi dan orientasi lokal di sepanjang ramp (naik, datar, turun)
func get_local_transform_at_distance(dist: float, lane_offset: float = 0.0) -> Transform3D:
	var clamped_dist: float = clampf(dist, 0.0, segment_length)
	var pos: Vector3 = Vector3.ZERO
	var forward: Vector3 = Vector3(0.0, 0.0, -1.0)
	var up: Vector3 = Vector3.UP

	if clamped_dist < ramp_up_length:
		var up_slope: float = atan2(ramp_height, ramp_up_length)
		var t: float = clamped_dist / maxf(0.001, ramp_up_length)
		var y: float = ramp_height * t + ROAD_THICKNESS * 0.5
		pos = Vector3(lane_offset, y, -clamped_dist)
		forward = Vector3(0.0, sin(up_slope), -cos(up_slope)).normalized()
		up = Vector3(0.0, cos(up_slope), sin(up_slope)).normalized()
	elif clamped_dist < ramp_up_length + ramp_flat_length:
		var y: float = ramp_height + ROAD_THICKNESS * 0.5
		pos = Vector3(lane_offset, y, -clamped_dist)
		forward = Vector3(0.0, 0.0, -1.0)
		up = Vector3.UP
	else:
		var down_slope: float = atan2(-ramp_height, ramp_down_length)
		var s_down: float = clamped_dist - (ramp_up_length + ramp_flat_length)
		var t: float = s_down / maxf(0.001, ramp_down_length)
		var y: float = ramp_height * (1.0 - t) + ROAD_THICKNESS * 0.5
		pos = Vector3(lane_offset, y, -clamped_dist)
		forward = Vector3(0.0, sin(down_slope), -cos(down_slope)).normalized()
		up = Vector3(0.0, cos(down_slope), sin(down_slope)).normalized()

	var basis: Basis = Basis.looking_at(forward, up)
	return Transform3D(basis, pos)

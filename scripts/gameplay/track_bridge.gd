class_name TrackBridge
extends TrackSegment

# TrackBridge: Segmen jembatan yang terangkat di atas permukaan tanah.
# Terdiri dari jalur naik pendek, jembatan datar di ketinggian, dan jalur turun.

@export var bridge_height: float = 4.0       # Ketinggian jembatan (meter)
@export var bridge_span_length: float = 24.0 # Panjang bentangan jembatan datar
@export var approach_length: float = 8.0     # Panjang jalur naik/turun

const APPROACH_RESOLUTION: int = 4


func _ready() -> void:
	segment_type = SegmentType.BRIDGE
	segment_length = approach_length + bridge_span_length + approach_length
	super._ready()


func _calculate_connection_points() -> void:
	entry_point = Vector3.ZERO
	entry_forward = Vector3(0.0, 0.0, -1.0)
	# Keluar di ketinggian yang sama (naik lalu turun)
	exit_point = Vector3(0.0, 0.0, -segment_length)
	exit_forward = Vector3(0.0, 0.0, -1.0)


func _build_segment_geometry() -> void:
	var asphalt_mat: StandardMaterial3D = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.22, 0.22, 0.25, 1.0)
	asphalt_mat.roughness = 0.7

	var bridge_mat: StandardMaterial3D = StandardMaterial3D.new()
	bridge_mat.albedo_color = Color(0.35, 0.35, 0.38, 1.0)
	bridge_mat.roughness = 0.5

	var shoulder_mat: StandardMaterial3D = StandardMaterial3D.new()
	shoulder_mat.albedo_color = Color(0.45, 0.38, 0.35, 1.0)
	shoulder_mat.roughness = 0.8

	var railing_mat: StandardMaterial3D = StandardMaterial3D.new()
	railing_mat.albedo_color = Color(0.6, 0.6, 0.65, 1.0)
	railing_mat.metallic = 0.5
	railing_mat.roughness = 0.3

	# 1. Jalur naik kontinu tunggal
	var up_slope: float = atan2(bridge_height, approach_length)
	var up_len: float = sqrt(approach_length * approach_length + bridge_height * bridge_height)
	var up_pos: Vector3 = Vector3(0.0, bridge_height * 0.5, -approach_length * 0.5)
	_add_road_piece("BridgeUp", asphalt_mat, shoulder_mat, up_pos, up_slope, up_len)

	# 2. Bentangan jembatan datar kontinu tunggal
	var span_z_start: float = -approach_length
	var span_pos: Vector3 = Vector3(0.0, bridge_height, span_z_start - bridge_span_length * 0.5)
	_add_road_piece("BridgeSpan", bridge_mat, shoulder_mat, span_pos, 0.0, bridge_span_length)

	# Pagar pengaman jembatan (kiri dan kanan)
	for side in [-1.0, 1.0]:
		var railing: MeshInstance3D = MeshInstance3D.new()
		railing.name = "Railing_" + ("L" if side < 0 else "R")
		var rbox: BoxMesh = BoxMesh.new()
		rbox.size = Vector3(0.15, 1.2, bridge_span_length)
		rbox.material = railing_mat
		railing.mesh = rbox
		railing.position = Vector3(
			side * (TOTAL_WIDTH * 0.5 + 0.1),
			bridge_height + 0.6,
			span_z_start - bridge_span_length * 0.5
		)
		add_child(railing)

	# 3. Jalur turun kontinu tunggal
	var down_slope: float = atan2(-bridge_height, approach_length)
	var down_pos: Vector3 = Vector3(0.0, bridge_height * 0.5, -(approach_length + bridge_span_length + approach_length * 0.5))
	_add_road_piece("BridgeDown", asphalt_mat, shoulder_mat, down_pos, down_slope, up_len)

	# Pilar penyangga jembatan
	_build_support_pillars(span_z_start, bridge_mat)


func _build_support_pillars(span_z_start: float, pillar_mat: StandardMaterial3D) -> void:
	var pillar_count: int = 3  # Jumlah pilar
	var spacing: float = bridge_span_length / float(pillar_count + 1)

	for i in range(pillar_count):
		var z: float = span_z_start - spacing * float(i + 1)
		for side in [-1.0, 1.0]:
			var pillar: MeshInstance3D = MeshInstance3D.new()
			pillar.name = "Pillar_" + str(i) + "_" + ("L" if side < 0 else "R")
			var pbox: BoxMesh = BoxMesh.new()
			pbox.size = Vector3(0.6, bridge_height, 0.6)
			pbox.material = pillar_mat
			pillar.mesh = pbox
			pillar.position = Vector3(side * 4.0, bridge_height * 0.5, z)
			add_child(pillar)


func _add_road_piece(piece_name: String, road_mat: StandardMaterial3D,
		shoulder_mat: StandardMaterial3D, pos: Vector3,
		slope_angle: float, piece_length: float) -> void:
	var road: MeshInstance3D = MeshInstance3D.new()
	road.name = piece_name
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(ROAD_WIDTH, ROAD_THICKNESS, piece_length)
	box.material = road_mat
	road.mesh = box
	road.position = pos
	road.rotation.x = slope_angle
	add_child(road)

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

	var up_slope: float = atan2(bridge_height, approach_length)
	var up_len: float = sqrt(approach_length * approach_length + bridge_height * bridge_height)

	# 1. Collision jalur naik
	_add_col("BridgeUpCol", Vector3(0.0, bridge_height * 0.5, -approach_length * 0.5), up_slope, up_len)

	# 2. Collision bentangan datar
	var span_z_start: float = -approach_length
	_add_col("BridgeSpanCol", Vector3(0.0, bridge_height, span_z_start - bridge_span_length * 0.5), 0.0, bridge_span_length)

	# 3. Collision jalur turun
	var down_slope: float = atan2(-bridge_height, approach_length)
	var down_pos: Vector3 = Vector3(0.0, bridge_height * 0.5, -(approach_length + bridge_span_length + approach_length * 0.5))
	_add_col("BridgeDownCol", down_pos, down_slope, up_len)


func _add_col(col_name: String, pos: Vector3,
		slope_angle: float, piece_length: float) -> void:
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	shape_node.name = col_name
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(TOTAL_WIDTH, ROAD_THICKNESS, piece_length)
	shape_node.shape = shape
	shape_node.position = pos
	shape_node.rotation.x = slope_angle
	collision_body.add_child(shape_node)


## Menghitung posisi dan orientasi lokal di sepanjang jembatan (naik, bentang datar, turun)
func get_local_transform_at_distance(dist: float, lane_offset: float = 0.0) -> Transform3D:
	var clamped_dist: float = clampf(dist, 0.0, segment_length)
	var pos: Vector3 = Vector3.ZERO
	var forward: Vector3 = Vector3(0.0, 0.0, -1.0)
	var up: Vector3 = Vector3.UP

	if clamped_dist < approach_length:
		var up_slope: float = atan2(bridge_height, approach_length)
		var t: float = clamped_dist / maxf(0.001, approach_length)
		var y: float = bridge_height * t + ROAD_THICKNESS * 0.5
		pos = Vector3(lane_offset, y, -clamped_dist)
		forward = Vector3(0.0, sin(up_slope), -cos(up_slope)).normalized()
		up = Vector3(0.0, cos(up_slope), sin(up_slope)).normalized()
	elif clamped_dist < approach_length + bridge_span_length:
		var y: float = bridge_height + ROAD_THICKNESS * 0.5
		pos = Vector3(lane_offset, y, -clamped_dist)
		forward = Vector3(0.0, 0.0, -1.0)
		up = Vector3.UP
	else:
		var down_slope: float = atan2(-bridge_height, approach_length)
		var s_down: float = clamped_dist - (approach_length + bridge_span_length)
		var t: float = s_down / maxf(0.001, approach_length)
		var y: float = bridge_height * (1.0 - t) + ROAD_THICKNESS * 0.5
		pos = Vector3(lane_offset, y, -clamped_dist)
		forward = Vector3(0.0, sin(down_slope), -cos(down_slope)).normalized()
		up = Vector3(0.0, cos(down_slope), sin(down_slope)).normalized()

	var basis: Basis = Basis.looking_at(forward, up)
	return Transform3D(basis, pos)

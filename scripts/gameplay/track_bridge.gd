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

	# Jalur naik
	var up_slope: float = atan2(bridge_height, approach_length)
	var up_step: float = approach_length / float(APPROACH_RESOLUTION)
	var up_h_step: float = bridge_height / float(APPROACH_RESOLUTION)
	for i in range(APPROACH_RESOLUTION):
		var z: float = -up_step * (float(i) + 0.5)
		var y: float = up_h_step * (float(i) + 0.5)
		_add_road_piece("BridgeUp_" + str(i), asphalt_mat, shoulder_mat,
			Vector3(0.0, y, z), up_slope, up_step * 1.02)

	# Bentangan jembatan datar
	var span_z_start: float = -approach_length
	var span_steps: int = 4
	var span_step_len: float = bridge_span_length / float(span_steps)
	for i in range(span_steps):
		var z: float = span_z_start - span_step_len * (float(i) + 0.5)
		_add_road_piece("BridgeSpan_" + str(i), bridge_mat, shoulder_mat,
			Vector3(0.0, bridge_height, z), 0.0, span_step_len * 1.02)

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

	# Jalur turun
	var down_z_start: float = -(approach_length + bridge_span_length)
	var down_slope: float = atan2(-bridge_height, approach_length)
	for i in range(APPROACH_RESOLUTION):
		var z: float = down_z_start - up_step * (float(i) + 0.5)
		var y: float = bridge_height - up_h_step * (float(i) + 0.5)
		_add_road_piece("BridgeDown_" + str(i), asphalt_mat, shoulder_mat,
			Vector3(0.0, y, z), down_slope, up_step * 1.02)

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


func _build_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "RoadCollision"
	add_child(collision_body)

	var up_slope: float = atan2(bridge_height, approach_length)
	var up_step: float = approach_length / float(APPROACH_RESOLUTION)
	var up_h_step: float = bridge_height / float(APPROACH_RESOLUTION)

	# Collision jalur naik
	for i in range(APPROACH_RESOLUTION):
		_add_col("BridgeUpCol_" + str(i),
			Vector3(0.0, up_h_step * (float(i) + 0.5), -up_step * (float(i) + 0.5)),
			up_slope, up_step * 1.02)

	# Collision bentangan
	var span_z_start: float = -approach_length
	var span_steps: int = 4
	var span_step_len: float = bridge_span_length / float(span_steps)
	for i in range(span_steps):
		_add_col("BridgeSpanCol_" + str(i),
			Vector3(0.0, bridge_height, span_z_start - span_step_len * (float(i) + 0.5)),
			0.0, span_step_len * 1.02)

	# Collision jalur turun
	var down_z_start: float = -(approach_length + bridge_span_length)
	var down_slope: float = atan2(-bridge_height, approach_length)
	for i in range(APPROACH_RESOLUTION):
		_add_col("BridgeDownCol_" + str(i),
			Vector3(0.0, bridge_height - up_h_step * (float(i) + 0.5),
				down_z_start - up_step * (float(i) + 0.5)),
			down_slope, up_step * 1.02)


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

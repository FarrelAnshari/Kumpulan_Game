class_name TrackUphill
extends TrackSegment

# TrackUphill: Segmen tanjakan dengan elevasi naik secara bertahap.
# Permukaan jalan miring ke atas sepanjang segmen.

@export var elevation_gain: float = 3.0  # Ketinggian yang didaki (meter)

const SLOPE_RESOLUTION: int = 8  # Jumlah sub-segmen pembentuk tanjakan


func _ready() -> void:
	segment_type = SegmentType.UPHILL
	super._ready()


func _calculate_connection_points() -> void:
	entry_point = Vector3.ZERO
	entry_forward = Vector3(0.0, 0.0, -1.0)

	exit_point = Vector3(0.0, elevation_gain, -segment_length)
	# Arah keluar tetap mendatar (kendaraan akan menyesuaikan elevasi)
	exit_forward = Vector3(0.0, 0.0, -1.0)


func _build_segment_geometry() -> void:
	var asphalt_mat: StandardMaterial3D = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.22, 0.22, 0.25, 1.0)
	asphalt_mat.roughness = 0.7

	var shoulder_mat: StandardMaterial3D = StandardMaterial3D.new()
	shoulder_mat.albedo_color = Color(0.45, 0.38, 0.35, 1.0)
	shoulder_mat.roughness = 0.8

	var line_mat: StandardMaterial3D = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.95, 0.95, 0.95, 1.0)
	line_mat.roughness = 0.4

	var step_len: float = segment_length / float(SLOPE_RESOLUTION)
	var step_height: float = elevation_gain / float(SLOPE_RESOLUTION)
	var slope_angle: float = atan2(elevation_gain, segment_length)

	for i in range(SLOPE_RESOLUTION):
		var z_pos: float = -step_len * (float(i) + 0.5)
		var y_pos: float = step_height * (float(i) + 0.5)

		# Aspal miring
		var road_piece: MeshInstance3D = MeshInstance3D.new()
		road_piece.name = "UphillRoad_" + str(i)
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(ROAD_WIDTH, ROAD_THICKNESS, step_len * 1.02)
		box.material = asphalt_mat
		road_piece.mesh = box
		road_piece.position = Vector3(0.0, y_pos, z_pos)
		road_piece.rotation.x = slope_angle
		add_child(road_piece)

		# Bahu
		for side in [-1.0, 1.0]:
			var shoulder: MeshInstance3D = MeshInstance3D.new()
			shoulder.name = "UphillShoulder_" + str(i) + "_" + ("L" if side < 0 else "R")
			var sbox: BoxMesh = BoxMesh.new()
			sbox.size = Vector3(SHOULDER_WIDTH, ROAD_THICKNESS * 0.85, step_len * 1.02)
			sbox.material = shoulder_mat
			shoulder.mesh = sbox
			shoulder.position = Vector3(
				side * (ROAD_WIDTH * 0.5 + SHOULDER_WIDTH * 0.5), y_pos, z_pos
			)
			shoulder.rotation.x = slope_angle
			add_child(shoulder)

		# Garis marka
		var line_x_positions: Array[float] = [
			-ROAD_WIDTH * 0.5, -LANE_WIDTH * 0.5,
			LANE_WIDTH * 0.5, ROAD_WIDTH * 0.5,
		]
		for lx in range(line_x_positions.size()):
			var line_piece: MeshInstance3D = MeshInstance3D.new()
			line_piece.name = "UphillLine_" + str(i) + "_" + str(lx)
			var lbox: BoxMesh = BoxMesh.new()
			lbox.size = Vector3(LINE_WIDTH, ROAD_THICKNESS + LINE_HEIGHT_OFFSET, step_len * 1.02)
			lbox.material = line_mat
			line_piece.mesh = lbox
			line_piece.position = Vector3(line_x_positions[lx], y_pos + LINE_HEIGHT_OFFSET, z_pos)
			line_piece.rotation.x = slope_angle
			add_child(line_piece)


func _build_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "RoadCollision"
	add_child(collision_body)

	var step_len: float = segment_length / float(SLOPE_RESOLUTION)
	var step_height: float = elevation_gain / float(SLOPE_RESOLUTION)
	var slope_angle: float = atan2(elevation_gain, segment_length)

	for i in range(SLOPE_RESOLUTION):
		var z_pos: float = -step_len * (float(i) + 0.5)
		var y_pos: float = step_height * (float(i) + 0.5)

		var shape_node: CollisionShape3D = CollisionShape3D.new()
		shape_node.name = "UphillCollision_" + str(i)
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(TOTAL_WIDTH, ROAD_THICKNESS, step_len * 1.02)
		shape_node.shape = shape
		shape_node.position = Vector3(0.0, y_pos, z_pos)
		shape_node.rotation.x = slope_angle
		collision_body.add_child(shape_node)

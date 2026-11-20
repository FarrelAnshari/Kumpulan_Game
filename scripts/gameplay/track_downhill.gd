class_name TrackDownhill
extends TrackSegment

# TrackDownhill: Segmen turunan dengan elevasi menurun secara bertahap.
# Kebalikan dari TrackUphill.

@export var elevation_drop: float = 3.0  # Ketinggian yang diturunkan (meter)

const SLOPE_RESOLUTION: int = 8


func _ready() -> void:
	segment_type = SegmentType.DOWNHILL
	super._ready()


func _calculate_connection_points() -> void:
	entry_point = Vector3.ZERO
	entry_forward = Vector3(0.0, 0.0, -1.0)

	exit_point = Vector3(0.0, -elevation_drop, -segment_length)
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

	# Turunan lurus adalah satu bidang miring kontinu dari entry ke exit
	var slope_len: float = sqrt(segment_length * segment_length + elevation_drop * elevation_drop)
	var slope_angle: float = atan2(-elevation_drop, segment_length)
	var mid_pos: Vector3 = Vector3(0.0, -elevation_drop * 0.5, -segment_length * 0.5)

	# 1. Aspal turunan kontinu tunggal (tanpa sambungan internal)
	var road_piece: MeshInstance3D = MeshInstance3D.new()
	road_piece.name = "DownhillRoadSurface"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(ROAD_WIDTH, ROAD_THICKNESS, slope_len)
	box.material = asphalt_mat
	road_piece.mesh = box
	road_piece.position = mid_pos
	road_piece.rotation.x = slope_angle
	add_child(road_piece)

	# 2. Bahu kiri dan kanan kontinu tunggal
	for side in [-1.0, 1.0]:
		var shoulder: MeshInstance3D = MeshInstance3D.new()
		shoulder.name = "DownhillShoulder_" + ("L" if side < 0 else "R")
		var sbox: BoxMesh = BoxMesh.new()
		sbox.size = Vector3(SHOULDER_WIDTH, ROAD_THICKNESS * 0.85, slope_len)
		sbox.material = shoulder_mat
		shoulder.mesh = sbox
		shoulder.position = mid_pos + Vector3(side * (ROAD_WIDTH * 0.5 + SHOULDER_WIDTH * 0.5), 0.0, 0.0)
		shoulder.rotation.x = slope_angle
		add_child(shoulder)

	# 3. Garis marka 3 lajur kontinu tunggal
	var line_x_positions: Array[float] = [
		-ROAD_WIDTH * 0.5, -LANE_WIDTH * 0.5,
		LANE_WIDTH * 0.5, ROAD_WIDTH * 0.5,
	]
	for lx in range(line_x_positions.size()):
		var line_piece: MeshInstance3D = MeshInstance3D.new()
		line_piece.name = "DownhillLine_" + str(lx)
		var lbox: BoxMesh = BoxMesh.new()
		lbox.size = Vector3(LINE_WIDTH, ROAD_THICKNESS + LINE_HEIGHT_OFFSET, slope_len)
		lbox.material = line_mat
		line_piece.mesh = lbox
		line_piece.position = mid_pos + Vector3(line_x_positions[lx], LINE_HEIGHT_OFFSET, 0.0)
		line_piece.rotation.x = slope_angle
		add_child(line_piece)


func _build_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "RoadCollision"
	add_child(collision_body)

	var slope_len: float = sqrt(segment_length * segment_length + elevation_drop * elevation_drop)
	var slope_angle: float = atan2(-elevation_drop, segment_length)
	var mid_pos: Vector3 = Vector3(0.0, -elevation_drop * 0.5, -segment_length * 0.5)

	var shape_node: CollisionShape3D = CollisionShape3D.new()
	shape_node.name = "DownhillCollisionShape"
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(TOTAL_WIDTH, ROAD_THICKNESS, slope_len)
	shape_node.shape = shape
	shape_node.position = mid_pos
	shape_node.rotation.x = slope_angle
	collision_body.add_child(shape_node)


## Menghitung posisi dan orientasi lokal di sepanjang turunan
func get_local_transform_at_distance(dist: float, lane_offset: float = 0.0) -> Transform3D:
	var clamped_dist: float = clampf(dist, 0.0, segment_length)
	var t: float = clamped_dist / maxf(0.001, segment_length)
	var slope_angle: float = atan2(-elevation_drop, segment_length)
	var pos: Vector3 = Vector3(lane_offset, -elevation_drop * t + ROAD_THICKNESS * 0.5, -clamped_dist)
	var forward: Vector3 = Vector3(0.0, sin(slope_angle), -cos(slope_angle)).normalized()
	var up: Vector3 = Vector3(0.0, cos(slope_angle), sin(slope_angle)).normalized()
	var basis: Basis = Basis.looking_at(forward, up)
	return Transform3D(basis, pos)

class_name TrackCurveLeft
extends TrackSegment

# TrackCurveLeft: Segmen belok kiri menggunakan pendekatan arc (busur).
# Jalan melengkung ke kiri dengan sudut tertentu.

@export var curve_angle_deg: float = 30.0  # Sudut belok dalam derajat
@export var curve_radius: float = 40.0     # Jari-jari belok (meter)

const ARC_RESOLUTION: int = 12  # Jumlah sub-segmen pembentuk kurva


func _ready() -> void:
	segment_type = SegmentType.CURVE_LEFT
	# Panjang busur = radius × sudut (radian)
	segment_length = curve_radius * deg_to_rad(curve_angle_deg)
	super._ready()


func _calculate_connection_points() -> void:
	entry_point = Vector3.ZERO
	entry_forward = Vector3(0.0, 0.0, -1.0)

	# Titik keluar dihitung berdasarkan geometri busur
	var angle_rad: float = deg_to_rad(curve_angle_deg)
	# Pusat lingkaran belok ada di kiri (sumbu -X dari entry)
	# Exit point = rotasi entry_point mengelilingi pusat lingkaran
	var center: Vector3 = Vector3(-curve_radius, 0.0, 0.0)
	var exit_offset: Vector3 = Vector3(curve_radius, 0.0, 0.0)
	exit_offset = exit_offset.rotated(Vector3.UP, -angle_rad)
	exit_point = center + exit_offset
	exit_forward = Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, -angle_rad)


func _build_segment_geometry() -> void:
	_build_curved_road()


func _build_curved_road() -> void:
	var angle_rad: float = deg_to_rad(curve_angle_deg)
	var center: Vector3 = Vector3(-curve_radius, 0.0, 0.0)
	var step_angle: float = angle_rad / float(ARC_RESOLUTION)
	var step_length: float = segment_length / float(ARC_RESOLUTION)

	var asphalt_mat: StandardMaterial3D = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.22, 0.22, 0.25, 1.0)
	asphalt_mat.roughness = 0.7

	var shoulder_mat: StandardMaterial3D = StandardMaterial3D.new()
	shoulder_mat.albedo_color = Color(0.45, 0.38, 0.35, 1.0)
	shoulder_mat.roughness = 0.8

	var line_mat: StandardMaterial3D = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.95, 0.95, 0.95, 1.0)
	line_mat.roughness = 0.4

	for i in range(ARC_RESOLUTION):
		var angle_start: float = step_angle * float(i)
		var angle_mid: float = step_angle * (float(i) + 0.5)

		# Posisi tengah dari sub-segmen
		var offset: Vector3 = Vector3(curve_radius, 0.0, 0.0).rotated(Vector3.UP, -angle_mid)
		var pos: Vector3 = center + offset
		var rot_y: float = -angle_mid

		# Aspal sub-segmen
		var road_piece: MeshInstance3D = MeshInstance3D.new()
		road_piece.name = "CurveRoad_" + str(i)
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(ROAD_WIDTH, ROAD_THICKNESS, step_length * 1.05)
		box.material = asphalt_mat
		road_piece.mesh = box
		road_piece.position = pos
		road_piece.rotation.y = rot_y
		add_child(road_piece)

		# Bahu kiri dan kanan
		for side in [-1.0, 1.0]:
			var shoulder: MeshInstance3D = MeshInstance3D.new()
			shoulder.name = "CurveShoulder_" + str(i) + "_" + ("L" if side < 0 else "R")
			var sbox: BoxMesh = BoxMesh.new()
			sbox.size = Vector3(SHOULDER_WIDTH, ROAD_THICKNESS * 0.85, step_length * 1.05)
			sbox.material = shoulder_mat
			shoulder.mesh = sbox

			var local_offset: Vector3 = Vector3(side * (ROAD_WIDTH * 0.5 + SHOULDER_WIDTH * 0.5), 0.0, 0.0)
			local_offset = local_offset.rotated(Vector3.UP, rot_y)
			shoulder.position = pos + local_offset
			shoulder.rotation.y = rot_y
			add_child(shoulder)

		# Garis pembatas & pembagi
		var line_x_positions: Array[float] = [
			-ROAD_WIDTH * 0.5,  # Tepi kiri
			-LANE_WIDTH * 0.5,  # Pembagi lajur kiri-tengah
			LANE_WIDTH * 0.5,   # Pembagi lajur tengah-kanan
			ROAD_WIDTH * 0.5,   # Tepi kanan
		]
		for lx in range(line_x_positions.size()):
			var line_piece: MeshInstance3D = MeshInstance3D.new()
			line_piece.name = "CurveLine_" + str(i) + "_" + str(lx)
			var lbox: BoxMesh = BoxMesh.new()
			lbox.size = Vector3(LINE_WIDTH, ROAD_THICKNESS + LINE_HEIGHT_OFFSET, step_length * 1.05)
			lbox.material = line_mat
			line_piece.mesh = lbox

			var loffset: Vector3 = Vector3(line_x_positions[lx], LINE_HEIGHT_OFFSET, 0.0)
			loffset = loffset.rotated(Vector3.UP, rot_y)
			line_piece.position = pos + loffset
			line_piece.rotation.y = rot_y
			add_child(line_piece)


func _build_collision() -> void:
	var angle_rad: float = deg_to_rad(curve_angle_deg)
	var center: Vector3 = Vector3(-curve_radius, 0.0, 0.0)
	var step_angle: float = angle_rad / float(ARC_RESOLUTION)
	var step_length: float = segment_length / float(ARC_RESOLUTION)

	collision_body = StaticBody3D.new()
	collision_body.name = "RoadCollision"
	add_child(collision_body)

	for i in range(ARC_RESOLUTION):
		var angle_mid: float = step_angle * (float(i) + 0.5)
		var offset: Vector3 = Vector3(curve_radius, 0.0, 0.0).rotated(Vector3.UP, -angle_mid)
		var pos: Vector3 = center + offset

		var shape_node: CollisionShape3D = CollisionShape3D.new()
		shape_node.name = "CurveCollision_" + str(i)
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(TOTAL_WIDTH, ROAD_THICKNESS, step_length * 1.05)
		shape_node.shape = shape
		shape_node.position = pos
		shape_node.rotation.y = -angle_mid
		collision_body.add_child(shape_node)

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
	exit_offset = exit_offset.rotated(Vector3.UP, angle_rad)
	exit_point = center + exit_offset
	exit_forward = Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, angle_rad)


func _build_segment_geometry() -> void:
	_build_curved_road()


func _build_curved_road() -> void:
	var asphalt_mat: StandardMaterial3D = StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color(0.22, 0.22, 0.25, 1.0)
	asphalt_mat.roughness = 0.7
	asphalt_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var shoulder_mat: StandardMaterial3D = StandardMaterial3D.new()
	shoulder_mat.albedo_color = Color(0.45, 0.38, 0.35, 1.0)
	shoulder_mat.roughness = 0.8
	shoulder_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var line_mat: StandardMaterial3D = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.95, 0.95, 0.95, 1.0)
	line_mat.roughness = 0.4
	line_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var y_top: float = ROAD_THICKNESS * 0.5
	var y_bottom: float = -ROAD_THICKNESS * 0.5
	var y_line: float = y_top + LINE_HEIGHT_OFFSET

	# 1. Permukaan aspal kontinu (Road Surface)
	var st_road: SurfaceTool = SurfaceTool.new()
	st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_road.set_material(asphalt_mat)
	_add_ribbon_quads(st_road, -ROAD_WIDTH * 0.5, ROAD_WIDTH * 0.5, y_top)
	st_road.generate_normals()
	road_mesh = MeshInstance3D.new()
	road_mesh.name = "ContinuousRoadSurface"
	road_mesh.mesh = st_road.commit()
	add_child(road_mesh)

	# 2. Bahu jalan kiri & kanan serta tepi samping (Shoulders & Side Skirts)
	var st_shoulder: SurfaceTool = SurfaceTool.new()
	st_shoulder.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_shoulder.set_material(shoulder_mat)
	# Bahu kiri
	_add_ribbon_quads(st_shoulder, -TOTAL_WIDTH * 0.5, -ROAD_WIDTH * 0.5, y_top)
	# Bahu kanan
	_add_ribbon_quads(st_shoulder, ROAD_WIDTH * 0.5, TOTAL_WIDTH * 0.5, y_top)
	# Tepi samping kiri (vertical skirt)
	_add_vertical_skirt(st_shoulder, -TOTAL_WIDTH * 0.5, y_top, y_bottom, true)
	# Tepi samping kanan (vertical skirt)
	_add_vertical_skirt(st_shoulder, TOTAL_WIDTH * 0.5, y_top, y_bottom, false)
	st_shoulder.generate_normals()
	var shoulder_mesh: MeshInstance3D = MeshInstance3D.new()
	shoulder_mesh.name = "ContinuousShoulders"
	shoulder_mesh.mesh = st_shoulder.commit()
	add_child(shoulder_mesh)

	# 3. Garis marka 3 lajur kontinu (Lane Markings)
	var st_lines: SurfaceTool = SurfaceTool.new()
	st_lines.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_lines.set_material(line_mat)

	var line_centers: Array[float] = [
		-ROAD_WIDTH * 0.5,  # Tepi kiri
		-LANE_WIDTH * 0.5,  # Pembagi kiri-tengah
		LANE_WIDTH * 0.5,   # Pembagi tengah-kanan
		ROAD_WIDTH * 0.5,   # Tepi kanan
	]
	var half_lw: float = LINE_WIDTH * 0.5
	for cx in line_centers:
		_add_ribbon_quads(st_lines, cx - half_lw, cx + half_lw, y_line)

	st_lines.generate_normals()
	var lines_mesh: MeshInstance3D = MeshInstance3D.new()
	lines_mesh.name = "ContinuousLaneMarkings"
	lines_mesh.mesh = st_lines.commit()
	add_child(lines_mesh)


## Membangun quad strip melengkung yang mulus dan tanpa celah antar-simpul
func _add_ribbon_quads(st: SurfaceTool, x_left: float, x_right: float, y: float) -> void:
	var angle_rad: float = deg_to_rad(curve_angle_deg)
	var step_angle: float = angle_rad / float(ARC_RESOLUTION)

	for i in range(ARC_RESOLUTION):
		var a0: float = step_angle * float(i)
		var a1: float = step_angle * float(i + 1)

		var p0: Vector3 = _get_curve_point(a0, x_left, y)
		var p1: Vector3 = _get_curve_point(a0, x_right, y)
		var p2: Vector3 = _get_curve_point(a1, x_left, y)
		var p3: Vector3 = _get_curve_point(a1, x_right, y)

		# 2 segitiga membentuk quad dengan normal menghadap ke atas (+Y)
		st.add_vertex(p0)
		st.add_vertex(p2)
		st.add_vertex(p1)

		st.add_vertex(p1)
		st.add_vertex(p2)
		st.add_vertex(p3)


## Menambahkan tepi samping vertikal pada pinggir luar bahu jalan
func _add_vertical_skirt(st: SurfaceTool, x: float, y_top: float, y_bottom: float, is_left: bool) -> void:
	var angle_rad: float = deg_to_rad(curve_angle_deg)
	var step_angle: float = angle_rad / float(ARC_RESOLUTION)

	for i in range(ARC_RESOLUTION):
		var a0: float = step_angle * float(i)
		var a1: float = step_angle * float(i + 1)

		var t0: Vector3 = _get_curve_point(a0, x, y_top)
		var t1: Vector3 = _get_curve_point(a1, x, y_top)
		var b0: Vector3 = _get_curve_point(a0, x, y_bottom)
		var b1: Vector3 = _get_curve_point(a1, x, y_bottom)

		if is_left:
			# Normal menghadap ke luar kiri (-X)
			st.add_vertex(t0)
			st.add_vertex(t1)
			st.add_vertex(b0)

			st.add_vertex(t1)
			st.add_vertex(b1)
			st.add_vertex(b0)
		else:
			# Normal menghadap ke luar kanan (+X)
			st.add_vertex(t0)
			st.add_vertex(b0)
			st.add_vertex(t1)

			st.add_vertex(t1)
			st.add_vertex(b0)
			st.add_vertex(b1)


## Menghitung koordinat 3D titik kurva berdasarkan sudut dan offset lateral
func _get_curve_point(angle: float, lateral_x: float, y: float) -> Vector3:
	var center: Vector3 = Vector3(-curve_radius, 0.0, 0.0)
	var r: float = curve_radius + lateral_x
	var offset: Vector3 = Vector3(r, 0.0, 0.0).rotated(Vector3.UP, angle)
	return center + offset + Vector3(0.0, y, 0.0)


## Membangun collision kontinu yang presisi mengikuti permukaan jalan melengkung
func _build_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "RoadCollision"
	add_child(collision_body)

	var st_col: SurfaceTool = SurfaceTool.new()
	st_col.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Collision mencakup seluruh lebar (13.5m) dari ujung bahu kiri ke bahu kanan
	_add_ribbon_quads(st_col, -TOTAL_WIDTH * 0.5, TOTAL_WIDTH * 0.5, ROAD_THICKNESS * 0.5)
	var col_mesh: ArrayMesh = st_col.commit()

	var shape_node: CollisionShape3D = CollisionShape3D.new()
	shape_node.name = "ContinuousTrimeshCollision"
	shape_node.shape = col_mesh.create_trimesh_shape()
	collision_body.add_child(shape_node)


## Menghitung posisi dan orientasi lokal di sepanjang kurva belok kiri
func get_local_transform_at_distance(dist: float, lane_offset: float = 0.0) -> Transform3D:
	var clamped_dist: float = clampf(dist, 0.0, segment_length)
	var t: float = clamped_dist / maxf(0.001, segment_length)
	var angle_rad: float = deg_to_rad(curve_angle_deg)
	var theta: float = angle_rad * t
	var center: Vector3 = Vector3(-curve_radius, 0.0, 0.0)
	var r_lane: float = curve_radius + lane_offset
	var offset: Vector3 = Vector3(r_lane, 0.0, 0.0).rotated(Vector3.UP, theta)
	var pos: Vector3 = center + offset + Vector3(0.0, ROAD_THICKNESS * 0.5, 0.0)
	var forward: Vector3 = Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, theta)
	var up: Vector3 = Vector3.UP
	var basis: Basis = Basis.looking_at(forward, up)
	return Transform3D(basis, pos)

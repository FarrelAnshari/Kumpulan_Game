extends Node3D

# TrackTest: Scene pengujian sistem lintasan modular Fase 2.
# Menampilkan berbagai jenis segmen yang terhubung, test rig yang bergerak otomatis,
# chase camera, dan HUD diagnostik.

@onready var track_manager: TrackManager = $TrackManager
@onready var test_rig: TrackTestRig = $TrackTestRig
@onready var chase_camera: ChaseCamera = $ChaseCamera

# Referensi UI diagnostik
var lbl_track_info: Label
var lbl_camera_info: Label
var lbl_rig_info: Label
var lbl_orientation_info: Label
var lbl_segment_detail: Label

# Data urutan segmen untuk pengujian
var test_sequence: Array[Dictionary] = [
	{"type": "straight", "length": 30.0},
	{"type": "curve_left", "angle": 30.0, "radius": 40.0},
	{"type": "straight", "length": 20.0},
	{"type": "uphill", "length": 20.0, "elevation": 3.0},
	{"type": "straight", "length": 15.0},
	{"type": "curve_right", "angle": 30.0, "radius": 40.0},
	{"type": "straight", "length": 20.0},
	{"type": "ramp", "height": 2.5, "up_length": 8.0, "flat_length": 4.0, "down_length": 8.0},
	{"type": "straight", "length": 20.0},
	{"type": "downhill", "length": 20.0, "elevation": 3.0},
	{"type": "straight", "length": 15.0},
	{"type": "bridge", "height": 4.0, "span": 24.0, "approach": 8.0},
	{"type": "straight", "length": 30.0},
]

# Touch controller (dari Fase 1)
var touch_controller: TouchController


func _ready() -> void:
	_build_environment()
	_build_track()
	_setup_test_rig()
	_setup_camera()
	_build_ui_overlay()
	_setup_touch_controller()


func _process(_delta: float) -> void:
	_update_diagnostics()


## Membangun lingkungan dasar (langit, cahaya, terrain)
func _build_environment() -> void:
	# WorldEnvironment
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.55, 0.85, 1.0)
	sky_mat.sky_horizon_color = Color(0.95, 0.75, 0.55, 1.0)
	sky_mat.ground_bottom_color = Color(0.2, 0.15, 0.1, 1.0)
	sky_mat.ground_horizon_color = Color(0.85, 0.65, 0.45, 1.0)

	var sky: Sky = Sky.new()
	sky.sky_material = sky_mat

	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.65, 0.65, 0.7, 1.0)
	env.tonemap_mode = Environment.TONE_MAP_ACES

	world_env.environment = env
	add_child(world_env)

	# DirectionalLight3D (matahari)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.transform = Transform3D(
		Basis(Vector3(0.866, -0.25, 0.433), Vector3(0.0, 0.866, 0.5), Vector3(-0.5, -0.433, 0.75)),
		Vector3(0, 15, 0)
	)
	sun.shadow_enabled = true
	add_child(sun)

	# Terrain dasar (rumput hijau)
	var terrain: MeshInstance3D = MeshInstance3D.new()
	terrain.name = "TerrainGround"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(200, 600)
	var terrain_mat: StandardMaterial3D = StandardMaterial3D.new()
	terrain_mat.albedo_color = Color(0.38, 0.58, 0.32, 1.0)
	terrain_mat.roughness = 0.9
	plane.material = terrain_mat
	terrain.mesh = plane
	terrain.position = Vector3(0.0, -0.2, -150.0)
	add_child(terrain)


## Membangun lintasan dari urutan segmen pengujian
func _build_track() -> void:
	track_manager.build_from_sequence(test_sequence)


## Menyiapkan test rig di posisi awal
func _setup_test_rig() -> void:
	test_rig.position = Vector3(0.0, TrackSegment.ROAD_THICKNESS * 0.5, 0.0)


## Menyiapkan chase camera
func _setup_camera() -> void:
	chase_camera.target = test_rig
	chase_camera._snap_to_target()


## Membangun UI overlay diagnostik (landscape-friendly)
func _build_ui_overlay() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "UIOverlay"
	add_child(canvas)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	canvas.add_child(margin)

	# Layout: informasi di kiri atas, ringkasan di kanan atas
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(hbox)

	# Panel kiri: info lintasan & kamera
	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var left_style: StyleBoxFlat = StyleBoxFlat.new()
	left_style.bg_color = Color(0.08, 0.10, 0.16, 0.85)
	left_style.corner_radius_top_left = 10
	left_style.corner_radius_top_right = 10
	left_style.corner_radius_bottom_left = 10
	left_style.corner_radius_bottom_right = 10
	left_style.content_margin_left = 12
	left_style.content_margin_top = 8
	left_style.content_margin_right = 12
	left_style.content_margin_bottom = 8
	left_panel.add_theme_stylebox_override("panel", left_style)
	hbox.add_child(left_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	left_panel.add_child(vbox)

	# Judul
	var title: Label = Label.new()
	title.text = "🛣️ FASE 2: Track System Test"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	vbox.add_child(title)

	lbl_track_info = Label.new()
	lbl_track_info.add_theme_font_size_override("font_size", 11)
	lbl_track_info.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(lbl_track_info)

	lbl_camera_info = Label.new()
	lbl_camera_info.add_theme_font_size_override("font_size", 11)
	lbl_camera_info.add_theme_color_override("font_color", Color(0.65, 0.95, 0.7))
	vbox.add_child(lbl_camera_info)

	lbl_rig_info = Label.new()
	lbl_rig_info.add_theme_font_size_override("font_size", 11)
	lbl_rig_info.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
	vbox.add_child(lbl_rig_info)

	lbl_orientation_info = Label.new()
	lbl_orientation_info.add_theme_font_size_override("font_size", 11)
	lbl_orientation_info.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	vbox.add_child(lbl_orientation_info)

	lbl_segment_detail = Label.new()
	lbl_segment_detail.add_theme_font_size_override("font_size", 11)
	lbl_segment_detail.add_theme_color_override("font_color", Color(0.9, 0.75, 0.95))
	vbox.add_child(lbl_segment_detail)

	# Hint kontrol
	var hint: Label = Label.new()
	hint.text = "Kontrol: A/D (lajur) | Swipe Kiri/Kanan | Escape (keluar)"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(hint)

	# Spacer untuk mendorong panel kiri ke atas
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)


## Memasang TouchController di layer UI
func _setup_touch_controller() -> void:
	touch_controller = TouchController.new()
	var canvas: CanvasLayer = get_node_or_null("UIOverlay")
	if canvas:
		canvas.add_child(touch_controller)
		canvas.move_child(touch_controller, 0)


## Memperbarui teks diagnostik setiap frame
func _update_diagnostics() -> void:
	if lbl_track_info == null:
		return

	# Info lintasan
	var seg_count: int = track_manager.get_segment_count()
	var total_len: float = track_manager.get_total_length()
	lbl_track_info.text = (
		"Segmen: " + str(seg_count)
		+ " | Total: " + str(snappedf(total_len, 0.1)) + "m"
	)

	# Info kamera
	var cam_pos: Vector3 = chase_camera.global_position
	lbl_camera_info.text = (
		"Kamera: X=" + str(snappedf(cam_pos.x, 0.1))
		+ " Y=" + str(snappedf(cam_pos.y, 0.1))
		+ " Z=" + str(snappedf(cam_pos.z, 0.1))
		+ " | FOV=" + str(snappedf(chase_camera.fov, 0.1)) + "°"
	)

	# Info test rig
	var rig_pos: Vector3 = test_rig.global_position
	lbl_rig_info.text = (
		"Rig: X=" + str(snappedf(rig_pos.x, 0.1))
		+ " Y=" + str(snappedf(rig_pos.y, 0.1))
		+ " Z=" + str(snappedf(rig_pos.z, 0.1))
		+ " | Lajur: " + test_rig.get_lane_name()
		+ " | Jarak: " + str(snappedf(test_rig.total_distance, 0.1)) + "m"
	)

	# Info orientasi dan viewport
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var ratio_w: float = vp_size.x / maxf(1.0, vp_size.y)
	lbl_orientation_info.text = (
		"Viewport: " + str(int(vp_size.x)) + "x" + str(int(vp_size.y))
		+ " | Rasio: " + str(snappedf(ratio_w, 0.01)) + ":1"
		+ " | Orientasi: LANDSCAPE"
	)

	# Detail segmen aktif (berdasarkan posisi Z test rig)
	var seg_names: PackedStringArray = PackedStringArray()
	for i in range(mini(seg_count, 5)):
		var seg: TrackSegment = track_manager.get_segment(i)
		if seg:
			seg_names.append(_get_segment_type_name(seg.segment_type))
	lbl_segment_detail.text = "Urutan: " + ", ".join(seg_names) + "..."


## Mendapatkan nama tipe segmen untuk tampilan
func _get_segment_type_name(seg_type: TrackSegment.SegmentType) -> String:
	match seg_type:
		TrackSegment.SegmentType.STRAIGHT: return "Lurus"
		TrackSegment.SegmentType.CURVE_LEFT: return "Belok-L"
		TrackSegment.SegmentType.CURVE_RIGHT: return "Belok-R"
		TrackSegment.SegmentType.UPHILL: return "Tanjakan"
		TrackSegment.SegmentType.DOWNHILL: return "Turunan"
		TrackSegment.SegmentType.RAMP: return "Ramp"
		TrackSegment.SegmentType.BRIDGE: return "Jembatan"
		_: return "?"

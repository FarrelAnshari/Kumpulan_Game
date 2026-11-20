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
var lbl_connection_status: Label
var lbl_input_status: Label

# Referensi kamera alternatif
var top_camera: Camera3D
var is_top_view: bool = false
var view_toggle_cooldown: float = 0.0

# Status input diagnostik
var last_action_text: String = "Belum ada input"
var action_indicator_timer: float = 0.0
var frame_count: int = 0
var screenshot_cooldown: float = 0.0

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


func _process(delta: float) -> void:
	frame_count += 1
	_handle_auto_screenshots()
	_monitor_gameplay_actions(delta)
	_update_diagnostics()


## Menangani pengambilan screenshot otomatis saat audit dijalankan
func _handle_auto_screenshots() -> void:
	var should_capture: bool = false
	for a in OS.get_cmdline_args():
		if a == "--capture-audit":
			should_capture = true
			break

	if not should_capture:
		return

	if frame_count == 10:
		_save_viewport_screenshot("screenshot_game_view.png")
		top_camera.current = true
	elif frame_count == 18:
		_save_viewport_screenshot("screenshot_top_view.png")
		top_camera.current = false
	elif frame_count == 210:
		_save_viewport_screenshot("screenshot_curve_view.png")


## Menyimpan gambar tampilan viewport ke file PNG
func _save_viewport_screenshot(filename: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var dir: String = "res://screenshots"
		var abs_dir: String = ProjectSettings.globalize_path(dir)
		DirAccess.make_dir_recursive_absolute(abs_dir)
		var abs_path: String = abs_dir + "/" + filename
		img.save_png(abs_path)
		print("📸 Screenshot berhasil disimpan ke: ", abs_path)


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
	env.tonemap_mode = Environment.TONE_MAPPER_ACES

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

	# Terrain dasar (rumput hijau) — cukup besar untuk seluruh lintasan
	var terrain: MeshInstance3D = MeshInstance3D.new()
	terrain.name = "TerrainGround"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(400, 800)
	var terrain_mat: StandardMaterial3D = StandardMaterial3D.new()
	terrain_mat.albedo_color = Color(0.38, 0.58, 0.32, 1.0)
	terrain_mat.roughness = 0.9
	plane.material = terrain_mat
	terrain.mesh = plane
	terrain.position = Vector3(0.0, -0.2, -200.0)
	add_child(terrain)


## Membangun lintasan dari urutan segmen pengujian
func _build_track() -> void:
	track_manager.build_from_sequence(test_sequence)
	# Jalankan diagnostik koneksi dan cetak ke konsol
	track_manager.print_connection_diagnostics()
	track_manager.print_path_diagnostics()


## Menyiapkan test rig di posisi awal pada lintasan
func _setup_test_rig() -> void:
	test_rig.track_manager = track_manager
	test_rig.total_distance = 0.0
	test_rig._update_transform_on_track(0.0)


## Menyiapkan chase camera dan top-view camera
func _setup_camera() -> void:
	chase_camera.target = test_rig
	chase_camera._snap_to_target()

	# Kamera pandangan atas (Top-View / Bird's Eye) untuk audit geometri lintasan
	top_camera = Camera3D.new()
	top_camera.name = "TopCamera"
	top_camera.current = false
	top_camera.fov = 75.0
	top_camera.position = Vector3(-20.0, 175.0, -135.0)
	top_camera.rotation_degrees = Vector3(-89.9, 0.0, 0.0)
	add_child(top_camera)


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

	lbl_connection_status = Label.new()
	lbl_connection_status.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl_connection_status)

	# Label status input real-time
	lbl_input_status = Label.new()
	lbl_input_status.add_theme_font_size_override("font_size", 11)
	lbl_input_status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(lbl_input_status)

	# Hint kontrol lengkap (Keyboard & Touch)
	var hint_kb: Label = Label.new()
	hint_kb.text = "🎮 Keyboard: A/D (Lajur) | Space/W (Jump) | S/Down (Slide) | V (Kamera) | F11 (Screenshot) | Esc (Keluar)"
	hint_kb.add_theme_font_size_override("font_size", 10)
	hint_kb.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	vbox.add_child(hint_kb)

	var hint_touch: Label = Label.new()
	hint_touch.text = "📱 Touch: Swipe Kiri/Kanan (Lajur) | Swipe Atas (Jump) | Swipe Bawah (Slide)"
	hint_touch.add_theme_font_size_override("font_size", 10)
	hint_touch.add_theme_color_override("font_color", Color(0.7, 0.85, 0.75))
	vbox.add_child(hint_touch)

	var hint_note: Label = Label.new()
	hint_note.text = "ℹ️ Fisika & animasi lompat/meluncur kendaraan diimplementasikan pada Fase 3."
	hint_note.add_theme_font_size_override("font_size", 9)
	hint_note.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	vbox.add_child(hint_note)

	# Spacer untuk mendorong panel kiri ke atas
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)


## Memasang TouchController di layer UI dan menghubungkan sinyal
func _setup_touch_controller() -> void:
	touch_controller = TouchController.new()
	var canvas: CanvasLayer = get_node_or_null("UIOverlay")
	if canvas:
		canvas.add_child(touch_controller)
		canvas.move_child(touch_controller, 0)
		touch_controller.swipe_detected.connect(_on_touch_swipe)
		touch_controller.tap_detected.connect(_on_touch_tap)


## Memantau aksi input gameplay (Keyboard & Touch Actions)
func _monitor_gameplay_actions(delta: float) -> void:
	if action_indicator_timer > 0.0:
		action_indicator_timer = maxf(0.0, action_indicator_timer - delta)

	if view_toggle_cooldown > 0.0:
		view_toggle_cooldown = maxf(0.0, view_toggle_cooldown - delta)

	if Input.is_physical_key_pressed(KEY_V) and view_toggle_cooldown <= 0.0:
		view_toggle_cooldown = 0.3
		toggle_camera_view()
	elif Input.is_action_just_pressed("jump"):
		_register_action("⬆️ JUMP (Lompat)", Color(1.0, 0.85, 0.2))
	elif Input.is_action_just_pressed("slide"):
		_register_action("⬇️ SLIDE (Meluncur)", Color(0.3, 0.9, 1.0))
	elif Input.is_action_just_pressed("move_left"):
		_register_action("⬅️ MOVE_LEFT (Kiri)", Color(0.5, 1.0, 0.5))
	elif Input.is_action_just_pressed("move_right"):
		_register_action("➡️ MOVE_RIGHT (Kanan)", Color(0.5, 1.0, 0.5))
	elif Input.is_action_just_pressed("pause"):
		_register_action("⏸️ PAUSE / ESCAPE (Keluar)", Color(1.0, 0.4, 0.4))
		get_tree().quit()


## Beralih antara ChaseCamera (Third-Person) dan TopCamera (Overhead)
func toggle_camera_view() -> void:
	is_top_view = !is_top_view
	if is_top_view:
		top_camera.current = true
		_register_action("📷 KAMERA: TOP-VIEW AKTIF (Bird's Eye)", Color(0.3, 0.9, 1.0))
	else:
		chase_camera.current = true
		_register_action("📷 KAMERA: CHASE CAMERA AKTIF (Third-Person)", Color(0.4, 1.0, 0.6))


## Menangani callback gestur swipe dari TouchController
func _on_touch_swipe(_dir: Vector2, action_name: String) -> void:
	match action_name:
		"jump":
			_register_action("👆 SWIPE ATAS → JUMP (Lompat)", Color(1.0, 0.85, 0.2))
		"slide":
			_register_action("👆 SWIPE BAWAH → SLIDE (Meluncur)", Color(0.3, 0.9, 1.0))
		"move_left":
			_register_action("👆 SWIPE KIRI → MOVE_LEFT (Kiri)", Color(0.5, 1.0, 0.5))
		"move_right":
			_register_action("👆 SWIPE KANAN → MOVE_RIGHT (Kanan)", Color(0.5, 1.0, 0.5))
		_:
			_register_action("👆 SWIPE: " + action_name.to_upper(), Color(0.8, 0.8, 0.9))


## Menangani callback ketukan layar dari TouchController
func _on_touch_tap(_pos: Vector2, action_name: String) -> void:
	_register_action("👆 TAP: " + action_name.to_upper(), Color(0.8, 0.8, 0.9))


## Mendaftarkan aksi yang terdeteksi dan memicu indikator visual sementara
func _register_action(action_str: String, col: Color) -> void:
	last_action_text = action_str
	action_indicator_timer = 1.5
	if lbl_input_status:
		lbl_input_status.text = "⚡ Input Terdeteksi: " + last_action_text
		lbl_input_status.add_theme_color_override("font_color", col)


## Memperbarui teks diagnostik setiap frame
func _update_diagnostics() -> void:
	if lbl_track_info == null:
		return

	# Info lintasan
	var seg_count: int = track_manager.get_segment_count()
	var total_len: float = track_manager.get_total_length()
	lbl_track_info.text = (
		"Segmen: " + str(seg_count)
		+" | Total: " + str(snappedf(total_len, 0.1)) + "m"
	)

	# Info kamera
	var active_cam: Camera3D = top_camera if (top_camera and top_camera.current) else chase_camera
	var cam_pos: Vector3 = active_cam.global_position
	var cam_mode_str: String = "TOP-VIEW" if (top_camera and top_camera.current) else "CHASE (3rd Person)"
	lbl_camera_info.text = (
		"Kamera [" + cam_mode_str + "]: X=" + str(snappedf(cam_pos.x, 0.1))
		+" Y=" + str(snappedf(cam_pos.y, 0.1))
		+" Z=" + str(snappedf(cam_pos.z, 0.1))
		+" | FOV=" + str(snappedf(active_cam.fov, 0.1)) + "°"
	)

	# Info test rig (Path Following, Orientasi, dan Lajur)
	var rig_pos: Vector3 = test_rig.global_position
	var rig_fwd: Vector3 = - test_rig.global_basis.z.normalized()
	var heading_yaw: float = rad_to_deg(atan2(rig_fwd.x, -rig_fwd.z))
	var pitch_deg: float = rad_to_deg(asin(clampf(rig_fwd.y, -1.0, 1.0)))
	var progress_pct: int = int((test_rig.total_distance / maxf(1.0, total_len)) * 100.0)

	lbl_rig_info.text = (
		"Rig: Pos=(" + str(snappedf(rig_pos.x, 0.1)) + ", " + str(snappedf(rig_pos.y, 0.1)) + ", " + str(snappedf(rig_pos.z, 0.1)) + ")"
		+" | Yaw=" + str(snappedf(heading_yaw, 0.1)) + "° Pitch=" + str(snappedf(pitch_deg, 0.1)) + "°\n"
		+"Lajur: " + test_rig.get_lane_name()
		+" | Jarak: " + str(snappedf(test_rig.total_distance, 0.1)) + "/" + str(snappedf(total_len, 0.1)) + "m (" + str(progress_pct) + "%)"
	)

	# Detail segmen aktif tempat test rig berada saat ini
	var seg_info: Dictionary = test_rig.get_current_segment_info()
	var current_seg_idx: int = seg_info.get("index", -1)
	if current_seg_idx >= 0 and current_seg_idx < seg_count:
		var current_seg: TrackSegment = track_manager.get_segment(current_seg_idx)
		var seg_name: String = _get_segment_type_name(current_seg.segment_type) if current_seg else "?"
		var local_d: float = seg_info.get("local_dist", 0.0)
		var seg_len: float = seg_info.get("segment_length", 0.0)
		lbl_segment_detail.text = (
			"🛣️ Segmen Aktif: [" + str(current_seg_idx + 1) + "/" + str(seg_count) + "] "
			+ seg_name.to_upper()
			+" | Progres Segmen: " + str(snappedf(local_d, 0.1)) + "/" + str(snappedf(seg_len, 0.1)) + "m"
		)
	else:
		lbl_segment_detail.text = "🛣️ Segmen Aktif: Menunggu data lintasan..."

	# Diagnostik koneksi
	if lbl_connection_status:
		var results: Array[Dictionary] = track_manager.validate_connections()
		var issues: int = 0
		var max_gap: float = 0.0
		for r in results:
			if r["status"] != "OK":
				issues += 1
			max_gap = maxf(max_gap, r["gap_distance"])
		if issues == 0:
			lbl_connection_status.text = (
				"✅ Koneksi: " + str(results.size()) + " sambungan OK"
				+" | Gap maks: " + str(snappedf(max_gap, 0.001)) + "m"
			)
			lbl_connection_status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			lbl_connection_status.text = (
				"❌ Koneksi: " + str(issues) + " masalah ditemukan"
				+" | Gap maks: " + str(snappedf(max_gap, 0.001)) + "m"
			)
			lbl_connection_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	# Status input terakhir
	if lbl_input_status and action_indicator_timer <= 0.0:
		if last_action_text == "Belum ada input":
			lbl_input_status.text = "🎮 Input: Menunggu aksi (Space/W/S/A/D/Swipe)..."
			lbl_input_status.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		else:
			lbl_input_status.text = "🎮 Input Terakhir: " + last_action_text
			lbl_input_status.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))


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

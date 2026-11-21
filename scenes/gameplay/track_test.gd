extends Node3D

# TrackTest: Scene pengujian sistem lintasan modular dan pergerakan pemain.
# Fase 2: Sistem lintasan modular, TrackTestRig, diagnostik koneksi.
# Fase 3: Integrasi PlayerController (Sepeda Motor + Ponco Rider), Auto-Forward, dan Smooth Lateral Movement.

@onready var track_manager: TrackManager = $TrackManager
@onready var test_rig: TrackTestRig = $TrackTestRig
@onready var player: PlayerController = $PlayerController
@onready var chase_camera: ChaseCamera = $ChaseCamera

# Referensi UI diagnostik
var lbl_title: Label
var lbl_track_info: Label
var lbl_camera_info: Label
var lbl_rig_info: Label
var lbl_orientation_info: Label
var lbl_segment_detail: Label
var lbl_connection_status: Label
var lbl_input_status: Label

# Mode aktor aktif (default: PlayerController untuk Fase 3)
var use_player: bool = true

# Referensi kamera alternatif
var top_camera: Camera3D
var side_camera: Camera3D
var is_top_view: bool = false
var view_toggle_cooldown: float = 0.0

# Status input diagnostik
var last_action_text: String = "Belum ada input"
var action_indicator_timer: float = 0.0
var frame_count: int = 0
var screenshot_cooldown: float = 0.0
var has_captured_finish: bool = false
var has_captured_apex: bool = false
var has_captured_landing: bool = false
var has_captured_slide_neutral: bool = false
var has_captured_slide_side: bool = false
var slide_side_capture_frame: int = 0
var has_captured_slide_skid: bool = false

# Data urutan segmen untuk pengujian (13 segmen modular Fase 2)
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
	_setup_player()
	_setup_test_rig()
	_setup_camera()
	_build_ui_overlay()
	_setup_touch_controller()


func _process(delta: float) -> void:
	frame_count += 1
	_handle_auto_screenshots()
	_monitor_gameplay_actions(delta)
	_update_diagnostics()


## Memasang PlayerController pada lintasan dan mereset ke posisi awal
func _setup_player() -> void:
	if player:
		player.track_manager = track_manager
		player.reset_to_start()
		print("🏍️ PlayerController berhasil diintegrasikan dengan TrackManager.")


## Menyiapkan test rig diagnostik (disembunyikan secara visual jika Player aktif)
func _setup_test_rig() -> void:
	if test_rig:
		test_rig.track_manager = track_manager
		test_rig.total_distance = 0.0
		test_rig.visible = !use_player
		test_rig.set_process(!use_player)


## Menyiapkan chase camera dan top-view camera
func _setup_camera() -> void:
	if use_player and player:
		chase_camera.set_target(player)
	elif test_rig:
		chase_camera.set_target(test_rig)
	chase_camera._snap_to_target()

	# Kamera pandangan atas (Top-View / Bird's Eye) untuk audit geometri lintasan
	top_camera = Camera3D.new()
	top_camera.name = "TopCamera"
	top_camera.current = false
	top_camera.fov = 75.0
	top_camera.position = Vector3(-20.0, 175.0, -135.0)
	top_camera.rotation_degrees = Vector3(-89.9, 0.0, 0.0)
	add_child(top_camera)

	# Kamera pandangan samping (Side-View Profile) untuk verifikasi visual slide & postur
	side_camera = Camera3D.new()
	side_camera.name = "SideCamera"
	side_camera.current = false
	side_camera.fov = 50.0
	add_child(side_camera)


## Berganti aktor aktif antara PlayerController dan TrackTestRig (Fitur Diagnostik F2/F3)
func _toggle_active_actor() -> void:
	use_player = !use_player
	if use_player and player:
		test_rig.visible = false
		test_rig.set_process(false)
		player.visible = true
		player.set_physics_process(true)
		chase_camera.set_target(player)
		_register_action("🔄 Aktor Aktif: PlayerController (Motor & Ponco)", Color(0.4, 1.0, 0.6))
	elif test_rig:
		player.visible = false
		player.set_physics_process(false)
		test_rig.visible = true
		test_rig.set_process(true)
		chase_camera.set_target(test_rig)
		_register_action("🔄 Aktor Aktif: TrackTestRig (Kotak Oranye)", Color(1.0, 0.6, 0.2))


## Menangani pengambilan screenshot otomatis saat pengujian/audit dijalankan
func _handle_auto_screenshots() -> void:
	var mode_audit: bool = false
	var mode_step2: bool = false
	var mode_step3: bool = false
	var mode_step4: bool = false

	for a in OS.get_cmdline_args():
		if a == "--capture-audit":
			mode_audit = true
		elif a == "--capture-step2":
			mode_step2 = true
		elif a == "--capture-step3":
			mode_step3 = true
		elif a == "--capture-step4":
			mode_step4 = true
		elif a == "--fast-test" and player:
			player.forward_speed = 45.0

	if mode_audit:
		if frame_count == 10:
			_save_viewport_screenshot("screenshot_game_view.png")
			top_camera.current = true
		elif frame_count == 18:
			_save_viewport_screenshot("screenshot_top_view.png")
			top_camera.current = false
		elif frame_count == 210:
			_save_viewport_screenshot("screenshot_curve_view.png")
	elif mode_step2:
		if frame_count == 10:
			_save_viewport_screenshot("step2_spawn.png")
		elif frame_count == 60:
			_save_viewport_screenshot("step2_curve.png")
		elif frame_count == 180:
			_save_viewport_screenshot("step2_bridge.png")
		if player and player.is_track_completed and not has_captured_finish:
			has_captured_finish = true
			_save_viewport_screenshot("step2_finish.png")
		if has_captured_finish and frame_count > 380:
			get_tree().quit()
	elif mode_step3:
		# Skenario pengujian terprogram untuk Step 3
		if frame_count == 10:
			_save_viewport_screenshot("step3_neutral.png")
		# Simulasi belok kiri dan miring kiri
		elif frame_count == 15:
			Input.action_press("move_left")
		elif frame_count == 40:
			_save_viewport_screenshot("step3_steer_left.png")
		# Lepas belok kiri, biarkan berada di posisi antara (intermediate)
		elif frame_count == 55:
			Input.action_release("move_left")
		elif frame_count == 70:
			_save_viewport_screenshot("step3_intermediate.png")
		# Simulasi belok kanan menuju kurva
		elif frame_count == 80:
			Input.action_press("move_right")
		elif frame_count == 120:
			_save_viewport_screenshot("step3_steer_right.png")
		# Tetap tekan kanan sampai menabrak batas jalan (Boundary Clamping)
		elif frame_count == 170:
			_save_viewport_screenshot("step3_boundary.png")
		# Kembalikan ke tengah untuk pengujian ramp / bridge
		elif frame_count == 180:
			Input.action_release("move_right")
			Input.action_press("move_left")
		elif frame_count == 235:
			Input.action_release("move_left")
		elif frame_count == 260:
			_save_viewport_screenshot("step3_ramp_lateral.png")

		if player and player.is_track_completed and not has_captured_finish:
			has_captured_finish = true
			_save_viewport_screenshot("step3_finish.png")
			print("🏁 Step 3: Player selesai menempuh seluruh lintasan dan berhenti aman.")

		if has_captured_finish and frame_count > 420:
			print("📸 Audit Step 3 selesai penuh. Menutup.")
			get_tree().quit()

	elif mode_step4:
		# Skenario pengujian berbasis kondisi & event untuk Step 4 Refinement
		if frame_count == 10:
			_save_viewport_screenshot("step4_neutral.png")

		# 1. Jump di lintasan lurus (Jarak ~15m)
		if player and player.total_distance >= 15.0 and player.total_distance < 20.0 and player.move_state == PlayerController.MoveState.NORMAL and not has_captured_apex:
			Input.action_press("jump")

		if player and player.move_state == PlayerController.MoveState.JUMPING and not has_captured_apex:
			Input.action_release("jump")
			# Tangkap tepat ketika kecepatan vertikal melintasi 0 m/s (Puncak Apex tertinggi)
			if player.jump_vertical_velocity <= 0.05 and player.jump_height >= 1.60:
				has_captured_apex = true
				_save_viewport_screenshot("step4_jump_peak.png")
				print("📸 Jump Apex Captured: Height=%.2fm, Velocity=%.2fm/s" % [player.jump_height, player.jump_vertical_velocity])

		if player and has_captured_apex and not has_captured_landing and player.move_state == PlayerController.MoveState.NORMAL:
			has_captured_landing = true
			_save_viewport_screenshot("step4_landing.png")

		# 2. Low Side-Skid Slide Netral (Jarak ~60m)
		if player and player.total_distance >= 60.0 and player.total_distance < 70.0 and player.move_state == PlayerController.MoveState.NORMAL and not has_captured_slide_neutral:
			Input.action_press("slide")

		if player and player.move_state == PlayerController.MoveState.SLIDING and not has_captured_slide_neutral:
			Input.action_release("slide")
			# Tunggu hingga postur slide penuh dan bank stabil (-18.5°)
			if player.slide_posture_t >= 0.95 and player.slide_timer <= 0.65:
				has_captured_slide_neutral = true
				_save_viewport_screenshot("step4_slide_active.png")

		# Tampak Samping (Side View Profile) saat Slide aktif penuh
		if player and player.move_state == PlayerController.MoveState.SLIDING and has_captured_slide_neutral and not has_captured_slide_side:
			if slide_side_capture_frame == 0 and side_camera:
				# Tahap 1: Aktifkan side camera dan posisikan di sisi samping pemain
				side_camera.global_position = player.global_position - player.global_basis.x * 3.5 + player.global_basis.y * 0.65 - player.global_basis.z * 0.2
				side_camera.look_at(player.global_position + player.global_basis.y * 0.45, Vector3.UP)
				side_camera.current = true
				slide_side_capture_frame = frame_count + 1
			elif slide_side_capture_frame > 0 and frame_count >= slide_side_capture_frame:
				# Tahap 2: Viewport telah merender frame dari side_camera, simpan gambar
				has_captured_slide_side = true
				_save_viewport_screenshot("step4_slide_side_view.png")
				# Kembalikan ke chase camera
				chase_camera.current = true
				print("📸 Slide Side View Profile Captured!")

		# 3. Low Side-Skid Slide Belok Kiri (Jarak ~100m)
		if player and player.total_distance >= 100.0 and player.total_distance < 110.0 and player.move_state == PlayerController.MoveState.NORMAL and not has_captured_slide_skid:
			Input.action_press("slide")
			Input.action_press("move_left")

		if player and player.move_state == PlayerController.MoveState.SLIDING and has_captured_slide_neutral and not has_captured_slide_skid:
			Input.action_release("slide")
			if player.slide_posture_t >= 0.85 and player.lateral_velocity < -1.5:
				has_captured_slide_skid = true
				_save_viewport_screenshot("step4_slide_skid_left.png")

		if player and has_captured_slide_skid and player.total_distance >= 125.0 and player.total_distance < 130.0:
			Input.action_release("move_left")

		# 4. Jump di Ramp (Jarak ~145m - Segmen 8 RAMP)
		if player and player.total_distance >= 142.0 and player.total_distance < 147.0 and player.move_state == PlayerController.MoveState.NORMAL:
			Input.action_press("jump")

		if player and player.total_distance >= 147.0 and player.move_state == PlayerController.MoveState.JUMPING:
			Input.action_release("jump")
			if player.jump_height >= 1.2:
				_save_viewport_screenshot("step4_jump_ramp.png")

		# 5. Finish di ujung lintasan (Jarak 291.9m)
		if player and player.is_track_completed and not has_captured_finish:
			has_captured_finish = true
			_save_viewport_screenshot("step4_finish.png")
			print("🏁 Step 4: Player selesai menempuh seluruh lintasan.")

		if has_captured_finish and frame_count > 450:
			print("📸 Audit Step 4 selesai penuh. Menutup.")
			get_tree().quit()
			has_captured_finish = true
			_save_viewport_screenshot("step4_finish.png")
			print("🏁 Step 4: Player selesai menempuh seluruh lintasan.")

		if has_captured_finish and frame_count > 500:
			print("📸 Audit Step 4 selesai penuh. Menutup.")
			get_tree().quit()


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

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.transform = Transform3D(
		Basis(Vector3(0.866, -0.25, 0.433), Vector3(0.0, 0.866, 0.5), Vector3(-0.5, -0.433, 0.75)),
		Vector3(0, 15, 0)
	)
	sun.shadow_enabled = true
	add_child(sun)

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
	track_manager.print_connection_diagnostics()
	track_manager.print_path_diagnostics()


## Membangun UI overlay diagnostik
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

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(hbox)

	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var left_style: StyleBoxFlat = StyleBoxFlat.new()
	left_style.bg_color = Color(0.08, 0.10, 0.16, 0.88)
	left_style.corner_radius_top_left = 10
	left_style.corner_radius_top_right = 10
	left_style.corner_radius_bottom_left = 10
	left_style.corner_radius_bottom_right = 10
	left_style.content_margin_left = 14
	left_style.content_margin_top = 10
	left_style.content_margin_right = 14
	left_style.content_margin_bottom = 10
	left_panel.add_theme_stylebox_override("panel", left_style)
	hbox.add_child(left_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	left_panel.add_child(vbox)

	title_label_setup(vbox)

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

	lbl_input_status = Label.new()
	lbl_input_status.add_theme_font_size_override("font_size", 11)
	lbl_input_status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(lbl_input_status)

	var hint_kb: Label = Label.new()
	hint_kb.text = "🎮 Keyboard: A/D (Lateral) | Space/W (Jump) | S (Slide) | R (Reset) | V (Kamera) | F11 (Screenshot) | Esc (Keluar)"
	hint_kb.add_theme_font_size_override("font_size", 10)
	hint_kb.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	vbox.add_child(hint_kb)

	var hint_note: Label = Label.new()
	hint_note.text = "📱 Touch: Swipe Kiri/Kanan (Lajur) | Swipe Atas (Jump) | Swipe Bawah (Slide)"
	hint_note.add_theme_font_size_override("font_size", 9)
	hint_note.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	vbox.add_child(hint_note)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)


func title_label_setup(vbox: VBoxContainer) -> void:
	lbl_title = Label.new()
	lbl_title.text = "🏍️ FASE 3 — STEP 4: Jump & Low Side-Skid Slide"
	lbl_title.add_theme_font_size_override("font_size", 15)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(lbl_title)


## Memasang TouchController di layer UI
func _setup_touch_controller() -> void:
	touch_controller = TouchController.new()
	var canvas: CanvasLayer = get_node_or_null("UIOverlay")
	if canvas:
		canvas.add_child(touch_controller)
		canvas.move_child(touch_controller, 0)
		touch_controller.swipe_detected.connect(_on_touch_swipe)
		touch_controller.tap_detected.connect(_on_touch_tap)


## Memantau aksi input gameplay
func _monitor_gameplay_actions(delta: float) -> void:
	if action_indicator_timer > 0.0:
		action_indicator_timer = maxf(0.0, action_indicator_timer - delta)

	if view_toggle_cooldown > 0.0:
		view_toggle_cooldown = maxf(0.0, view_toggle_cooldown - delta)

	if Input.is_physical_key_pressed(KEY_V) and view_toggle_cooldown <= 0.0:
		view_toggle_cooldown = 0.3
		toggle_camera_view()
	elif Input.is_physical_key_pressed(KEY_F10) and view_toggle_cooldown <= 0.0:
		view_toggle_cooldown = 0.3
		_toggle_active_actor()
	elif Input.is_physical_key_pressed(KEY_R) and view_toggle_cooldown <= 0.0:
		view_toggle_cooldown = 0.3
		if player:
			player.reset_to_start()
		if test_rig:
			test_rig.total_distance = 0.0
		_register_action("🔄 RESET KE AWAL LINTASAN", Color(1.0, 0.9, 0.3))
	elif Input.is_action_just_pressed("pause") or Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()


## Beralih antara ChaseCamera dan TopCamera
func toggle_camera_view() -> void:
	is_top_view = !is_top_view
	if is_top_view:
		top_camera.current = true
		_register_action("📷 KAMERA: TOP-VIEW AKTIF (Bird's Eye)", Color(0.3, 0.9, 1.0))
	else:
		chase_camera.current = true
		_register_action("📷 KAMERA: CHASE CAMERA AKTIF (Third-Person)", Color(0.4, 1.0, 0.6))


func _on_touch_swipe(_dir: Vector2, action_name: String) -> void:
	match action_name:
		"move_left":
			if player:
				player.apply_lateral_impulse(-1.0)
			_register_action("👆 SWIPE KIRI → Manuver Kiri", Color(0.4, 0.9, 1.0))
		"move_right":
			if player:
				player.apply_lateral_impulse(1.0)
			_register_action("👆 SWIPE KANAN → Manuver Kanan", Color(0.4, 0.9, 1.0))
		"jump":
			if player:
				pass  # Input sudah dikirim oleh TouchController via Input.action_press
			_register_action("👆 SWIPE ATAS → LOMPAT! 🦘", Color(1.0, 0.85, 0.2))
		"slide":
			if player:
				pass  # Input sudah dikirim oleh TouchController via Input.action_press
			_register_action("👆 SWIPE BAWAH → SLIDE! 🏂", Color(0.3, 0.9, 1.0))
		_:
			_register_action("👆 SWIPE: " + action_name.to_upper(), Color(0.8, 0.8, 0.9))


func _on_touch_tap(_pos: Vector2, action_name: String) -> void:
	match action_name:
		"move_left":
			if player:
				player.apply_lateral_impulse(-0.8)
			_register_action("👆 TAP KIRI → Manuver Kiri", Color(0.4, 0.9, 1.0))
		"move_right":
			if player:
				player.apply_lateral_impulse(0.8)
			_register_action("👆 TAP KANAN → Manuver Kanan", Color(0.4, 0.9, 1.0))
		_:
			_register_action("👆 TAP: " + action_name.to_upper(), Color(0.8, 0.8, 0.9))


func _register_action(action_str: String, col: Color) -> void:
	last_action_text = action_str
	action_indicator_timer = 1.5
	if lbl_input_status:
		lbl_input_status.text = "⚡ " + last_action_text
		lbl_input_status.add_theme_color_override("font_color", col)


## Memperbarui teks diagnostik setiap frame
func _update_diagnostics() -> void:
	if lbl_track_info == null:
		return

	var seg_count: int = track_manager.get_segment_count()
	var total_len: float = track_manager.get_total_length()
	lbl_track_info.text = (
		"Segmen: " + str(seg_count)
		+" | Total: " + str(snappedf(total_len, 0.1)) + "m"
	)

	var active_cam: Camera3D = top_camera if (top_camera and top_camera.current) else chase_camera
	var cam_pos: Vector3 = active_cam.global_position
	var cam_mode_str: String = "TOP-VIEW" if (top_camera and top_camera.current) else "CHASE (3rd Person)"
	lbl_camera_info.text = (
		"Kamera [" + cam_mode_str + "]: X=" + str(snappedf(cam_pos.x, 0.1))
		+" Y=" + str(snappedf(cam_pos.y, 0.1))
		+" Z=" + str(snappedf(cam_pos.z, 0.1))
		+" | FOV=" + str(snappedf(active_cam.fov, 0.1)) + "°"
	)

	# Info aktor aktif
	if use_player and player:
		var p_pos: Vector3 = player.global_position
		var p_fwd: Vector3 = - player.global_basis.z.normalized()
		var yaw_deg: float = rad_to_deg(atan2(p_fwd.x, -p_fwd.z))
		var pitch_deg: float = rad_to_deg(asin(clampf(p_fwd.y, -1.0, 1.0)))
		var pct: int = int((player.total_distance / maxf(1.0, total_len)) * 100.0)

		var lat_off: float = player.get_lateral_offset()
		var lat_vel: float = player.get_lateral_velocity()
		var steer_lean: float = player.get_lean_angle_deg()
		var actual_bank: float = player.get_actual_bank_deg()
		var move_state_str: String = player.get_move_state()
		var jump_h: float = player.get_jump_height()

		var lane_desc: String = "Tengah (0.0m)"
		if lat_off < -2.2:
			lane_desc = "Lajur Kiri"
		elif lat_off < -0.6:
			lane_desc = "Antara Tengah & Kiri"
		elif lat_off > 2.2:
			lane_desc = "Lajur Kanan"
		elif lat_off > 0.6:
			lane_desc = "Antara Tengah & Kanan"

		lbl_rig_info.text = (
			"Aktor: PlayerController (Sepeda Motor + Ponco)\n"
			+ "Pos=(" + str(snappedf(p_pos.x, 0.1)) + ", " + str(snappedf(p_pos.y, 0.1)) + ", " + str(snappedf(p_pos.z, 0.1)) + ")"
			+ " | Yaw=" + str(snappedf(yaw_deg, 0.1)) + "° Pitch=" + str(snappedf(pitch_deg, 0.1)) + "°\n"
			+ "Posisi: " + lane_desc + " (Offset: " + str(snappedf(lat_off, 0.01)) + "m) | Kecepatan Lat: " + str(snappedf(lat_vel, 0.1)) + "m/s\n"
			+ "Kemiringan: " + str(snappedf(actual_bank, 0.1)) + "° [VisualPivot] (Kemudi: " + str(snappedf(steer_lean, 0.1)) + "°) | Status: " + move_state_str + " | Tinggi: " + str(snappedf(jump_h, 0.01)) + "m\n"
			+ "Jarak: " + str(snappedf(player.total_distance, 0.1)) + "/" + str(snappedf(total_len, 0.1)) + "m (" + str(pct) + "%)"
		)
		lbl_rig_info.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))

		var seg_info: Dictionary = player.get_current_segment_info()
		_display_segment_detail(seg_info, seg_count)
	elif test_rig:
		var rig_pos: Vector3 = test_rig.global_position
		var rig_fwd: Vector3 = - test_rig.global_basis.z.normalized()
		var heading_yaw: float = rad_to_deg(atan2(rig_fwd.x, -rig_fwd.z))
		var pitch_deg: float = rad_to_deg(asin(clampf(rig_fwd.y, -1.0, 1.0)))
		var progress_pct: int = int((test_rig.total_distance / maxf(1.0, total_len)) * 100.0)

		lbl_rig_info.text = (
			"Aktor: TrackTestRig (Kotak Oranye - Diagnostik)\n"
			+ "Pos=(" + str(snappedf(rig_pos.x, 0.1)) + ", " + str(snappedf(rig_pos.y, 0.1)) + ", " + str(snappedf(rig_pos.z, 0.1)) + ")"
			+ " | Yaw=" + str(snappedf(heading_yaw, 0.1)) + "° Pitch=" + str(snappedf(pitch_deg, 0.1)) + "°\n"
			+ "Lajur: " + test_rig.get_lane_name()
			+ " | Jarak: " + str(snappedf(test_rig.total_distance, 0.1)) + "/" + str(snappedf(total_len, 0.1)) + "m (" + str(progress_pct) + "%)"
		)
		lbl_rig_info.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))

		var seg_info: Dictionary = test_rig.get_current_segment_info()
		_display_segment_detail(seg_info, seg_count)

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


func _display_segment_detail(seg_info: Dictionary, seg_count: int) -> void:
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

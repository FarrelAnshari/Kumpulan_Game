extends Node3D

# Bootstrap3D: Scene pengujian fondasi teknis 3D (Godot 4.7.2).
# Memverifikasi Camera3D, pencahayaan, material PBR dasar,
# lintasan 3 lajur (13,5 m), input keyboard & gesture touch, serta runtime diagnostics.

@onready var camera: Camera3D = $Camera3D
@onready var light: DirectionalLight3D = $DirectionalLight3D

# Parameter eksperimen awal kamera
const DEFAULT_HEIGHT: float = 4.5
const DEFAULT_DISTANCE: float = 9.5
const DEFAULT_TILT_DEG: float = -16.0
const DEFAULT_HFOV: float = 65.0

var current_height: float = DEFAULT_HEIGHT
var current_dist: float = DEFAULT_DISTANCE
var current_tilt: float = DEFAULT_TILT_DEG
var current_fov: float = DEFAULT_HFOV

# Label diagnostik runtime
var lbl_project_info: Label
var lbl_system_info: Label
var lbl_aspect_info: Label
var lbl_camera_info: Label
var lbl_input_status: Label
var lbl_last_action: Label

var last_action_text: String = "Belum ada input"
var touch_controller: TouchController


func _ready() -> void:
	_apply_camera_params()
	_build_ui_overlay()
	_setup_touch_controller()


func _process(delta: float) -> void:
	_handle_interactive_camera_tuning(delta)
	_monitor_gameplay_actions()
	_update_ui_diagnostics()


## Menerapkan parameter kamera 3D
func _apply_camera_params() -> void:
	if camera == null:
		return
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = current_fov
	camera.position = Vector3(0.0, current_height, current_dist)
	camera.rotation_degrees = Vector3(current_tilt, 0.0, 0.0)


## Penyesuaian interaktif saat pengujian di editor (Q/E, Panah, R/F, Z/C, Home)
func _handle_interactive_camera_tuning(delta: float) -> void:
	var changed: bool = false
	var speed: float = 4.0 * delta

	# Tinggi kamera (Q/E)
	if Input.is_key_pressed(KEY_Q):
		current_height += speed
		changed = true
	elif Input.is_key_pressed(KEY_E):
		current_height = maxf(1.5, current_height - speed)
		changed = true

	# Jarak kamera (Panah Atas / Bawah)
	if Input.is_key_pressed(KEY_UP):
		current_dist = maxf(4.0, current_dist - speed)
		changed = true
	elif Input.is_key_pressed(KEY_DOWN):
		current_dist += speed
		changed = true

	# Sudut tilt kamera (R/F)
	if Input.is_key_pressed(KEY_R):
		current_tilt = minf(-5.0, current_tilt + 15.0 * delta)
		changed = true
	elif Input.is_key_pressed(KEY_F):
		current_tilt = maxf(-45.0, current_tilt - 15.0 * delta)
		changed = true

	# FOV (Z/C)
	if Input.is_key_pressed(KEY_Z):
		current_fov = maxf(40.0, current_fov - 20.0 * delta)
		changed = true
	elif Input.is_key_pressed(KEY_C):
		current_fov = minf(90.0, current_fov + 20.0 * delta)
		changed = true

	# Reset Kamera (khusus tombol Home)
	if Input.is_physical_key_pressed(KEY_HOME):
		reset_camera()
		changed = true

	if changed:
		_apply_camera_params()


## Mengembalikan nilai kamera ke parameter default awal
func reset_camera() -> void:
	current_height = DEFAULT_HEIGHT
	current_dist = DEFAULT_DISTANCE
	current_tilt = DEFAULT_TILT_DEG
	current_fov = DEFAULT_HFOV
	_apply_camera_params()


## Memantau aksi input gameplay secara real-time
func _monitor_gameplay_actions() -> void:
	if Input.is_action_just_pressed("move_left"):
		last_action_text = "⬅️ MOVE_LEFT (Kiri)"
	elif Input.is_action_just_pressed("move_right"):
		last_action_text = "➡️ MOVE_RIGHT (Kanan)"
	elif Input.is_action_just_pressed("jump"):
		last_action_text = "⬆️ JUMP (Lompat)"
	elif Input.is_action_just_pressed("slide"):
		last_action_text = "⬇️ SLIDE (Meluncur)"


## Membuat UI overlay diagnostik
func _build_ui_overlay() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "UIOverlay"
	add_child(canvas)

	# Margin container untuk panel info di atas
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 24)
	canvas.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# Panel Kartu Informasi Diagnostik
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.16, 0.90)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	vbox.add_child(panel)

	var pbox: VBoxContainer = VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 4)
	panel.add_child(pbox)

	lbl_project_info = Label.new()
	var proj_name: String = str(ProjectSettings.get_setting("application/config/name", "SepedaPetualang"))
	var engine_ver: String = Engine.get_version_info().string
	lbl_project_info.text = "🚲 " + proj_name + " | Godot " + engine_ver
	lbl_project_info.add_theme_font_size_override("font_size", 16)
	lbl_project_info.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	pbox.add_child(lbl_project_info)

	lbl_system_info = Label.new()
	var physics_eng: String = str(ProjectSettings.get_setting("physics/3d/physics_engine", "Default"))
	var render_method: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility"))
	lbl_system_info.text = "Physics: " + physics_eng + " | Renderer: " + render_method
	lbl_system_info.add_theme_font_size_override("font_size", 12)
	lbl_system_info.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	pbox.add_child(lbl_system_info)

	lbl_aspect_info = Label.new()
	lbl_aspect_info.add_theme_font_size_override("font_size", 12)
	lbl_aspect_info.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	pbox.add_child(lbl_aspect_info)

	lbl_camera_info = Label.new()
	lbl_camera_info.add_theme_font_size_override("font_size", 12)
	lbl_camera_info.add_theme_color_override("font_color", Color(0.65, 0.95, 0.7))
	pbox.add_child(lbl_camera_info)

	lbl_input_status = Label.new()
	var has_left: bool = InputMap.has_action("move_left")
	var has_right: bool = InputMap.has_action("move_right")
	var has_jump: bool = InputMap.has_action("jump")
	var has_slide: bool = InputMap.has_action("slide")
	lbl_input_status.text = "InputMap: L:" + str(has_left) + " R:" + str(has_right) + " J:" + str(has_jump) + " S:" + str(has_slide)
	lbl_input_status.add_theme_font_size_override("font_size", 12)
	lbl_input_status.add_theme_color_override("font_color", Color(0.9, 0.75, 0.95))
	pbox.add_child(lbl_input_status)

	lbl_last_action = Label.new()
	lbl_last_action.text = "Input Terakhir: " + last_action_text
	lbl_last_action.add_theme_font_size_override("font_size", 14)
	lbl_last_action.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
	pbox.add_child(lbl_last_action)

	var hint: Label = Label.new()
	hint.text = "Uji Kamera: [Q/E] Tinggi | [Panah] Jarak | [R/F] Tilt | [Z/C] FOV\nUji Kontrol: A/D (Lajur), Space/W (Lompat), S (Slide), atau Swipe Touch"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	pbox.add_child(hint)

	var btn_reset: Button = Button.new()
	btn_reset.text = "🔄 Reset Kamera [Home]"
	btn_reset.custom_minimum_size = Vector2(0, 32)
	btn_reset.add_theme_font_size_override("font_size", 12)
	btn_reset.pressed.connect(reset_camera)
	pbox.add_child(btn_reset)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var footer: Label = Label.new()
	footer.text = "✓ Lintasan 13,5 m (3 Lajur @ 3,5m + Bahu 2x 1,5m)\n✓ Fondasi 3D Siap Masuk Fase 2"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	vbox.add_child(footer)


## Memasang TouchController di layer UI agar merespons swipe & tap
func _setup_touch_controller() -> void:
	touch_controller = TouchController.new()
	var canvas: CanvasLayer = get_node_or_null("UIOverlay")
	if canvas:
		# Tempatkan di indeks 0 agar berada di latar belakang tombol UI
		canvas.add_child(touch_controller)
		canvas.move_child(touch_controller, 0)
		touch_controller.swipe_detected.connect(_on_touch_swipe)
		touch_controller.tap_detected.connect(_on_touch_tap)


func _on_touch_swipe(_dir: Vector2, action_name: String) -> void:
	last_action_text = "👆 SWIPE: " + action_name.to_upper()


func _on_touch_tap(_pos: Vector2, action_name: String) -> void:
	last_action_text = "👆 TAP: " + action_name.to_upper()


## Memperbarui teks diagnostik viewport & kamera
func _update_ui_diagnostics() -> void:
	if lbl_aspect_info == null or lbl_camera_info == null:
		return

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var ratio: float = vp_size.y / maxf(1.0, vp_size.x)
	var ratio_name: String = "16:9 (~1.78)"
	if ratio > 2.1:
		ratio_name = "20:9 / 20.5:9 (~2.2)"
	elif ratio > 1.9:
		ratio_name = "18:9 / 19.5:9 (~2.0)"

	lbl_aspect_info.text = (
		"Viewport: " + str(int(vp_size.x)) + "x" + str(int(vp_size.y))
		+ " | Rasio: " + ratio_name
	)

	lbl_camera_info.text = (
		"Kamera: HFOV " + str(snappedf(current_fov, 0.1)) + "°"
		+ " | Y=" + str(snappedf(current_height, 0.1)) + "m"
		+ " | Z=" + str(snappedf(current_dist, 0.1)) + "m"
		+ " | Tilt=" + str(snappedf(current_tilt, 0.1)) + "°"
	)

	if lbl_last_action:
		lbl_last_action.text = "Input Terakhir: " + last_action_text

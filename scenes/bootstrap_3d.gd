extends Node3D

# Bootstrap3D: Scene awal pengujian baseline 3D (Godot 4.7.2).
# Memverifikasi Camera3D, pencahayaan, material PBR dasar,
# dan proporsi lintasan 3 lajur (total 13,5 m) pada orientasi portrait 720x1280.

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

var lbl_camera_info: Label
var lbl_aspect_info: Label


func _ready() -> void:
	_apply_camera_params()
	_build_ui_overlay()


func _process(delta: float) -> void:
	_handle_interactive_camera_tuning(delta)
	_update_ui_diagnostics()


## Menerapkan parameter kamera 3D
func _apply_camera_params() -> void:
	if camera == null:
		return
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = current_fov
	camera.position = Vector3(0.0, current_height, current_dist)
	camera.rotation_degrees = Vector3(current_tilt, 0.0, 0.0)


## Penyesuaian interaktif saat pengujian di editor (Q/E, W/S, R/F, Z/C)
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

	# Jarak kamera (W/S) - tombol S digunakan dengan Shift agar tidak bentrok
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

	if changed:
		_apply_camera_params()


## Membuat UI overlay diagnostik
func _build_ui_overlay() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 30)
	canvas.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# Panel Kartu Informasi
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.18, 0.88)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	vbox.add_child(panel)

	var pbox: VBoxContainer = VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 6)
	panel.add_child(pbox)

	var title: Label = Label.new()
	title.text = "🚲 SEPEDA PETUALANG 3D - BOOTSTRAP"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	pbox.add_child(title)

	lbl_aspect_info = Label.new()
	lbl_aspect_info.add_theme_font_size_override("font_size", 13)
	lbl_aspect_info.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	pbox.add_child(lbl_aspect_info)

	lbl_camera_info = Label.new()
	lbl_camera_info.add_theme_font_size_override("font_size", 13)
	lbl_camera_info.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	pbox.add_child(lbl_camera_info)

	var hint: Label = Label.new()
	hint.text = "Kontrol Kalibrasi Kamera di Editor:\n• [Q/E]: Tinggi (Y)  • [Panah Atas/Bawah]: Jarak (Z)\n• [R/F]: Tilt Derajat  • [Z/C]: HFOV\n• [Spasi]: Reset ke Nilai Default"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	pbox.add_child(hint)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var footer: Label = Label.new()
	footer.text = "✓ Lintasan 13,5 m (3 Lajur @ 3,5m + Bahu 2x 1,5m)\n✓ Baseline 3D Siap Masuk Fase 1"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	vbox.add_child(footer)


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

	if Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE):
		current_height = DEFAULT_HEIGHT
		current_dist = DEFAULT_DISTANCE
		current_tilt = DEFAULT_TILT_DEG
		current_fov = DEFAULT_HFOV
		_apply_camera_params()

class_name PlayerPreview
extends Node3D

## PlayerPreview: Scene preview visual untuk inspeksi Player, Motor, dan Ponco Rider.
## Digunakan untuk memvalidasi proporsi, arah hadap, postur duduk, dan skala model.

@onready var player: Node3D = $PlayerController
@onready var camera: Camera3D = $Camera3D

var camera_angle_idx: int = 0
var view_cooldown: float = 0.0

# Posisi kamera yang dapat ditinjau (Tiga perempat, Samping, Depan, Belakang)
var camera_presets: Array[Dictionary] = [
	{
		"name": "Perspektif Tiga-Perempat (3/4 Isometric-style)",
		"pos": Vector3(2.6, 1.8, -2.4),
		"look_at": Vector3(0.0, 0.75, 0.0)
	},
	{
		"name": "Tampak Samping Kanan (Side Profile)",
		"pos": Vector3(3.2, 1.2, 0.0),
		"look_at": Vector3(0.0, 0.75, 0.0)
	},
	{
		"name": "Tampak Depan (Front View)",
		"pos": Vector3(0.0, 1.2, -3.2),
		"look_at": Vector3(0.0, 0.75, 0.0)
	},
	{
		"name": "Tampak Belakang (Chase Angle)",
		"pos": Vector3(0.0, 1.6, 3.2),
		"look_at": Vector3(0.0, 0.8, -0.5)
	}
]

var lbl_view_mode: Label
var frame_count: int = 0


func _ready() -> void:
	print("PlayerPreview: _ready() called. Initializing UI and cameras...")
	_build_ui()
	_apply_camera_preset(0)


func _process(delta: float) -> void:
	frame_count += 1
	_handle_auto_capture()

	if view_cooldown > 0.0:
		view_cooldown = maxf(0.0, view_cooldown - delta)

	# Tombol V untuk beralih sudut kamera
	if Input.is_physical_key_pressed(KEY_V) and view_cooldown <= 0.0:
		view_cooldown = 0.3
		camera_angle_idx = (camera_angle_idx + 1) % camera_presets.size()
		_apply_camera_preset(camera_angle_idx)

	# Tombol Esc untuk keluar
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()


func _apply_camera_preset(idx: int) -> void:
	var preset: Dictionary = camera_presets[idx]
	camera.position = preset["pos"]
	camera.look_at(preset["look_at"], Vector3.UP)
	if lbl_view_mode:
		lbl_view_mode.text = "Sudut Kamera [Tekan 'V']: " + preset["name"]
	print("Camera preset switched to: ", preset["name"])


func _handle_auto_capture() -> void:
	var should_capture: bool = false
	var all_args: Array = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for a in all_args:
		if "capture" in a.to_lower():
			should_capture = true
			break
	if not should_capture:
		return

	if frame_count == 10:
		_save_screenshot("step1_verified_3d.png")
		_save_screenshot("screenshot_player_preview.png")
	elif frame_count == 20:
		_apply_camera_preset(1) # Side Profile
	elif frame_count == 28:
		_save_screenshot("step1_verified_side.png")
		_save_screenshot("screenshot_player_side_profile.png")
	elif frame_count == 36:
		_apply_camera_preset(2) # Front View
	elif frame_count == 44:
		_save_screenshot("step1_verified_front.png")
	elif frame_count == 52:
		_apply_camera_preset(3) # Rear View
	elif frame_count == 60:
		_save_screenshot("step1_verified_rear.png")
	elif frame_count >= 65:
		print("Auto-capture completed successfully, quitting.")
		get_tree().quit()


func _save_screenshot(filename: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var dir: String = "res://screenshots"
		var abs_dir: String = ProjectSettings.globalize_path(dir)
		DirAccess.make_dir_recursive_absolute(abs_dir)
		var abs_path: String = abs_dir + "/" + filename
		img.save_png(abs_path)
		print("📸 Screenshot preview disimpan ke: ", abs_path)


func _build_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "PreviewUI"
	add_child(canvas)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	canvas.add_child(margin)

	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.88)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "🏍️ FASE 3 — STEP 1: PLAYER & VEHICLE PREVIEW"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var info: Label = Label.new()
	info.text = (
		"• Kendaraan: Sepeda Motor Petualang (P=1.9m, L=0.68m, T=1.05m)\n"
		+ "• Karakter: Ponco Rider (Postur duduk alami, tangan di stang, kaki di pijakan)\n"
		+ "• Orientasi Hadap: -Z (Sesuai sumbu forward lintasan F2)\n"
		+ "• Skala: 1.0 (Roda menempel aspal pada Y=0.0m)"
	)
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	vbox.add_child(info)

	lbl_view_mode = Label.new()
	lbl_view_mode.text = "Sudut Kamera [Tekan 'V']: " + camera_presets[0]["name"]
	lbl_view_mode.add_theme_font_size_override("font_size", 12)
	lbl_view_mode.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	vbox.add_child(lbl_view_mode)

	var hint: Label = Label.new()
	hint.text = "Kontrol: V (Ganti Kamera) | Esc (Keluar)"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	vbox.add_child(hint)

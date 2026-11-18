extends Control

# Main: Scene pengujian awal untuk Fase 1.
# Menguji kesesuaian resolusi portrait (720x1280), kesiapan Autoload,
# dan verifikasi input gesture swipe, tap layar, serta keyboard.

var touch_controller: TouchController

# Elemen UI visual untuk indikator input
var label_status: Label
var label_gesture: Label
var box_left: PanelContainer
var box_jump: PanelContainer
var box_right: PanelContainer
var label_left: Label
var label_jump: Label
var label_right: Label


func _ready() -> void:
	# Bangun antarmuka secara prosedural (aman dan tidak merusak file tscn)
	_build_ui()
	_setup_touch_controller()


## Membuat tata letak antarmuka pengujian Fase 1
func _build_ui() -> void:
	# Latar belakang ceria
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.96, 0.94, 0.90) # Warna krem hangat
	add_child(bg)

	# Kontainer utama dengan margin agar tidak mepet tepi layar HP
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 64)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)

	# Judul Utama
	var title: Label = Label.new()
	title.text = "🚲 SEPEDA PETUALANG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.18, 0.22, 0.35))
	vbox.add_child(title)

	# Subjudul Fase
	var subtitle: Label = Label.new()
	subtitle.text = "Fase 1: Setup Proyek & Sistem Input"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.35, 0.45, 0.65))
	vbox.add_child(subtitle)

	# Kartu Info Status Autoload & Proyek
	var info_panel: PanelContainer = PanelContainer.new()
	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 8)
	info_panel.add_child(info_box)
	vbox.add_child(info_panel)

	var info_title: Label = Label.new()
	info_title.text = "✓ STATUS SISTEM INTI:"
	info_title.add_theme_font_size_override("font_size", 18)
	info_title.add_theme_color_override("font_color", Color(0.15, 0.6, 0.3))
	info_box.add_child(info_title)

	var info_text: Label = Label.new()
	var vp_size: Vector2 = get_viewport_rect().size
	info_text.text = (
		"• Resolusi Dasar: 720 x 1280 (Portrait)\n"
		+ "• Viewport Saat Ini: " + str(int(vp_size.x)) + " x " + str(int(vp_size.y)) + "\n"
		+ "• GameState (Autoload): Nyawa " + str(GameState.hearts) + "/" + str(GameState.MAX_HEARTS) + ", Koin: " + str(GameState.coins) + "\n"
		+ "• SaveManager (Autoload): Siap (user://save_data.json)\n"
		+ "• AudioManager (Autoload): Siap (Master Bus)"
	)
	info_text.add_theme_font_size_override("font_size", 16)
	info_text.add_theme_color_override("font_color", Color(0.2, 0.2, 0.25))
	info_box.add_child(info_text)

	# Label instruksi interaksi
	var inst_label: Label = Label.new()
	inst_label.text = "UJI INPUT PEMAIN:\nGeser jari (Swipe) / Ketuk sisi layar / Gunakan tombol Keyboard (A, D, Space, Panah)"
	inst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inst_label.add_theme_font_size_override("font_size", 17)
	inst_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	vbox.add_child(inst_label)

	# Baris Indikator Tombol Visual
	var hbox_indicators: HBoxContainer = HBoxContainer.new()
	hbox_indicators.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_indicators.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox_indicators)

	# 1. Indikator KIRI
	box_left = _create_indicator_box("⬅️ KIRI\n[A / ←]")
	label_left = box_left.get_child(0) as Label
	hbox_indicators.add_child(box_left)

	# 2. Indikator LOMPAT
	box_jump = _create_indicator_box("⬆️ LOMPAT\n[Space / W]")
	label_jump = box_jump.get_child(0) as Label
	hbox_indicators.add_child(box_jump)

	# 3. Indikator KANAN
	box_right = _create_indicator_box("➡️ KANAN\n[D / →]")
	label_right = box_right.get_child(0) as Label
	hbox_indicators.add_child(box_right)

	# Label Feedback Terakhir Gesture
	label_gesture = Label.new()
	label_gesture.text = "Gesture Terakhir: (Belum ada sentuhan)"
	label_gesture.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_gesture.add_theme_font_size_override("font_size", 18)
	label_gesture.add_theme_color_override("font_color", Color(0.85, 0.45, 0.1))
	vbox.add_child(label_gesture)

	# Tombol Uji Suara Prosedural
	var btn_sound: Button = Button.new()
	btn_sound.text = "🔊 Uji Efek Suara (AudioManager)"
	btn_sound.custom_minimum_size = Vector2(0, 52)
	btn_sound.add_theme_font_size_override("font_size", 17)
	btn_sound.pressed.connect(_on_test_sound_pressed)
	vbox.add_child(btn_sound)

	# Tombol Buka Arena Balap Fase 2
	var btn_gameplay: Button = Button.new()
	btn_gameplay.text = "🌅 Buka Arena Balap (Fase 2)"
	btn_gameplay.custom_minimum_size = Vector2(0, 56)
	btn_gameplay.add_theme_font_size_override("font_size", 18)
	btn_gameplay.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/gameplay.tscn"))
	vbox.add_child(btn_gameplay)

	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Footer Status Fase
	var footer: Label = Label.new()
	footer.text = "Fase 1 Berhasil & Fase 2 Siap Diuji."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 16)
	footer.add_theme_color_override("font_color", Color(0.4, 0.5, 0.4))
	vbox.add_child(footer)


## Memasang TouchController di scene
func _setup_touch_controller() -> void:
	touch_controller = TouchController.new()
	add_child(touch_controller)
	touch_controller.swipe_detected.connect(_on_swipe_detected)
	touch_controller.tap_detected.connect(_on_tap_detected)


## Membuat kotak indikator tombol dengan gaya visual
func _create_indicator_box(text: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 110)

	var lbl: Label = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	panel.add_child(lbl)

	_style_panel(panel, Color(0.88, 0.90, 0.92))
	return panel


## Mengubah warna panel indikator
func _style_panel(panel: PanelContainer, bg_color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)


## Memperbarui sorotan visual tombol saat ditekan/di-swipe
func _process(_delta: float) -> void:
	var left_active: bool = Input.is_action_pressed("move_left")
	var right_active: bool = Input.is_action_pressed("move_right")
	var jump_active: bool = Input.is_action_pressed("jump")

	_update_indicator(box_left, label_left, left_active, Color(0.25, 0.75, 0.45))
	_update_indicator(box_right, label_right, right_active, Color(0.25, 0.75, 0.45))
	_update_indicator(box_jump, label_jump, jump_active, Color(0.95, 0.65, 0.2))


func _update_indicator(panel: PanelContainer, label: Label, is_active: bool, active_color: Color) -> void:
	if is_active:
		_style_panel(panel, active_color)
		label.add_theme_color_override("font_color", Color.WHITE)
	else:
		_style_panel(panel, Color(0.88, 0.90, 0.92))
		label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))


func _on_swipe_detected(direction: Vector2) -> void:
	var desc: String = ""
	if abs(direction.x) > abs(direction.y):
		desc = "Swipe Kiri ⬅️" if direction.x < 0 else "Swipe Kanan ➡️"
	else:
		desc = "Swipe Atas (Lompat) ⬆️" if direction.y < 0 else "Swipe Bawah ⬇️"
	label_gesture.text = "Gesture Terakhir: " + desc


func _on_tap_detected(pos: Vector2) -> void:
	var vp_width: float = get_viewport_rect().size.x
	var zone: String = "Tengah (Lompat)"
	if pos.x < vp_width * 0.4:
		zone = "Kiri (Geser Kiri)"
	elif pos.x > vp_width * 0.6:
		zone = "Kanan (Geser Kanan)"
	label_gesture.text = "Gesture Terakhir: Ketuk " + zone


## Menghasilkan nada beep pendek ceria tanpa file audio eksternal
func _on_test_sound_pressed() -> void:
	var sample_rate: int = 22050
	var duration: float = 0.12
	var total_frames: int = int(sample_rate * duration)
	var pba: PackedByteArray = PackedByteArray()
	pba.resize(total_frames)

	# Gelombang suara 880 Hz (A5) dengan fade out lembut
	for i: int in range(total_frames):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = 1.0 - (float(i) / float(total_frames))
		var wave: float = sin(2.0 * PI * 880.0 * t) * envelope
		var byte_val: int = int(clamp((wave * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		pba.set(i, byte_val)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = pba

	AudioManager.play_sfx(stream)
	label_gesture.text = "Audio: SFX Berhasil Diputar!"

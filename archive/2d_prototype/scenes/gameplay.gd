extends Node2D

# Gameplay: Scene pengujian arena balap untuk Fase 2.
# Mengoordinasikan Latar Sunset (Background), Jalan 3 Lajur (Road),
# dan Dekorasi Bergerak (DecorationManager).

@onready var road: Road = $Road
@onready var decoration_manager: DecorationManager = $DecorationManager

var show_lane_guides: bool = false


func _ready() -> void:
	_setup_test_ui()


## Membuat UI overlay pengetesan Fase 2
func _setup_test_ui() -> void:
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	add_child(canvas_layer)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_right", 24)
	canvas_layer.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# Banner Informasi Fase 2
	var banner: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.22, 0.85)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	banner.add_theme_stylebox_override("panel", style)
	vbox.add_child(banner)

	var banner_box: VBoxContainer = VBoxContainer.new()
	banner_box.add_theme_constant_override("separation", 6)
	banner.add_child(banner_box)

	var lbl_title: Label = Label.new()
	lbl_title.text = "🌅 FASE 2: JALAN PERSPEKTIF 3 LAJUR"
	lbl_title.add_theme_font_size_override("font_size", 19)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	banner_box.add_child(lbl_title)

	var lbl_desc: Label = Label.new()
	lbl_desc.text = "• 3 Lajur konsisten: Kiri (-1), Tengah (0), Kanan (+1)\n• Marka jalan bergerak mulus (delta frame-independent)\n• Dekorasi kaktus, batu, semak, dan pohon membesar proporsional"
	lbl_desc.add_theme_font_size_override("font_size", 14)
	lbl_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	banner_box.add_child(lbl_desc)

	# Baris tombol kontrol
	var hbox_btns: HBoxContainer = HBoxContainer.new()
	hbox_btns.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox_btns)

	var btn_guides: Button = Button.new()
	btn_guides.text = "🔍 Garis Panduan Lajur"
	btn_guides.custom_minimum_size = Vector2(0, 44)
	btn_guides.pressed.connect(_on_toggle_guides)
	hbox_btns.add_child(btn_guides)

	var btn_back: Button = Button.new()
	btn_back.text = "⬅️ Kembali ke Tes Fase 1"
	btn_back.custom_minimum_size = Vector2(0, 44)
	btn_back.pressed.connect(_on_back_pressed)
	hbox_btns.add_child(btn_back)


func _on_toggle_guides() -> void:
	show_lane_guides = not show_lane_guides
	queue_redraw()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## Menggambar garis panduan lajur (bila diaktifkan) untuk memverifikasi akurasi matematika
func _draw() -> void:
	if not show_lane_guides:
		return

	var steps: int = 24
	var color_guide: Color = Color(0.2, 0.8, 1.0, 0.6)

	for lane in [-1, 0, 1]:
		for i in range(steps):
			var t1: float = float(i) / float(steps)
			var t2: float = float(i + 1) / float(steps)

			var p1: Vector2 = Vector2(PerspectiveMath.get_lane_x(t1, lane), PerspectiveMath.get_y(t1))
			var p2: Vector2 = Vector2(PerspectiveMath.get_lane_x(t2, lane), PerspectiveMath.get_y(t2))

			draw_line(p1, p2, color_guide, 2.0, true)

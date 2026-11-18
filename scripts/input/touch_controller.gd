class_name TouchController
extends Control

# TouchController: Menangani input sentuh layar (tap dan swipe gesture).
# Mendeteksi gesekan jari (swipe) secara manual menggunakan InputEventScreenTouch/Drag
# dan meneruskannya ke Input action Godot (move_left, move_right, jump, slide).

signal swipe_detected(direction: Vector2, action_name: String)
signal tap_detected(screen_position: Vector2, action_name: String)

# Konfigurasi ambang batas (threshold) sentuhan dalam piksel
const MIN_SWIPE_DISTANCE: float = 45.0
const MAX_TAP_DISTANCE: float = 25.0
const MAX_TAP_DURATION_SEC: float = 0.35

var touch_start_position: Vector2 = Vector2.ZERO
var touch_start_time_msec: int = 0
var is_touch_active: bool = false
var swipe_already_triggered: bool = false
var active_touch_index: int = -1 # Menangani multi-touch: hanya melacak jari pertama


func _ready() -> void:
	# Memastikan node ini menangkap input sentuh di seluruh layar
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# MOUSE_FILTER_PASS memungkinkan tombol UI di atasnya menangkap klik duluan
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)


## Memproses awal dan akhir sentuhan layar
func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Hanya layani satu jari aktif pertama (menghindari konflik multi-touch)
		if active_touch_index == -1:
			active_touch_index = event.index
			is_touch_active = true
			swipe_already_triggered = false
			touch_start_position = event.position
			touch_start_time_msec = Time.get_ticks_msec()
	else:
		if event.index == active_touch_index:
			if is_touch_active and not swipe_already_triggered:
				var touch_vector: Vector2 = event.position - touch_start_position
				var duration_sec: float = (Time.get_ticks_msec() - touch_start_time_msec) / 1000.0

				# Deteksi apakah ini berupa ketukan (Tap)
				if touch_vector.length() <= MAX_TAP_DISTANCE and duration_sec <= MAX_TAP_DURATION_SEC:
					_process_tap(event.position)

			is_touch_active = false
			swipe_already_triggered = false
			active_touch_index = -1


## Memproses pergeseran jari secara langsung saat menyentuh
func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not is_touch_active or swipe_already_triggered or event.index != active_touch_index:
		return

	var drag_vector: Vector2 = event.position - touch_start_position
	if drag_vector.length() >= MIN_SWIPE_DISTANCE:
		_process_swipe(drag_vector)
		swipe_already_triggered = true


## Menentukan arah gesekan (kiri, kanan, atas, bawah/slide)
func _process_swipe(vector: Vector2) -> void:
	var triggered_action: String = ""

	# Gesekan horizontal vs vertikal
	if abs(vector.x) > abs(vector.y):
		if vector.x < 0.0:
			triggered_action = "move_left"
		else:
			triggered_action = "move_right"
	else:
		if vector.y < 0.0:
			triggered_action = "jump"
		else:
			triggered_action = "slide"

	if triggered_action != "":
		_trigger_action(triggered_action)
		swipe_detected.emit(vector.normalized(), triggered_action)


## Menentukan aksi dari ketukan (sisi kiri atau kanan layar)
func _process_tap(tap_pos: Vector2) -> void:
	var viewport_width: float = get_viewport_rect().size.x
	var triggered_action: String = ""

	# Ketuk 40% area kiri -> pindah kiri
	if tap_pos.x < viewport_width * 0.4:
		triggered_action = "move_left"
	# Ketuk 40% area kanan -> pindah kanan
	elif tap_pos.x > viewport_width * 0.6:
		triggered_action = "move_right"
	# Ketuk area tengah -> lompat
	else:
		triggered_action = "jump"

	if triggered_action != "":
		_trigger_action(triggered_action)
		tap_detected.emit(tap_pos, triggered_action)


## Memicu event action Godot secara singkat agar dideteksi is_action_just_pressed()
func _trigger_action(action_name: String) -> void:
	Input.action_press(action_name)
	# Lepaskan aksi pada frame berikutnya
	get_tree().create_timer(0.05).timeout.connect(func(): Input.action_release(action_name))

extends Node

# GameState: Autoload untuk menyimpan status permainan saat runtime.
# Bertanggung jawab atas koin, nyawa/hati, skor, progres level, dan registrasi input dasar.

# Sinyal untuk memberitahu UI atau sistem lain saat ada perubahan
signal coins_changed(new_amount: int)
signal hearts_changed(new_amount: int)
signal score_changed(new_score: int)
signal game_paused(is_paused: bool)

# Konstanta batas nyawa pemain
const MAX_HEARTS: int = 3
const INITIAL_HEARTS: int = 3

# Variabel sesi aktif
var coins: int = 0:
	set(value):
		coins = max(0, value)
		coins_changed.emit(coins)

var hearts: int = INITIAL_HEARTS:
	set(value):
		hearts = clamp(value, 0, MAX_HEARTS)
		hearts_changed.emit(hearts)

var score: int = 0:
	set(value):
		score = max(0, value)
		score_changed.emit(score)

var current_level_index: int = 1
var is_game_active: bool = false


func _ready() -> void:
	# Pastikan input map terpasang dengan aman untuk testing PC & mobile
	_setup_default_input_map()
	# Inisialisasi status awal saat game pertama kali dijalankan
	reset_session()


## Mengatur ulang nilai sesi untuk memulai level baru
func reset_session() -> void:
	coins = 0
	hearts = INITIAL_HEARTS
	score = 0
	is_game_active = false


## Menambah koin yang didapat pemain
func add_coins(amount: int) -> void:
	if amount > 0:
		coins += amount


## Mengurangi hati ketika sepeda tersandung rintangan
func take_damage() -> void:
	if hearts > 0:
		hearts -= 1


## Menambah hati jika mendapatkan bonus penyembuh
func heal() -> void:
	if hearts < MAX_HEARTS:
		hearts += 1


## Memastikan action input terdaftar di InputMap (Keyboard & Touch)
func _setup_default_input_map() -> void:
	_register_key_action("move_left", [KEY_LEFT, KEY_A])
	_register_key_action("move_right", [KEY_RIGHT, KEY_D])
	_register_key_action("jump", [KEY_UP, KEY_W, KEY_SPACE])
	_register_key_action("slide", [KEY_DOWN, KEY_S])
	_register_key_action("pause", [KEY_ESCAPE])


## Helper untuk mendaftarkan aksi input bila belum ada
func _register_key_action(action_name: String, keycodes: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode: Key in keycodes:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = keycode
		# Hindari duplikasi event
		var already_exists: bool = false
		for existing_event: InputEvent in InputMap.action_get_events(action_name):
			if existing_event is InputEventKey and existing_event.physical_keycode == keycode:
				already_exists = true
				break
		if not already_exists:
			InputMap.action_add_event(action_name, event)

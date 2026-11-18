extends Node

# SaveManager: Autoload untuk menyimpan dan memuat progres permainan secara offline.
# Data disimpan dalam format JSON di direktori aman pengguna (user://).

const SAVE_FILE_PATH: String = "user://save_data.json"

# Struktur default jika belum ada save file
const DEFAULT_DATA: Dictionary = {
	"total_coins": 0,
	"unlocked_levels": [1],
	"level_stars": {
		"1": 0,
		"2": 0,
		"3": 0,
		"4": 0,
		"5": 0
	},
	"equipped_bike_color": "classic_orange",
	"equipped_helmet": "white_standard",
	"owned_items": ["classic_orange", "white_standard"],
	"settings": {
		"music_enabled": true,
		"sfx_enabled": true,
		"language": "id"
	}
}

var current_data: Dictionary = {}


func _ready() -> void:
	load_game()


## Memuat data dari file penyimpanan. Jika tidak ada, pakai nilai default.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		current_data = DEFAULT_DATA.duplicate(true)
		save_game()
		return

	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		current_data = DEFAULT_DATA.duplicate(true)
		return

	var json_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	if parsed is Dictionary:
		current_data = parsed
		_verify_missing_keys()
	else:
		# Jika file rusak, kembali ke default
		current_data = DEFAULT_DATA.duplicate(true)
		save_game()


## Menyimpan data permainan ke media penyimpanan perangkat
func save_game() -> void:
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: Gagal membuka file untuk menyimpan data!")
		return

	var json_string: String = JSON.stringify(current_data, "\t")
	file.store_string(json_string)
	file.close()


## Mengambil total koin yang dimiliki pemain
func get_total_coins() -> int:
	return int(current_data.get("total_coins", 0))


## Menambah total koin tabungan dan menyimpannya
func add_total_coins(amount: int) -> void:
	current_data["total_coins"] = get_total_coins() + max(0, amount)
	save_game()


## Menyimpan perolehan bintang untuk level tertentu
func set_level_stars(level_number: int, stars: int) -> void:
	var key: String = str(level_number)
	var stars_dict: Dictionary = current_data.get("level_stars", {})
	var current_stars: int = int(stars_dict.get(key, 0))

	# Simpan jika skor bintang lebih tinggi dari sebelumnya
	if stars > current_stars:
		stars_dict[key] = clamp(stars, 0, 3)
		current_data["level_stars"] = stars_dict

	# Buka level berikutnya jika berhasil mendapat minimal 1 bintang
	if stars >= 1:
		var unlocked: Array = current_data.get("unlocked_levels", [1])
		var next_level: int = level_number + 1
		if not unlocked.has(next_level) and next_level <= 5:
			unlocked.append(next_level)
			current_data["unlocked_levels"] = unlocked

	save_game()


## Memeriksa kelengkapan key data agar kompatibel saat update
func _verify_missing_keys() -> void:
	for key: String in DEFAULT_DATA.keys():
		if not current_data.has(key):
			current_data[key] = DEFAULT_DATA[key]

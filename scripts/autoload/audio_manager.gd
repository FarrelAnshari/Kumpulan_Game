extends Node

# AudioManager: Autoload untuk menangani musik latar dan efek suara (SFX).
# Mendukung pengaturan bisu/nyala (mute/unmute) yang sinkron dengan SaveManager.

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

const MAX_SFX_PLAYERS: int = 6

var is_music_enabled: bool = true
var is_sfx_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Musik tetap bisa dikontrol saat jeda (pause)
	_setup_audio_players()
	_sync_with_settings()


## Menyiapkan node AudioStreamPlayer secara prosedural
func _setup_audio_players() -> void:
	# Player untuk musik latar
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)

	# Kumpulan player untuk efek suara (SFX pooling)
	for i in range(MAX_SFX_PLAYERS):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)


## Sinkronisasi pengaturan suara dengan SaveManager
func _sync_with_settings() -> void:
	if SaveManager and SaveManager.current_data.has("settings"):
		var settings: Dictionary = SaveManager.current_data["settings"]
		is_music_enabled = settings.get("music_enabled", true)
		is_sfx_enabled = settings.get("sfx_enabled", true)


## Memutar musik latar
func play_music(stream: AudioStream) -> void:
	if stream == null or not is_music_enabled:
		return
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.play()


## Menghentikan musik latar
func stop_music() -> void:
	if bgm_player.playing:
		bgm_player.stop()


## Memutar efek suara (SFX)
func play_sfx(stream: AudioStream) -> void:
	if stream == null or not is_sfx_enabled:
		return

	# Cari player SFX yang sedang menganggur
	for player: AudioStreamPlayer in sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return

	# Jika semua sedang terpakai, gunakan player pertama
	sfx_players[0].stream = stream
	sfx_players[0].play()


## Menyalakan / mematikan musik latar
func toggle_music() -> bool:
	is_music_enabled = not is_music_enabled
	if not is_music_enabled:
		bgm_player.stop()
	elif bgm_player.stream != null:
		bgm_player.play()

	_save_audio_preference()
	return is_music_enabled


## Menyalakan / mematikan efek suara (SFX)
func toggle_sfx() -> bool:
	is_sfx_enabled = not is_sfx_enabled
	_save_audio_preference()
	return is_sfx_enabled


## Menyimpan preferensi audio ke save data
func _save_audio_preference() -> void:
	if SaveManager and SaveManager.current_data.has("settings"):
		SaveManager.current_data["settings"]["music_enabled"] = is_music_enabled
		SaveManager.current_data["settings"]["sfx_enabled"] = is_sfx_enabled
		SaveManager.save_game()

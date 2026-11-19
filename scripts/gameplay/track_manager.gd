class_name TrackManager
extends Node3D

# TrackManager: Mengelola rantai segmen lintasan modular.
# Menyambungkan segmen secara otomatis berdasarkan titik entry/exit,
# memastikan tidak ada celah antar segmen.

## Sinyal saat segmen baru ditambahkan atau dihapus
signal segment_added(segment: TrackSegment, index: int)
signal segment_removed(index: int)

## Daftar segmen aktif yang sudah terpasang
var active_segments: Array[TrackSegment] = []

## Referensi ke segmen terakhir yang ditambahkan (untuk penyambungan)
var last_exit_point: Vector3 = Vector3.ZERO
var last_exit_forward: Vector3 = Vector3(0.0, 0.0, -1.0)
var last_exit_basis: Basis = Basis.IDENTITY


func _ready() -> void:
	pass


## Menambahkan segmen baru ke ujung rantai lintasan.
## Segmen akan diposisikan secara otomatis agar tersambung tanpa celah.
func append_segment(segment: TrackSegment) -> void:
	add_child(segment)

	if active_segments.size() == 0:
		# Segmen pertama: letakkan di origin
		segment.global_position = Vector3.ZERO
		segment.global_rotation = Vector3.ZERO
	else:
		# Sambungkan ke titik keluar segmen sebelumnya
		_connect_segment_to_chain(segment)

	active_segments.append(segment)

	# Simpan titik keluar segmen ini untuk penyambungan berikutnya
	last_exit_point = segment.get_global_exit_point()
	last_exit_forward = segment.get_global_exit_forward()
	last_exit_basis = segment.global_basis

	segment_added.emit(segment, active_segments.size() - 1)


## Menyambungkan segmen baru ke ujung rantai lintasan.
## Titik masuk segmen baru disejajarkan dengan titik keluar segmen sebelumnya.
func _connect_segment_to_chain(segment: TrackSegment) -> void:
	# Hitung rotasi: arahkan entry_forward segmen baru menuju last_exit_forward
	var target_forward: Vector3 = last_exit_forward.normalized()

	# Rotasi horizontal (sumbu Y) agar arah forward cocok
	var angle_y: float = atan2(target_forward.x, target_forward.z) - atan2(
		segment.entry_forward.x, segment.entry_forward.z
	)
	segment.global_rotation = Vector3(0.0, angle_y, 0.0)

	# Posisikan: titik entry segmen baru = titik exit segmen sebelumnya
	var entry_global: Vector3 = segment.get_global_entry_point()
	var offset: Vector3 = last_exit_point - entry_global
	segment.global_position += offset


## Menghapus semua segmen dari lintasan
func clear_all_segments() -> void:
	for segment in active_segments:
		if is_instance_valid(segment):
			segment.queue_free()
	active_segments.clear()
	last_exit_point = Vector3.ZERO
	last_exit_forward = Vector3(0.0, 0.0, -1.0)
	last_exit_basis = Basis.IDENTITY


## Mendapatkan jumlah segmen aktif
func get_segment_count() -> int:
	return active_segments.size()


## Mendapatkan segmen berdasarkan indeks
func get_segment(index: int) -> TrackSegment:
	if index >= 0 and index < active_segments.size():
		return active_segments[index]
	return null


## Mendapatkan panjang total lintasan (jumlah panjang semua segmen)
func get_total_length() -> float:
	var total: float = 0.0
	for segment in active_segments:
		total += segment.segment_length
	return total


## Menambahkan beberapa segmen sekaligus dari daftar tipe
func build_from_sequence(segment_types: Array[Dictionary]) -> void:
	clear_all_segments()
	for seg_data in segment_types:
		var segment: TrackSegment = _create_segment_from_data(seg_data)
		if segment:
			append_segment(segment)


## Membuat instance segmen berdasarkan data konfigurasi
func _create_segment_from_data(data: Dictionary) -> TrackSegment:
	var seg_type: String = data.get("type", "straight")
	var segment: TrackSegment

	match seg_type:
		"straight":
			var s: TrackStraight = TrackStraight.new()
			s.segment_length = data.get("length", TrackSegment.DEFAULT_LENGTH)
			segment = s
		"curve_left":
			var s: TrackCurveLeft = TrackCurveLeft.new()
			s.curve_angle_deg = data.get("angle", 30.0)
			s.curve_radius = data.get("radius", 40.0)
			segment = s
		"curve_right":
			var s: TrackCurveRight = TrackCurveRight.new()
			s.curve_angle_deg = data.get("angle", 30.0)
			s.curve_radius = data.get("radius", 40.0)
			segment = s
		"uphill":
			var s: TrackUphill = TrackUphill.new()
			s.segment_length = data.get("length", TrackSegment.DEFAULT_LENGTH)
			s.elevation_gain = data.get("elevation", 3.0)
			segment = s
		"downhill":
			var s: TrackDownhill = TrackDownhill.new()
			s.segment_length = data.get("length", TrackSegment.DEFAULT_LENGTH)
			s.elevation_drop = data.get("elevation", 3.0)
			segment = s
		"ramp":
			var s: TrackRamp = TrackRamp.new()
			s.ramp_height = data.get("height", 2.5)
			s.ramp_up_length = data.get("up_length", 8.0)
			s.ramp_flat_length = data.get("flat_length", 4.0)
			s.ramp_down_length = data.get("down_length", 8.0)
			segment = s
		"bridge":
			var s: TrackBridge = TrackBridge.new()
			s.bridge_height = data.get("height", 4.0)
			s.bridge_span_length = data.get("span", 24.0)
			s.approach_length = data.get("approach", 8.0)
			segment = s

	return segment

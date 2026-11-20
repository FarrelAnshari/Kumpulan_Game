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


## Memvalidasi koneksi antar segmen dan melaporkan diagnostik.
## Mengembalikan Array of Dictionary berisi informasi gap, arah, dan status setiap sambungan.
func validate_connections() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for i in range(active_segments.size() - 1):
		var seg_a: TrackSegment = active_segments[i]
		var seg_b: TrackSegment = active_segments[i + 1]

		var exit_pt: Vector3 = seg_a.get_global_exit_point()
		var entry_pt: Vector3 = seg_b.get_global_entry_point()
		var gap_distance: float = exit_pt.distance_to(entry_pt)

		var exit_fwd: Vector3 = seg_a.get_global_exit_forward().normalized()
		var entry_fwd: Vector3 = seg_b.get_global_entry_forward().normalized()
		var forward_dot: float = exit_fwd.dot(entry_fwd)
		var angle_diff_deg: float = rad_to_deg(acos(clampf(forward_dot, -1.0, 1.0)))

		var status: String = "OK"
		if gap_distance > 0.1:
			status = "GAP"
		elif angle_diff_deg > 2.0:
			status = "MISALIGNED"

		results.append({
			"index": i,
			"seg_a_type": seg_a.segment_type,
			"seg_b_type": seg_b.segment_type,
			"exit_point": exit_pt,
			"entry_point": entry_pt,
			"gap_distance": gap_distance,
			"angle_diff_deg": angle_diff_deg,
			"status": status,
		})

	return results


## Mencetak laporan diagnostik koneksi ke konsol Godot
func print_connection_diagnostics() -> void:
	var results: Array[Dictionary] = validate_connections()
	var issues_found: int = 0

	print("=== DIAGNOSTIK KONEKSI LINTASAN ===")
	print("Jumlah segmen: ", active_segments.size())
	print("Panjang total: ", snappedf(get_total_length(), 0.1), "m")
	print("")

	for r in results:
		var i: int = r["index"]
		var gap: float = r["gap_distance"]
		var angle: float = r["angle_diff_deg"]
		var status: String = r["status"]

		if status != "OK":
			issues_found += 1

		var icon: String = "✅" if status == "OK" else "❌"
		print(
			icon, " Sambungan ", i, "→", i + 1,
			" | Gap: ", snappedf(gap, 0.001), "m",
			" | Sudut: ", snappedf(angle, 0.01), "°",
			" | Status: ", status
		)

	print("")
	if issues_found == 0:
		print("✅ Semua ", results.size(), " sambungan terhubung dengan benar.")
	else:
		print("❌ Ditemukan ", issues_found, " masalah sambungan.")


## Mendapatkan Transform3D dunia pada jarak total tertentu di sepanjang lintasan
## total_dist: jarak kumulatif dari awal lintasan (meter)
## lane_offset: offset lateral dari garis tengah (-3.5 = kiri, 0 = tengah, +3.5 = kanan)
func get_transform_at_distance(total_dist: float, lane_offset: float = 0.0) -> Transform3D:
	if active_segments.is_empty():
		return Transform3D.IDENTITY

	var remaining_dist: float = maxf(0.0, total_dist)
	for seg in active_segments:
		if remaining_dist <= seg.segment_length:
			return seg.get_global_transform_at_distance(remaining_dist, lane_offset)
		remaining_dist -= seg.segment_length

	# Jika melebihi panjang total, gunakan ujung segmen terakhir
	var last_seg: TrackSegment = active_segments.back()
	return last_seg.get_global_transform_at_distance(last_seg.segment_length, lane_offset)


## Mendapatkan informasi detail segmen pada jarak total tertentu
func get_segment_info_at_distance(total_dist: float) -> Dictionary:
	if active_segments.is_empty():
		return {"segment": null, "index": -1, "local_dist": 0.0, "segment_length": 0.0}

	var remaining_dist: float = maxf(0.0, total_dist)
	for i in range(active_segments.size()):
		var seg: TrackSegment = active_segments[i]
		if remaining_dist <= seg.segment_length or i == active_segments.size() - 1:
			return {
				"segment": seg,
				"index": i,
				"local_dist": remaining_dist,
				"segment_type": seg.segment_type,
				"segment_length": seg.segment_length
			}
		remaining_dist -= seg.segment_length

	return {"segment": null, "index": -1, "local_dist": 0.0, "segment_length": 0.0}


## Mencetak diagnostik path following untuk setiap segmen ke konsol
func print_path_diagnostics() -> void:
	print("\n========================================================")
	print("🚗 DIAGNOSTIK PATH FOLLOWING LINTASAN 3D")
	print("========================================================")
	var cum_dist: float = 0.0
	for i in range(active_segments.size()):
		var seg: TrackSegment = active_segments[i]
		var type_str: String = ""
		match seg.segment_type:
			TrackSegment.SegmentType.STRAIGHT: type_str = "STRAIGHT"
			TrackSegment.SegmentType.CURVE_LEFT: type_str = "CURVE_LEFT"
			TrackSegment.SegmentType.CURVE_RIGHT: type_str = "CURVE_RIGHT"
			TrackSegment.SegmentType.UPHILL: type_str = "UPHILL"
			TrackSegment.SegmentType.DOWNHILL: type_str = "DOWNHILL"
			TrackSegment.SegmentType.RAMP: type_str = "RAMP"
			TrackSegment.SegmentType.BRIDGE: type_str = "BRIDGE"

		var mid_dist: float = cum_dist + seg.segment_length * 0.5
		var tf_center: Transform3D = get_transform_at_distance(mid_dist, 0.0)
		var tf_left: Transform3D = get_transform_at_distance(mid_dist, -3.5)
		var tf_right: Transform3D = get_transform_at_distance(mid_dist, 3.5)

		var pos: Vector3 = tf_center.origin
		var fwd: Vector3 = -tf_center.basis.z.normalized()
		var yaw: float = rad_to_deg(atan2(fwd.x, -fwd.z))
		var pitch: float = rad_to_deg(asin(clampf(fwd.y, -1.0, 1.0)))

		var lane_l_dist: float = (tf_center.origin - tf_left.origin).length()
		var lane_r_dist: float = (tf_right.origin - tf_center.origin).length()

		print(
			"[%2d/13] %-11s (len=%4.1fm) | Pos=(%5.1f, %4.1f, %5.1f) | Yaw=%5.1f° Pitch=%4.1f° | Lajur=(%3.1fm, %3.1fm)" % [
				i + 1, type_str, seg.segment_length, pos.x, pos.y, pos.z, yaw, pitch, lane_l_dist, lane_r_dist
			]
		)
		cum_dist += seg.segment_length
	print("========================================================\n")

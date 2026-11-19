class_name TrackStraight
extends TrackSegment

# TrackStraight: Segmen lintasan lurus.
# Menggunakan geometri default dari TrackSegment tanpa modifikasi.


func _ready() -> void:
	segment_type = SegmentType.STRAIGHT
	super._ready()

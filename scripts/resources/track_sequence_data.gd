class_name TrackSequenceData
extends Resource

# TrackSequenceData: Resource untuk mendefinisikan urutan segmen lintasan.
# Digunakan oleh TrackManager untuk membangun lintasan dari data.
# Disimpan sebagai file .tres di folder resources/levels/.

@export var sequence_name: String = "Test Track"
@export var description: String = ""

## Daftar segmen berupa Array of Dictionary.
## Setiap Dictionary berisi:
##   - "type": String ("straight", "curve_left", "curve_right", "uphill", "downhill", "ramp", "bridge")
##   - Parameter tambahan sesuai tipe:
##     - straight: "length" (float)
##     - curve_left/right: "angle" (float, derajat), "radius" (float, meter)
##     - uphill: "length" (float), "elevation" (float)
##     - downhill: "length" (float), "elevation" (float)
##     - ramp: "height", "up_length", "flat_length", "down_length" (float)
##     - bridge: "height", "span", "approach" (float)
@export var segments: Array[Dictionary] = []

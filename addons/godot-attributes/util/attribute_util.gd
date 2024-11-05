## Utilities for Godot Attributes.
class_name AttributeUtil extends Object

enum TimeUnit {
	## Time in seconds.
	SECONDS = 0,
	## Time in milliseconds.
	MILLISECONDS = 1,
	## Time in microseconds.
	MICROSECONDS = 2,
}

static var _conversions_to_seconds: Dictionary = {
	TimeUnit.SECONDS: 1.0,
	TimeUnit.MILLISECONDS: 1_000.0,
	TimeUnit.MICROSECONDS: 1_000_000.0,
}

## Returns the amount of time passed since the engine started, but in the unit of [param time_unit].
static func get_ticks(time_unit: TimeUnit) -> float:
	match time_unit:
		TimeUnit.MICROSECONDS:
			return Time.get_ticks_usec()
		TimeUnit.MILLISECONDS:
			return Time.get_ticks_msec()
		TimeUnit.SECONDS:
			return AttributeUtil.get_ticks_seconds()
		_:
			assert(false, "no implementation for time_unit (%s)" % time_unit)
			return false


## Returns the conversion of [method Time.get_ticks_usec] to seconds.
static func get_ticks_seconds() -> float:
	return Time.get_ticks_usec() / 1_000_000.0



class Reference extends Object:
	var ref: Variant
	
	func _init(_ref: Variant) -> void:
		ref = _ref

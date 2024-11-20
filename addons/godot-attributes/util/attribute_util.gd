## Utilities for Godot Attributes.
class_name AttributeUtil extends Object

static func connect_safely(_signal: Signal, _callable: Callable) -> void:
	if !_signal.is_connected(_callable):
		_signal.connect(_callable)


static func disconnect_safely(_signal: Signal, _callable: Callable) -> void:
	if _signal.is_connected(_callable):
		_signal.disconnect(_callable)


class Reference extends Object:
	var ref: Variant
	
	func _init(_ref: Variant) -> void:
		ref = _ref

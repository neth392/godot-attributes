## Contains the data relating to any event that occurred within an [Attribute].
## TODO better explained docs.
class_name AttributeEvent extends Object

var _active_effect: ActiveAttributeEffect
var _apply_event: bool = false
var _add_event: bool = false
var _remove_event: bool = false
var _active_add_blocked_by_source: ActiveAttributeEffect
var _old_active_stack_count: int = 0
var _new_active_stack_count: int = 0
var _old_base_value: float
var _new_base_value: float
var _old_current_value: float
var _new_current_value: float

func _init(attribute: Attribute, active: ActiveAttributeEffect = null) -> void:
	assert(attribute != null, "attribute is null")
	_old_base_value = attribute._base_value
	_new_base_value = attribute._base_value
	_old_current_value = attribute._current_value
	_new_current_value = attribute._current_value
	_active_effect = active
	if _active_effect != null:
		_old_active_stack_count = _active_effect.get_stack_count()
		_new_active_stack_count = _active_effect.get_stack_count()


func get_active_effect() -> ActiveAttributeEffect:
	return _active_effect


func is_apply_event() -> bool:
	return _apply_event


func is_add_event() -> bool:
	return _add_event


func is_remove_event() -> bool:
	return _remove_event


func get_active_add_blocked_by_source() -> ActiveAttributeEffect:
	return _active_add_blocked_by_source


func get_new_active_stack_count() -> int:
	return _new_active_stack_count


func get_old_active_stack_count() -> int:
	return _old_active_stack_count


func active_stack_count_changed() -> bool:
	assert(_active_effect != null, "_active_effect is null for this event")
	return _old_active_stack_count != _new_active_stack_count


func base_value_changed() -> bool:
	return _old_base_value != _new_base_value


func get_old_base_value() -> float:
	return _old_base_value


func get_new_base_value() -> float:
	return _new_base_value


func current_value_changed() -> bool:
	return _old_current_value != _new_current_value


func get_old_current_value() -> float:
	return _old_current_value


func get_new_current_value() -> float:
	return _new_current_value

## Emitted by [signal Attribute.event_occurred], contains the data relating to any event
## that occurred within an [Attribute].
class_name AttributeEvent extends Object

var _attribute: Attribute
var _active_effect: ActiveAttributeEffect

# Types of events
var _apply_event: bool = false
var _apply_blocked_event: bool = false
var _add_event: bool = false
var _remove_event: bool = false

# Stack count
var _prev_active_stack_count: int = 0
var _new_active_stack_count: int = 0

# Base values
var _prev_base_value: float
var _new_base_value: float

# Current value
var _prev_current_value: float
var _new_current_value: float

# Use a Dictionary here for more efficient lookups
var _blocked_temporary_actives: Dictionary[ActiveAttributeEffect, Variant]

func _init(attribute: Attribute, active: ActiveAttributeEffect = null) -> void:
	assert(attribute != null, "attribute is null")
	_attribute = attribute
	_prev_base_value = attribute._base_value
	_new_base_value = attribute._base_value
	_prev_current_value = attribute._current_value
	_new_current_value = attribute._current_value
	_active_effect = active
	if _active_effect != null:
		_prev_active_stack_count = _active_effect.get_stack_count()
		_new_active_stack_count = _active_effect.get_stack_count()


func get_attribute() -> Attribute:
	return _attribute


func has_active_effect() -> bool:
	return _active_effect != null


func get_active_effect() -> ActiveAttributeEffect:
	return _active_effect


func is_apply_event() -> bool:
	return _apply_event


func is_apply_blocked_event() -> bool:
	return _apply_blocked_event


func is_add_event() -> bool:
	return _add_event


func is_add_block_event() -> bool:
	return _add_event && _active_effect.get_last_add_result() != Attribute.AddEffectResult.SUCCESS


func is_remove_event() -> bool:
	return _remove_event


func get_new_active_stack_count() -> int:
	return _new_active_stack_count


func get_prev_active_stack_count() -> int:
	return _prev_active_stack_count


func active_stack_count_changed() -> bool:
	assert(_active_effect != null, "_active_effect is null for this event")
	return _new_active_stack_count != _prev_active_stack_count


func base_value_changed() -> bool:
	return _prev_base_value != _new_base_value


func get_prev_base_value() -> float:
	return _prev_base_value


func get_new_base_value() -> float:
	return _new_base_value


func current_value_changed() -> bool:
	return _prev_current_value != _new_current_value


func get_prev_current_value() -> float:
	return _prev_current_value


func get_new_current_value() -> float:
	return _new_current_value


func is_temporary_blocked(temporary_active: ActiveAttributeEffect) -> bool:
	return _blocked_temporary_actives.has(temporary_active)


func get_blocked_temporaries() -> Array[ActiveAttributeEffect]:
	return _blocked_temporary_actives.keys()

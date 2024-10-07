## Contains the data relating to any event that occurred within an [Attribute]
## during 
class_name AttributeEvent extends Object

var _active_effect: ActiveAttributeEffect
var _active_applied: bool = false
var _active_added: bool = false
var _active_removed: bool = false
var _old_active_stack_count: int = 0
var _new_active_stack_count: int = 0
var _old_base_value: float
var _new_base_value: float
var _old_current_value: float
var _new_current_value: float

func get_active_effect() -> ActiveAttributeEffect:
	return _active_effect


func active_applied() -> bool:
	return _active_applied


func active_added() -> bool:
	return _active_added


func active_removed() -> bool:
	return _active_removed


func active_stack_count_changed() -> bool:
	assert(_active_effect != null, "_active_effect is null for this event")
	return _old_active_stack_count != _active_effect.get_stack_count()


func get_old_active_stack_count() -> int:
	return _old_active_stack_count


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

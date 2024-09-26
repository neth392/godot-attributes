## Wrapper of an [Array] of [ActiveAttributeEffect]s for safety in use with an [Attribute].
## [br]NOTE: This class was designed so that iterating active effects based on their features is
## quicker than adding & removing. It is a tradeoff subject to change, but more than
## likely arrays will be iterated constantly while added to / removed from less so.
class_name ActiveAttributeEffectArray extends Resource

var _same_priority_sorting_method: Attribute.SamePrioritySortingMethod
var _array: Array[ActiveAttributeEffect] = []

# Feature specific arrays
var _only_temps: Array[ActiveAttributeEffect] = []
var _only_blockers: Array[ActiveAttributeEffect] = []
var _only_modifiers: Array[ActiveAttributeEffect] = []

func _init(same_priority_sorting_method: Attribute.SamePrioritySortingMethod) -> void:
	_same_priority_sorting_method = same_priority_sorting_method


## Returns the underlying array for iteration purposes ONLY.
func iterate() -> Array[ActiveAttributeEffect]:
	return _array


## Returns an underlying array of only TEMPORARY [ActiveAttributeEffect]s, for
## iteration purposes ONLY.
func iterate_temp() -> Array[ActiveAttributeEffect]:
	return _only_temps


## Returns an underlying array of only blocker [ActiveAttributeEffect]s, for
## iteration purposes ONLY.
func iterate_blockers() -> Array[ActiveAttributeEffect]:
	return _only_blockers


## Returns an underlying array of only modifier [ActiveAttributeEffect]s, for
## iteration purposes ONLY.
func iterate_modifiers() -> Array[ActiveAttributeEffect]:
	return _only_modifiers


## Returns the range to iterate the undelrying array in reverse.
func iterate_reverse() -> Array:
	return range(_array.size() -1, -1, -1)


func add(active: ActiveAttributeEffect) -> int:
	assert(!_array.has(active), "active (%s) already present" % active)
	var index: int = _add_to_sorted_array(_array, active)
	
	if active.get_effect().is_temporary():
		_add_to_sorted_array(_only_temps, active)
	
	if active.get_effect().is_blocker():
		_add_to_sorted_array(_only_blockers, active)
	
	if active.get_effect().is_modifier():
		_add_to_sorted_array(_only_modifiers, active)
	
	return index


func _add_to_sorted_array(add_to: Array[ActiveAttributeEffect], active: ActiveAttributeEffect) -> int:
	var index: int = 0
	for other_active: ActiveAttributeEffect in add_to:
		if _sort_new_before_other(active, other_active):
			add_to.insert(index, active)
			break
		index += 1
	
	# Append if not added during loop
	if index == add_to.size():
		add_to.append(active)
	
	return index


func _sort_new_before_other(new: ActiveAttributeEffect, other: ActiveAttributeEffect) -> bool:
	if new.get_effect().type != other.get_effect().type:
		return new.get_effect().type < other.get_effect().type
	if new.get_effect().priroity == other.get_effect().priority:
		match _same_priority_sorting_method:
			Attribute.SamePrioritySortingMethod.OLDER_FIRST:
				return false
			Attribute.SamePrioritySortingMethod.NEWER_FIRST:
				return true
			_:
				assert(false, "no implementation for _same_priority_sorting_method (%s)" \
				% _same_priority_sorting_method)
	return new.get_effect().priority > other.get_effect().priority


func erase(active: ActiveAttributeEffect) -> void:
	_array.erase(active)
	_erase_from_arrays(active)


func remove_at(active: ActiveAttributeEffect, index: int) -> void:
	_array.remove_at(index)
	_erase_from_arrays(active)


func _erase_from_arrays(active: ActiveAttributeEffect) -> void:
	if active.get_effect().is_temporary():
		_only_temps.erase(active)
	if active.get_effect().is_blocker():
		_only_blockers.erase(active)
	if active.get_effect().is_modifier():
		_only_modifiers.erase(active)


func is_empty() -> bool:
	return _array.is_empty()


func has(active: ActiveAttributeEffect) -> bool:
	return _array.has(active)


func has_temps() -> bool:
	return !_only_temps.is_empty()


func has_blockers() -> bool:
	return !_only_blockers.is_empty()


func has_modifiers() -> bool:
	return !_only_modifiers.is_empty()


func clear() -> void:
	_array.clear()
	_only_temps.clear()
	_only_blockers.clear()
	_only_modifiers.clear()

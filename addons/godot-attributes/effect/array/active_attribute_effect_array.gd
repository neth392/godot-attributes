## This class serves as a wrapper of an [Array] of [ActiveAttributeEffect]s which
## supports mutations during iteration. This works by using 2 arrays; one to
## iterate, and another to mutate. When the iterable array is done being iterated,
## it is then asssigned the mutated array's elements.
@tool
class_name ActiveAttributeEffectArray extends Resource

# Array which can be iterable. No mutations are made to it.
var _iterable_array: Array[ActiveAttributeEffect]
# Array which mutations are made to.
var _data_array: Array[ActiveAttributeEffect]
var _data_array_changed: bool = false
var _safe_iteration_count: int = 0:
	set(value):
		assert(value >= 0, "_safe_iteration_count set to (%s) but value can not be < 0" % value)
		_safe_iteration_count = value
var _unsafe_iteration_count: int = 0:
	set(value):
		assert(value >= 0, "_unsafe_iteration_count set to (%s) but value can not be < 0" % value)
		_unsafe_iteration_count = value

var _break_loop: bool = false

@export_storage var _same_priority_sorting_method: Attribute.SamePrioritySortingMethod
@export_storage var _modify_is_added: bool
@export_storage var _storage_array: Array[ActiveAttributeEffect]:
	set(_value):
		_data_array = _value
	get():
		var array: Array[ActiveAttributeEffect] = []
		for active: ActiveAttributeEffect in _data_array:
			if !active.get_effect().omit_from_save:
				array.append(active)
		return array

func _init(same_priority_sorting_method: Attribute.SamePrioritySortingMethod = \
Attribute.SamePrioritySortingMethod.OLDER_FIRST, modify_is_added: bool = false) -> void:
	_same_priority_sorting_method = same_priority_sorting_method
	_modify_is_added = modify_is_added


func for_each_block_mutations(active_consumer: Callable) -> void:
	assert(active_consumer.is_valid(), "active_consumer (%s) is invalid" % active_consumer)
	assert(active_consumer.get_argument_count() == 1, ("active_consumer (%s) must have only 1" + \
	"argument of type ActiveAttributeEffect") % active_consumer)
	
	_unsafe_iteration_count += 1
	
	for active: ActiveAttributeEffect in _data_array:
		active_consumer.call(active)
		if _break_loop:
			_break_loop = false
			break
	
	_unsafe_iteration_count -= 1


## Executes the [param active_consumer] for each element in this array, excluding any pending
## additions & removals. Mutating this instance within [member active_consumer] is safe as long as
## [param allow_mutations] is true. If [param allow_mutations] is false, mutations can not be
## made & errors will be thrown.
func for_each_allow_mutations(active_consumer: Callable) -> void:
	assert(_unsafe_iteration_count <= 0, "can not call for_each_allow_mutations while inside " + \
	"for_each_block_mutations")
	assert(active_consumer.is_valid(), "active_consumer (%s) is invalid" % active_consumer)
	assert(active_consumer.get_argument_count() == 1, ("active_consumer (%s) must have only 1" + \
	"argument of type ActiveAttributeEffect") % active_consumer)
	
	_safe_iteration_count += 1
	
	for active: ActiveAttributeEffect in _iterable_array:
		active_consumer.call(active)
		if _break_loop:
			_break_loop = false
			break
	
	_safe_iteration_count -= 1
	
	if _safe_iteration_count == 0 && _data_array_changed:
		_data_array_changed = false
		_iterable_array.assign(_data_array)

## Finds & returns the first [ActiveAttributeEffect]s which [param active_predicate]
## returns true for when that active is passed as the sole argument.
## [br]WARNING: It is NOT safe to mutate the array during this call. Do not emit signals
## or anything that could allow other unvalidated code to execute.
func find_first(active_predicate: Callable) -> ActiveAttributeEffect:
	assert(active_predicate.get_argument_count() == 1, ("active_predicate (%s) must only " + \
	"have 1 argument of type ActiveAttributeEffect") % active_predicate)
	for active: ActiveAttributeEffect in _data_array:
		if active_predicate.call(active) == true:
			return active
	return null


## Finds & returns an array of all [ActiveAttributeEffect]s which [param active_predicate]
## returns true for when that active is passed as the sole argument.
## [br]WARNING: It is NOT safe to mutate the array during this call. Do not emit signals
## or anything that could allow other unvalidated code to execute.
func find_all(active_predicate: Callable) -> Array[ActiveAttributeEffect]:
	var actives: Array[ActiveAttributeEffect] = []
	for active: ActiveAttributeEffect in _data_array:
		if active_predicate.call(active) == true:
			actives.append(active)
	return actives


## Breaks the current loop.
func break_for_each() -> void:
	assert(_safe_iteration_count > 0 || _unsafe_iteration_count > 0, "not currently iterating")
	_break_loop = true


## Adds [param active] to this array.
func add(active: ActiveAttributeEffect) -> void:
	assert(_unsafe_iteration_count <= 0, "can not mutate this array while inside for_each_block_mutations()")
	assert(active != null, "active is null")
	assert(!_data_array.has(active), "%s already added to this array" % active)
	assert(!_modify_is_added || !active._is_added, "%s already added to another array" % active)
	
	if _modify_is_added:
		active._is_added = true
	
	# It is quicker to insert an element at a specific position than
	# it is to append it & resort the entire array.
	var index: int = 0
	for other_active: ActiveAttributeEffect in _data_array:
		if _sort_new_before_other(active, other_active):
			_data_array.insert(index, active)
			break
		index += 1
	
	# Append if index hit the array's size, meaning it should be sorted last.
	if index == _data_array.size():
		_data_array.append(active)
	
	if _safe_iteration_count == 0:
		_iterable_array.assign(_data_array)
	else:
		_data_array_changed = true


## Erases [param active] from this array. If [param safe] is true, an error
## is not thrown if the element is not present in the array.
func erase(active: ActiveAttributeEffect, safe: bool = false) -> void:
	assert(_unsafe_iteration_count <= 0, "can not mutate this array while inside for_each_block_mutations()")
	assert(active != null, "active is null")
	assert(safe || _data_array.has(active), "%s not found in this array" % active)
	assert(!_modify_is_added || safe || active._is_added, "%s not added to any array" % active)
	
	if safe && !_data_array.has(active):
		return
	
	if _modify_is_added:
		active._is_added = false
	
	_data_array.erase(active)
	
	if _safe_iteration_count == 0:
		_iterable_array.assign(_data_array)
	else:
		_data_array_changed = true


## Clears the array. If currently iterating, [method break_for_each] is called
##& the array will be cleared immediately after.
func clear() -> void:
	assert(_unsafe_iteration_count <= 0, "can not mutate this array while inside for_each_block_mutations()")
	if _modify_is_added:
		for active: ActiveAttributeEffect in _data_array:
			active._is_added = false
	_data_array.clear()
	if _safe_iteration_count == 0:
		break_for_each()
		_iterable_array.clear()
	else:
		_data_array_changed = true


## Returns true if [param active]'s [member ActiveAttributeEffect._is_added] is true and
## it is within this array, false if not. Accounts for pending
## removals & additions.
func has(active: ActiveAttributeEffect) -> bool:
	return active._is_added && _data_array.has(active)


## Returns true if this array is empty, false if not. Accounts for pending changes.
func is_empty() -> bool:
	return _data_array.is_empty()


## Returns a duplicate of the underlying data array.
func duplicate_array() -> Array[ActiveAttributeEffect]:
	return _data_array.duplicate(false)


func _sort_new_before_other(new: ActiveAttributeEffect, other: ActiveAttributeEffect) -> bool:
	if new.get_effect().type != other.get_effect().type:
		return new.get_effect().type < other.get_effect().type
	if new.get_effect().priority == other.get_effect().priority:
		match _same_priority_sorting_method:
			Attribute.SamePrioritySortingMethod.OLDER_FIRST:
				return false
			Attribute.SamePrioritySortingMethod.NEWER_FIRST:
				return true
			_:
				assert(false, "no implementation for _same_priority_sorting_method (%s)" \
				% _same_priority_sorting_method)
	return new.get_effect().priority > other.get_effect().priority

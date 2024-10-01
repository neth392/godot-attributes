## This class serves as a wrapper of an [Array] of [ActiveAttributeEffect]s
## that has a built in "pending" system to allow adding/removing active effects
## from an attribute even when being iterated.
@tool
class_name ActiveAttributeEffectArray extends Resource

enum _PendingAction {
	CLEAR,
	ADD,
	ERASE
}

var _same_priority_sorting_method: Attribute.SamePrioritySortingMethod
var _array: Array[ActiveAttributeEffect]
var _pending_actions: Array[Array]
var _pending_add: Array[ActiveAttributeEffect]
var _pending_erase: Array[ActiveAttributeEffect]
var _is_iterating: bool = false


func _init(same_priority_sorting_method: Attribute.SamePrioritySortingMethod = \
Attribute.SamePrioritySortingMethod.OLDER_FIRST) -> void:
	_same_priority_sorting_method = same_priority_sorting_method


func for_each(active_consumer: Callable) -> void:
	assert(!_is_iterating, "nested iteration of this array not currently supported")
	assert(active_consumer.is_valid(), "active_consumer (%s) is invalid" % active_consumer)
	assert(active_consumer.get_argument_count() == 1, ("active_consumer (%s) must have only 1" + \
	"argument of type ActiveAttributeEffect") % active_consumer)
	_is_iterating = true
	for active: ActiveAttributeEffect in _array:
		active_consumer.call(active)
	_is_iterating = false
	for pending: Array in _pending_actions:
		assert(!pending.is_empty(), "_pending_actions contains empty array")
		match pending[0]:
			_PendingAction.CLEAR:
				_array.clear()
			_PendingAction.ADD:
				assert(pending.size() == 2, "pending (%s) size != 2" % pending)
				_add_skip_check(pending[1])
			_PendingAction.ERASE:
				assert(pending.size() == 2, "pending (%s) size != 2" % pending)
				_array.erase(pending[1])
			_:
				assert(false, "no implementation for _PendingAction (%s)" % pending[0])
	_pending_actions.clear()
	_pending_add.clear()
	_pending_erase.clear()


func add(active: ActiveAttributeEffect) -> void:
	assert(active != null, "active is null")
	# Add to pending if iterating
	if _is_iterating:
		_add_pending_action(_PendingAction.ADD, active)
		return
	
	_add_skip_check(active)


func _add_skip_check(active: ActiveAttributeEffect) -> void:
	# It is quicker to insert an element at a specific position than
	# it is to append it & resort the entire array.
	var index: int = 0
	for other_active: ActiveAttributeEffect in _array:
		if _sort_new_before_other(active, other_active):
			_array.insert(index, active)
			break
		index += 1
	
	# Append if not added during loop
	# Per godot docs, .resize & then setting the element is faster than append
	if index == _array.size():
		_array.resize(_array.size() + 1)
		_array[_array.size() -1 ] = active


func erase(active: ActiveAttributeEffect) -> void:
	assert(active != null, "active is null")
	# Add to pending if iterating
	if _is_iterating:
		_add_pending_action(_PendingAction.ERASE, active)
		return
	_array.erase(active)


func has(active: ActiveAttributeEffect) -> bool:
	if !_is_iterating:
		return _array.has(active)
	return (_array.has(active) && !_pending_erase.has(active)) || _pending_add.has(active)


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


func is_empty() -> bool:
	return _array.is_empty()


func clear() -> void:
	if _is_iterating:
		_add_pending_action(_PendingAction.CLEAR, null)
		return
	_array.clear()


func _add_pending_action(action: _PendingAction, active: ActiveAttributeEffect) -> void:
	assert(_is_iterating, "can't add pending action when not iterating")
	_pending_actions.append([action, active])
	match action:
		_PendingAction.ADD:
			_pending_add.append(active)
			_pending_erase.erase(active)
		_PendingAction.ERASE:
			_pending_erase.append(action)
			_pending_add.erase(action)

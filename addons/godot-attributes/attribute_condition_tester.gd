## Checking conditions for adding & applying share the same logic, but a lot of
## functions, variables, & signal(s) used differ. The cleanest (and I assume most efficient)
## way to keep that logic the same & not copy/paste it was to create this class and 
## create a few simple methods overridden 
class_name AttributeConditionTester extends Object

static var _permanent_apply: AttributeConditionTester = ApplyTester.new()
static var _temporary: AttributeConditionTester = TemporaryApplyTester.new()
static var _add: AttributeConditionTester = AddTester.new()


## Returns the implementation for applying permanent effects to an attribute.
static func for_permanent_apply() -> AttributeConditionTester:
	return _permanent_apply


## Returns the implementation for applying temporary effects to an attribute.
static func for_temporary_apply() -> AttributeConditionTester:
	return _permanent_apply


## Returns the implementation for adding effects to an attribute. No difference between
## permanent & temporary actives for this impl.
static func for_add() -> AttributeConditionTester:
	return _add


## Tests all relevant [AttributeEffectCondition]s on [param active], returning true if no condition
## was failed, or false if a condition was failed.
	# Check active's own conditions
func test(attribute: Attribute, active: ActiveAttributeEffect, event: AttributeEvent) -> bool:
	if _has_own_conditions(active.get_effect()):
		# Find blocking condition, if any
		var blocking_condition: AttributeEffectCondition = _test_condition_array(attribute, active, 
		_get_own_conditions(active.get_effect()))
		
		# Check if blocked by a condition
		if blocking_condition != null:
			# Set last blocked by
			active._last_blocked_by = blocking_condition
			active._last_blocked_by_source = weakref(active)
			
			# Handle the event
			_handle_event(active, event)
			
			# Emit monitor signal 
			if blocking_condition.emit_blocked_signal:
				attribute._in_monitor_signal_or_callback = true
				_get_blocked_signal(attribute).emit(blocking_condition)
				attribute._in_monitor_signal_or_callback = false
			return false
	
	# Iterate BLOCKER effects
	if !attribute._actives.blockers.is_empty():
		var all_conditions_pass: AttributeUtil.Reference = AttributeUtil.Reference.new(true)
		attribute._actives.blockers.for_each(
			func(blocker: ActiveAttributeEffect) -> void:
				if !blocker.is_added() || blocker.is_expired():
					return
				
				# Find blocking condition, if any
				var blocking_condition: AttributeEffectCondition = _test_condition_array(attribute, active, 
				_get_blocker_conditions(blocker.get_effect()))
				
				# Check if blocked by a condition
				if blocking_condition.ref != null:
					# Set failed
					all_conditions_pass.ref = false
					
					# Set last blocked by
					active._last_blocked_by = blocking_condition
					active._last_blocked_by_source = weakref(blocker)
					
					# Handle the event
					_handle_event(active, event)
					
					# Emit monitor signal
					if blocking_condition.emit_blocked_signal:
						attribute._in_monitor_signal_or_callback = true
						_get_blocked_signal(attribute).emit(blocking_condition)
						attribute._in_monitor_signal_or_callback = false
					
					# Break this loop
					attribute._actives.break_for_each()
		, false) # Unsafe iteration (array is not mutated)
		
		return all_conditions_pass.ref
	
	return true


func _test_condition_array(attribute: Attribute, active_to_test: ActiveAttributeEffect, 
conditions: Array[AttributeEffectCondition]) -> AttributeEffectCondition:
	for condition: AttributeEffectCondition in conditions:
		if !condition.meets_condition(attribute, active_to_test):
			return condition
	return null


func _get_blocked_signal(attribute: Attribute) -> Signal:
	assert(false, "_get_blocked_signal not implemented")
	return Signal()


func _has_own_conditions(effect: AttributeEffect) -> bool:
	assert(false, "_has_conditions not implemented")
	return false


func _get_own_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
	assert(false, "_get_own_conditions not implemented")
	return []


func _get_blocker_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
	assert(false, "_get_blocker_conditions not implemented")
	return []


func _handle_event(active: ActiveAttributeEffect, event: AttributeEvent) -> void:
	# No error here, usually this does nothing
	pass


## Implementation for applying effects to an attribute
class ApplyTester extends AttributeConditionTester:
	
	func _get_blocked_signal(attribute: Attribute) -> Signal:
		return attribute.monitor_active_apply_blocked
	
	func _has_own_conditions(effect: AttributeEffect) -> bool:
		return effect.has_apply_conditions()
	
	func _get_own_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
		return effect.apply_conditions
	
	func _get_blocker_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
		return effect.apply_blockers

class TemporaryApplyTester extends ApplyTester:
	
	func _handle_event(active: ActiveAttributeEffect, event: AttributeEvent) -> void:
		event._blocked_temporary_actives[active] = null


## Implementation for adding effects to an attribute
class AddTester extends AttributeConditionTester:
	
	func _get_blocked_signal(attribute: Attribute) -> Signal:
		return attribute.monitor_active_add_blocked
	
	func _has_own_conditions(effect: AttributeEffect) -> bool:
		return effect.has_add_conditions()
	
	func _get_own_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
		return effect.add_conditions
	
	func _get_blocker_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
		return effect.add_blockers
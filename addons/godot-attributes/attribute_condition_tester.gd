## Checking conditions for adding & applying share the same logic, but a lot of
## functions, variables, & signal(s) used differ. The cleanest (and I assume most efficient)
## way to keep that logic the same & not copy/paste it was to create this class and 
## create a few simple methods overridden 
class_name AttributeConditionTester extends Object

static var _permanent_apply: AttributeConditionTester = ApplyTester.new()
static var _temporary: AttributeConditionTester = TemporaryApplyTester.new()
static var _add: AttributeConditionTester = AddTester.new()


## Returns the implementation for applying permanent effects to an attribute.
static func permanent_apply() -> AttributeConditionTester:
	return _permanent_apply


## Returns the implementation for applying temporary effects to an attribute.
static func temporary_apply() -> AttributeConditionTester:
	return _permanent_apply


## Returns the implementation for adding effects to an attribute. No difference between
## permanent & temporary actives for this impl.
static func add() -> AttributeConditionTester:
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
				attribute._in_hook = true
				_emit_blocked_signal(attribute, active)
				attribute._in_hook = false
			return false
	
	# Iterate BLOCKER effects
	var blockers: ActiveAttributeEffectArray = _get_blockers(attribute._actives)
	if !blockers.is_empty():
		var all_conditions_pass: AttributeUtil.Reference = AttributeUtil.Reference.new(true)
		blockers.for_each_block_mutations(
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
						attribute._in_hook = true
						_emit_blocked_signal(attribute, active)
						attribute._in_hook = false
					
					# Break this loop
					attribute._actives.break_for_each()
		)
		
		return all_conditions_pass.ref
	
	return true


func _test_condition_array(attribute: Attribute, active_to_test: ActiveAttributeEffect, 
conditions: Array[AttributeEffectCondition]) -> AttributeEffectCondition:
	for condition: AttributeEffectCondition in conditions:
		if !condition.meets_condition(attribute, active_to_test):
			return condition
	return null


func _emit_blocked_signal(attribute: Attribute, active: ActiveAttributeEffect) -> void:
	assert(false, "_get_blocked_signal not implemented")
	return Signal()


func _has_own_conditions(effect: AttributeEffect) -> bool:
	assert(false, "_has_conditions not implemented")
	return false


func _get_own_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
	assert(false, "_get_own_conditions not implemented")
	return []


func _get_blockers(cluster: ActiveAttributeEffectCluster) -> ActiveAttributeEffectArray:
	assert(false, "_get_blockers not implemented")
	return null


func _get_blocker_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
	assert(false, "_get_blocker_conditions not implemented")
	return []


func _handle_event(active: ActiveAttributeEffect, event: AttributeEvent) -> void:
	# No error here, usually this does nothing
	pass


## Implementation for applying effects to an attribute
class ApplyTester extends AttributeConditionTester:
	
	func _emit_blocked_signal(attribute: Attribute, active: ActiveAttributeEffect) -> void:
		attribute.monitor_active_apply_blocked.emit(active)
	
	func _has_own_conditions(effect: AttributeEffect) -> bool:
		return effect.has_apply_conditions
	
	func _get_own_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
		return effect.apply_conditions
	
	func _get_blockers(cluster: ActiveAttributeEffectCluster) -> ActiveAttributeEffectArray:
		return cluster.apply_blockers
	
	func _get_blocker_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
		return effect.apply_blockers


class TemporaryApplyTester extends ApplyTester:
	
	func _handle_event(active: ActiveAttributeEffect, event: AttributeEvent) -> void:
		event._blocked_temporary_actives[active] = null


## Implementation for adding effects to an attribute
class AddTester extends AttributeConditionTester:
	
	func _emit_blocked_signal(attribute: Attribute, active: ActiveAttributeEffect) -> void:
		attribute.monitor_active_add_blocked.emit(active)
	
	func _has_own_conditions(effect: AttributeEffect) -> bool:
		return effect.has_add_conditions
	
	func _get_own_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
		return effect.add_conditions
	
	func _get_blockers(cluster: ActiveAttributeEffectCluster) -> ActiveAttributeEffectArray:
		return cluster.add_blockers
	
	func _get_blocker_conditions(effect: AttributeEffect) -> Array[AttributeEffectCondition]:
		return effect.add_blockers

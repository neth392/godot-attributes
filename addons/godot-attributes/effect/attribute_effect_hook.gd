## Hooks provide a set of extra functionality to [AttributeEffect]s without
## the need to write it directly in code. The functionality is somewhat limited as the
## hook functions are called [i]instantly[/i] after that specific action has occurred
## within the [Attribute], and not a bit later in the stack like [AttributeEvent]s. Anything
## relating to adding/removing effects from an attribute are not supported, but 
## TODO fix above docs on a clear mind
@tool
class_name AttributeEffectHook extends Resource

enum _Function {
	BEFORE_ACTIVE_ADDED = 0,
	AFTER_ACTIVE_ADDED = 1,
	AFTER_ACTIVE_APPLIED = 2,
	BEFORE_ACTIVE_REMOVED = 3,
	AFTER_ACTIVE_REMOVED = 4,
	AFTER_ACTIVE_STACK_CHANGED = 5,
}

static var _temporary_functions: Array[_Function] = [
		_Function.BEFORE_ACTIVE_ADDED,
		_Function.AFTER_ACTIVE_ADDED,
		_Function.BEFORE_ACTIVE_REMOVED,
		_Function.AFTER_ACTIVE_REMOVED,
		_Function.AFTER_ACTIVE_STACK_CHANGED,
	]

static var _function_names: Dictionary[_Function, String] = {
	_Function.BEFORE_ACTIVE_ADDED: "_before_active_added",
	_Function.AFTER_ACTIVE_ADDED: "_after_active_added",
	_Function.AFTER_ACTIVE_APPLIED: "_after_active_applied",
	_Function.BEFORE_ACTIVE_REMOVED: "_before_active_removed",
	_Function.AFTER_ACTIVE_REMOVED: "_after_active_removed",
	_Function.AFTER_ACTIVE_STACK_CHANGED: "_after_active_stack_changed",
}

static var _functions_by_name: Dictionary[String, _Function]

static func _init() -> void:
	# Populate _functions_by_name
	for _function: _Function in _function_names:
		_functions_by_name[_function_names[_function]] = _function

# Used to detect what functions a hook has implemented - trickery here is that
# in the Array Script.get_script_method_list() returns, methods will appear more
# than once if the current or any parent script has overridden them.
static func _set_functions(hook: AttributeEffectHook):
	if hook._functions_set:
		return
	var script: Script = hook.get_script() as Script
	assert(script != null, "hook.get_script() doesnt return a Script type")
	var non_inherited_functions: Dictionary[_Function, bool] = {}
	var inherited_functions: Dictionary[_Function, bool] = {}
	
	for method: Dictionary in script.get_script_method_list():
		if _functions_by_name.has(method.name):
			var _function: _Function = _functions_by_name.get(method.name)
			if non_inherited_functions.has(_function):
				inherited_functions[_function] = true
			else:
				non_inherited_functions[_function] = true
	
	hook._functions_set = true
	hook._functions.assign(inherited_functions.keys())


static func _can_run(_function: _Function, effect: AttributeEffect) -> bool:
	if effect.type == AttributeEffect.Type.TEMPORARY:
		return _temporary_functions.has(_function)
	return true


var _functions_set: bool = false
# Internal cache of what functions are overridden
var _functions: Array[_Function] = []


## Editor tool function that is called when this hook is added to [param effect].
## Write assertions here so that hooks aren't added to effects they won't play nicely with.
func _run_assertions(effect: AttributeEffect) -> void:
	pass


## Called before the [param active] is to be added to the [param attribute].
func _before_active_added(attribute: Attribute, active: ActiveAttributeEffect, 
event: AttributeEvent) -> void:
	pass


## Called after the [param active] has been added to the [param attribute].
func _after_active_added(attribute: Attribute, active: ActiveAttributeEffect, 
event: AttributeEvent) -> void:
	pass


## Called after the [param active] has been applied to the [param attribute].
## [br]NOTE: ONLY called for PERMANENT effects.
func _after_active_applied(attribute: Attribute, active: ActiveAttributeEffect, 
event: AttributeEvent) -> void:
	pass


## Called before the [param active] is to be removed from the [param attribute].
func _before_active_removed(attribute: Attribute, active: ActiveAttributeEffect, 
event: AttributeEvent) -> void:
	pass


## Called after the [param active] has been removed from the [param attribute].
func _after_active_removed(attribute: Attribute, active: ActiveAttributeEffect, 
event: AttributeEvent) -> void:
	pass


## Called after the [param active]'s stack count has changed. [param previous_stack_count] was
## the previous count before the change.
func _after_stack_changed(attribute: Attribute, active: ActiveAttributeEffect,
event: AttributeEvent, previous_stack_count: int) -> void:
	pass

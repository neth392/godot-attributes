## An effect that can cause changes to an [Attribute]'s value, among many other functionalities.
## WARNING: This resource is not meant to be modified while [ActiveAttributeEffect]s derived
## from it are applied to an [Attribute]. It could result in unexpected behavior & break things.
## TODO: Address the above warning by "snapshotting" the effect and setting that to the
## [ActiveAttributeEffect] instead of this actual instance.
@tool
class_name AttributeEffect extends Resource

## The type of effect.
## [br] NOTE: This enum's structure determines the ordering of [ActiveAttributeEffectArray].
enum Type {
	## Makes temporary changes to an [Attribute] reflected in 
	## [method Attribute.get_current_value].
	TEMPORARY = 0,
	## Makes permanent changes to an [Attribute]'s base value.
	PERMANENT = 1,
}

## Determines how this effect can be stacked on an [Attribute], if at all.
enum StackMode {
	## Stacking is not allowed.
	DENY = 0,
	## Stacking is not allowed and an assertion will be called
	## if there is an attempt to stack this effect on an [Attribute].
	DENY_ERROR = 1,
	## Attribute effects are seperate, a new [ActiveAttributeEffect] is created
	## for every instance added to an [Attribute].
	SEPERATE = 2,
	## Attribute effects are combined into one [ActiveAttributeEffect] whose
	## [member ActiveAttributeEffect._stack_count] is increased accordingly.
	COMBINE = 3,
}

## Determines how the effect is applied time-wise.
enum DurationType {
	## The effect is applied to an [Attribute] and remains until it is explicitly
	## removed.
	INFINITE = 0,
	## The effect is applied to an [Attribute] and is removed automatically
	## after [member duration_seconds].
	HAS_DURATION = 1,
	## The effect is immediately applied to an [Attribute] and does not remain
	## stored on it.
	INSTANT = 2,
}

## The ID of this attribute effect.
@export var id: StringName

## The priority to be used to determine the order when processing & applying [AttributeEffect]s
## on an [Attribute]. Greater priorities will be processed & applied first. If two effects have
## equal priorities, [member Attribute.same_priority_sorting_method] determines which is procssed &
## applied first. 
## [br]If you want a temporary effect to override a value on an attribute & not have
## that value modified by any other effects, then the priority should be lesser than other effects 
## so the override effect is applied last.
## [br]NOTE: Effects are first sorted by type [enum Type.TEMPORARY] then [enum Type.PERMANENT].
@export var priority: int = 0

## Metadata tags to help identify an effect. Similar to an [AttributeContainer]'s tags.
## One use case would be to use tags as a category of effect, i.e. "poison" for all
## poison damage effects.
@export var tags: Array[StringName]

## The type of effect, see [enum AttributeEffect.Type]
@export var type: Type = Type.PERMANENT:
	set(_value):
		type = _value
		if type != Type.PERMANENT && duration_type == DurationType.INSTANT:
			# INSTANT not compatible with TEMPORARY or BLOCKER
			duration_type = DurationType.INFINITE
		if type == Type.PERMANENT && !has_value:
			has_value = true
		notify_property_list_changed()

## If true, this effect must have a [member value] which applies to an [Attribute].
@export var has_value: bool:
	set(_value):
		has_value = _value
		assert(!must_have_value() || has_value, "must_have_value() is true but has_value is false")
		notify_property_list_changed()

## The value that is applied to an [Attribute]'s value (base or current, based on
## [member type]).
@export var value: AttributeEffectValue

## Determines how the [member value] is applied to an [Attribute] (i.e. added, multiplied, etc).
@export var value_calculator: AttributeEffectCalculator

@export_group("Signals")

## If true, [signal Attribute.effect_added] will be emitted every time an
## [ActiveAttributeEffect] of this effect is added to an [Attribute].
@export var _emit_added_signal: bool = false

## If true, [signal Attribute.effect_applied] will be emitted every time an
## [ActiveAttributeEffect] of this effect is successfully applied on an [Attribute].
## [br]NOTE: ONLY AVAILABLE FOR [enum Type.PERMANENT] as TEMPORARY effects are not reliably applied.
@export var _emit_applied_signal: bool = false

## If true, [signal Attribute.effect_removed] will be emitted every time an
## [ActiveAttributeEffect] of this effect is removed from an [Attribute].
@export var _emit_removed_signal: bool = false

@export_group("Duration")

## How long the effect lasts.
@export var duration_type: DurationType:
	set(_value):
		assert(_value != DurationType.INSTANT || can_be_instant(), "duration_type can not" + \
		"be INSTANT when type != PERMANENT")
		if type == Type.TEMPORARY && _value == DurationType.INSTANT:
			duration_type = DurationType.INFINITE
			return
		duration_type = _value
		notify_property_list_changed()

## The amount of time in seconds this [AttributeEffect] lasts.
@export var duration_in_seconds: AttributeEffectValue

## If the effect should automatically be applied when it's duration expires.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var _apply_on_expire: bool = false:
	set(_value):
		assert(!_value || can_apply_on_expire(), "_apply_on_expire can not be true when " +\
		"duration_type != HAS_DURATION or when type != PERKMANENT")
		_apply_on_expire = _value
		notify_property_list_changed()

@export_group("Apply Limit")

## If true, [member apply_limit_amount] is the maximum amount of times an effect
## can apply. If the limit is hit, the effect is removed immediately.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var _apply_limit: bool = false:
	set(_value):
		assert(!_apply_limit || can_have_apply_limit(), "_apply_limit can not be true when " +\
		"duration_type == INSTANT or when type != PERMANENT")
		_apply_limit = _value
		notify_property_list_changed()

## The maximum amount of times this effect can be applied to an [Attribute], inclusive. If this
## number is reached, the effect is then instantly removed from the [Attribute].
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export_range(1, 100, 1, "or_greater", "hide_slider") var apply_limit_amount: int:
	set(_value):
		if !Engine.is_editor_hint() && has_apply_limit():
			assert(_value > 0, "apply_limit_amount must be > 0")
		apply_limit_amount = _value

## If true, whenever this effect's apply is blocked by an [AttributeEffectCondition],
## the internal apply count used in the apply limit system will still increment.
@export var count_apply_if_blocked: bool = false

@export_group("Period")

## Amount of time, in seconds, between when this effect is applied to an [Attribute].
## [br]Zero or less means every frame.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var period_in_seconds: AttributeEffectValue

## If [member period_in_seconds] should apply as a "delay" between when this effect 
## is added to an [Attribute] and its first time applying.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var initial_period: bool = false

## For special edge cases, if true the effect will be applied on it's expiration if
## the remaining period has reached 0.0 at the same frame. If [member _apply_on_expire]
## is true, this property is meaningless.
## [br]For example, if an effect has a duration of 5 seconds, and a period of 1, it
## will be applied when it expires as the remaining period for the next application
## will reach zero on the same frame.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var _apply_on_expire_if_period_is_zero: bool = false

@export_group("Stacking")

## The [StackMode] to use when duplicate [AttributeEffect]s are found.
@export var stack_mode: StackMode:
	set(_value):
		if duration_type == DurationType.INSTANT && _value == StackMode.COMBINE:
			stack_mode = StackMode.DENY
			return
		stack_mode = _value
		notify_property_list_changed()

@export_group("Attribute History")

## If true, anytime this effect is applied to an [Attribute] it is registered
## in that attribute's [AttributeHistory] if one exists.
@export var _log_history: bool = false

@export_group("Conditions")

## All [AttributeEffectCondition]s that must be met for this effect to be
## added to an [Attribute]. This array can safely be directly modified or set.
##[br]NOTE: Not supported for INSTANT effects, as they are just applied & not added.
@export var add_conditions: Array[AttributeEffectCondition]

## All [AttributeEffectCondition]s that must be met for this effect to be
## applied to an [Attribute]. This array can safely be directly modified or set.[br]
## [br]NOTE: When using with TEMPORARY effects, [method Attribute.update_current_value]
## will need to be called manually if a condition changes. That fucntion is only automatically
## called when an effect is added/removed or a PERMANENT effect is applied.
@export var apply_conditions: Array[AttributeEffectCondition]

@export_group("Hooks")

## List of [AttributeEffectHook]s to extend the functionality of this effect
## further than modifying the value of an [Attribute].
@export var _hooks: Array[AttributeEffectHook]:
	set(_value):
		_hooks = _value
		if !Engine.is_editor_hint():
			for hook: AttributeEffectHook in _hooks:
				_add_hook_internal(hook, false)
		else:
			for hook: AttributeEffectHook in _hooks:
				hook._run_assertions(self)

@export_group("Blockers")

## If true, this effect can utilize [member add_blockers] which
## are sets of [AttributeEffectCondition]s that can block other [AttributeEffect]s
## from being added to any [Attribute] this effect is currently added to.
## Only applicable for non-instant effects.
@export var _add_blocker: bool = false:
	set(value):
		_add_blocker = value
		notify_property_list_changed()

## Blocks other [AttributeEffect]s from being added to an [Attribute] if they
## do NOT meet any of these conditions. Only used if [member _add_blocker] is true.
@export var add_blockers: Array[AttributeEffectCondition]

## If true, this effect can utilize [member apply_blockers] which
## are sets of [AttributeEffectCondition]s that can block other [AttributeEffect]s
## from applying to any [Attribute] this effect is currently added to.
## Only applicable for non-instant effects, and only applicable for non-instant effects.
@export var _apply_blocker: bool = false:
	set(value):
		_apply_blocker = value
		notify_property_list_changed()

## Blocks other [AttributeEffect]s from being applied to an [Attribute] if they
## do NOT meet any of these conditions. Only used if [member _apply_blocker] is true,
## and only applicable for non-instant effects.
@export var apply_blockers: Array[AttributeEffectCondition]

@export_group("Modifiers")

## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the value of other [AttributeEffect]s. Only applicable for non-instant effects.
@export var _value_modifier: bool = false:
	set(value):
		_value_modifier = value
		notify_property_list_changed()

## Modifies the [member value] of other [AttributeEffect]s.
## Only used if [member _value_modifier] is true, and only applicable for
## non-instant effects.
@export var value_modifiers: AttributeEffectModifierArray

## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the period of other [AttributeEffect]s. Only applicable for non-instant effects.
@export var _period_modifier: bool = false:
	set(value):
		_period_modifier = value
		notify_property_list_changed()

## Modifies the [member period_in_seconds] of other [AttributeEffect]s.
## Only used if [member _period_modifier] is true, and only applicable for
## non-instant effects.
@export var period_modifiers: AttributeEffectModifierArray

## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the duration of other [AttributeEffect]s. Only applicable for non-instant effects.
@export var _duration_modifier: bool = false:
	set(value):
		_duration_modifier = value
		notify_property_list_changed()

## Modifies the [member duration_in_seconds] of other [AttributeEffect]s.
## Only used if [member _duration_modifier] is true, and only applicable for
## non-instant effects.
@export var duration_modifiers: AttributeEffectModifierArray

@export_group("Metadata")

## A simple [Dictionary] that can be used to store metadata for effects. Not
## used in any of the Attribute system's internals.
@export var metadata: Dictionary[Variant, Variant]

var _hooks_by_function: Dictionary[AttributeEffectHook._Function, Array]
var _block_runtime_modifications: bool = false:
	set(value):
		_block_runtime_modifications = true

func _init(_id: StringName = "") -> void:
	id = _id
	if Engine.is_editor_hint():
		return
	
	# Hook initialization
	for _function: int in AttributeEffectHook._Function.values():
		_hooks_by_function[_function] = []


func _validate_property(property: Dictionary) -> void:
	if property.name == "value" || property.name == "value_calculator":
		if !has_value:
			_no_editor(property)
		return
	
	if property.name == "_emit_applied_signal":
		if !can_emit_applied_signal():
			_no_editor(property)
		return
	
	if property.name == "_emit_added_signal":
		if !can_emit_added_signal():
			_no_editor(property)
		return
	
	if property.name == "_emit_removed_signal":
		if !can_emit_removed_signal():
			_no_editor(property)
		return
	
	if property.name == "duration_type":
		var exclude: Array = [] if can_be_instant() else [DurationType.INSTANT]
		property.hint_string = _format_enum(DurationType, exclude)
		return
	
	if property.name == "duration_in_seconds":
		if !has_duration():
			_no_editor(property)
		return
	
	if property.name == "_apply_on_expire":
		if !can_apply_on_expire():
			_no_editor(property)
		return
	
	if property.name == "_apply_limit":
		if !can_have_apply_limit():
			_no_editor(property)
		return
	
	if property.name == "apply_limit_amount":
		if !can_have_apply_limit() || !_apply_limit:
			_no_editor(property)
		return
	
	if property.name == "count_apply_if_blocked":
		if !can_have_apply_limit() || !_apply_limit:
			_no_editor(property)
		return
	
	if property.name == "period_in_seconds" || property.name == "initial_period":
		if !has_period():
			_no_editor(property)
		return
	
	if property.name == "_apply_on_expire_if_period_is_zero":
		if !can_apply_on_expire_if_period_is_zero() || is_apply_on_expire():
			_no_editor(property)
		return
	
	if property.name == "stack_mode":
		if is_instant():
			_no_editor(property)
		return
	
	if property.name == "_log_history":
		if !can_log_history():
			_no_editor(property)
		return
	
	if property.name == "add_conditions":
		if !has_add_conditions():
			_no_editor(property)
		return
	
	if property.name == "apply_conditions":
		if !has_apply_conditions():
			_no_editor(property)
		return
	
	if property.name == "_add_blocker" || property.name == "_apply_blocker":
		if !can_be_blocker():
			_no_editor(property)
		return
	
	if property.name == "add_blockers":
		if !can_be_blocker() ||  !is_add_blocker():
			_no_editor(property)
		return
	
	if property.name == "apply_blockers":
		if !can_be_blocker() || !is_apply_blocker():
			_no_editor(property)
		return
	
	if property.name == "_value_modifier" \
	or property.name == "_period_modifier" \
	or property.name == "_duration_modifier":
		if !can_be_modifier():
			_no_editor(property)
		return
	
	if property.name == "value_modifiers":
		if !can_be_modifier() || !is_value_modifier():
			_no_editor(property)
		return
	
	if property.name == "period_modifiers":
		if !can_be_modifier() || !is_period_modifier():
			_no_editor(property)
		return
	
	if property.name == "duration_modifiers":
		if !can_be_modifier() || !is_duration_modifier():
			_no_editor(property)
		return


## Helper method for _validate_property.
func _no_editor(property: Dictionary) -> void:
	property.usage = PROPERTY_USAGE_STORAGE


## Helper method for _validate_property.
func _format_enum(_enum: Dictionary, exclude: Array) -> String:
	var hint_string: Array[String] = []
	for name: String in _enum.keys():
		var value: int = _enum[name]
		if exclude.has(value):
			continue
		hint_string.append("%s:%s" % [name.to_camel_case().capitalize(), value])
	return ",".join(hint_string)


## Adds the [param hook] from this effect. An assertion is in place to prevent
## multiple [AttributeEffectHook]s of the same instance being added to an effect.
func add_hook(hook: AttributeEffectHook) -> void:
	if Engine.is_editor_hint():
		hook._run_assertions(self)
	_add_hook_internal(hook, true)


func _add_hook_internal(hook: AttributeEffectHook, add_to_list: bool) -> void:
	assert(!add_to_list || !_hooks.has(hook), "hook (%s) already exists" % hook)
	AttributeEffectHook._set_functions(hook)
	if add_to_list:
		_hooks.append(hook)
	for _function: AttributeEffectHook._Function in hook._functions:
		assert(AttributeEffectHook._can_run(_function, self), "")
		_hooks_by_function[_function].append(hook)


## Removes the [param hook] from this effect. Returns true if the hook
## existed & was removed, false if not.
func remove_hook(hook: AttributeEffectHook) -> bool:
	if !_hooks.has(hook):
		return false
	_hooks.erase(hook)
	for _function: AttributeEffectHook._Function in hook._functions:
		_hooks_by_function[_function].erase(hook)
	return true


## Applies the [member value_calculator] on the [param attribute_value] and
## [param effect_value], returning the result. It must always be ensured that
## the [param effect_value] comes from [b]this effect[/b], otherwise results
## will be unexpected.
func apply_calculator(attr_base_value: float, attr_current_value: float, effect_value: float) -> float:
	assert_has_value()
	return value_calculator._calculate(attr_base_value, attr_current_value, effect_value)


## Shorthand function to create an [ActiveAttributeEffect] for this [AttributeEffect].
func create_active_effect() -> ActiveAttributeEffect:
	return ActiveAttributeEffect.new(self)


## TBD: Make this more verbose?
func _to_string() -> String:
	return "AttributeEffect(id:%s)" % id


##########################################
## Helper functions for feature support ##
##########################################

## Whether or not this effect MUST have [member value].
func must_have_value() -> bool:
	return type == Type.PERMANENT


## Asserts [member has_value] returns true.
func assert_has_value() -> void:
	assert(has_value, "effect does have a value")


## Returns true if this effect supports a [member duration_type] of 
## [enum DurationType.INSTANT].
func can_be_instant() -> bool:
	return type == Type.PERMANENT


## Returns true if this effect supports [member duration_type] of 
## [enum DurationType.INSTANT] and is currently INSTANT.
func is_instant() -> bool:
	return can_be_instant() && duration_type == DurationType.INSTANT


## Helper function returning true if the effect's type is 
## [enum AttributeEffect.Type.PERMANENT], false if not.
func is_permanent() -> bool:
	return type == AttributeEffect.Type.PERMANENT


## Helper function returning true if the effect's type is 
## [enum AttributeEffect.Type.TEMPORARY], false if not.
func is_temporary() -> bool:
	return type == AttributeEffect.Type.TEMPORARY


## Returns true if this effect can be an add or apply blocker.
func can_be_blocker() -> bool:
	return !is_instant()


## Returns true if this effect is an add or apply blocker.
func is_any_blocker() -> bool:
	return _add_blocker || _apply_blocker


## If true, this effect can utilize [member add_blockers] which
## are sets of [AttributeEffectCondition]s that can block other [AttributeEffect]s
## from being added to any [Attribute] this effect is currently added to.
func is_add_blocker() -> bool:
	return _add_blocker


## If true, this effect can utilize [member apply_blockers] which
## are sets of [AttributeEffectCondition]s that can block other [AttributeEffect]s
## from applying to any [Attribute] this effect is currently added to.func is_apply_blocker() -> bool:
func is_apply_blocker() -> bool:
	return _apply_blocker


## Returns true if this effect can be a modifier of value, duration, or period.
func can_be_modifier() -> bool:
	return !is_instant()


## Returns true if this effect is a value, duration, or period modifier.
func is_any_modifier() -> bool:
	return _value_modifier || _duration_modifier || _period_modifier


## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the value of other [AttributeEffect]s. Only applicable for non-instant effects.
func is_value_modifier() -> bool:
	return _value_modifier


## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the duration of other [AttributeEffect]s. Only applicable for non-instant effects.
func is_duration_modifier() -> bool:
	return _duration_modifier


## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the period of other [AttributeEffect]s. Only applicable for non-instant effects.
func is_period_modifier() -> bool:
	return _period_modifier


## Whether or not this effect supports [member add_conditions]
func has_add_conditions() -> bool:
	return duration_type != DurationType.INSTANT


## Whether or not this effect supports [member apply_conditions]
func has_apply_conditions() -> bool:
	return has_value


## Whether or not this effect can emit [signal Attribute.effect_added].
func can_emit_added_signal() -> bool:
	return duration_type != DurationType.INSTANT


## Whether or not this effect should cause [signal Attriubte.effect_added] to be
## emitted when an active effect of this effect is added.
func should_emit_added_signal() -> bool:
	return can_emit_added_signal() && _emit_added_signal


## Whether or not this effect can emit [signal Attribute.effect_applied].
func can_emit_applied_signal() -> bool:
	return type == Type.PERMANENT


## Whether or not this effect should cause [signal Attriubte.effect_applied] to be
## emitted when an active effect of this effect is applied.
func should_emit_applied_signal() -> bool:
	return can_emit_applied_signal() && _emit_applied_signal


## Whether or not this effect can emit [signal Attribute.effect_removed].
func can_emit_removed_signal() -> bool:
	return duration_type != DurationType.INSTANT


## Whether or not this effect should cause [signal Attriubte.effect_removed] to be
## emitted when an active effect of this effect is removed.
func should_emit_removed_signal() -> bool:
	return can_emit_removed_signal() && _emit_removed_signal


## Whether or not this effect supports [member apply_on_expire]
func can_apply_on_expire() -> bool:
	return duration_type == DurationType.HAS_DURATION && type == Type.PERMANENT


## Whether or not this effect should automatically apply on the same frame that it expires.
## Returns true if [method can_apply_on_expire] and [member _apply_on_expire] are both true.
func is_apply_on_expire() -> bool:
	return can_apply_on_expire() && _apply_on_expire


## Whether or not this effect supports [member _apply_on_expire_if_period_is_zero]
func can_apply_on_expire_if_period_is_zero() -> bool:
	return has_period()


## Whether or not this effect should automatically apply on the same frame that it expires
## ONLY IF the remaining period is <= 0.0
## Returns true if [method can_apply_on_expire_if_period_is_zero] and 
## [member _apply_on_expire_if_period_is_zero] are both true.
func is_apply_on_expire_if_period_is_zero() -> bool:
	return can_apply_on_expire_if_period_is_zero() && _apply_on_expire_if_period_is_zero


## Whether or not this effect supports [member _apply_limit] & [member apply_limit_amount]
func can_have_apply_limit() -> bool:
	return duration_type != DurationType.INSTANT && type == Type.PERMANENT


## Whether or not this effect has an [member apply_limit_amount] (that maximum number
## of times it can apply before being instantly removed)
## Returns true if [method can_have_apply_limit] and [member _apply_limit] are both true.
func has_apply_limit() -> bool:
	return can_have_apply_limit() && _apply_limit


## Returns true if this effect has a [member duration_in_seconds].
func has_duration() -> bool:
	return duration_type == DurationType.HAS_DURATION


## Returns true if this effect has a [member period_in_seconds].
func has_period() -> bool:
	return type == Type.PERMANENT && !is_instant()


## Returns true if this effect supports [member _log_history].
func can_log_history() -> bool:
	return type == Type.PERMANENT


## Returns true if this effect's applications should be logged in an [AttributeHistory].
func should_log_history() -> bool:
	return can_log_history() && _log_history


## If this effect is stackable.
func is_stackable() -> bool:
	return stack_mode == AttributeEffect.StackMode.COMBINE

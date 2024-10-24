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
		if AttributeEffectFeatureManager.validate_user_set_value(self, &"type", _value):
			type = _value
			AttributeEffectFeatureManager.notify_value_changed(self, &"type")

## If true, this effect must have a [member value] which applies to an [Attribute].
@export var has_value: bool:
	set(_value):
		has_value = _value
		if has_value && value == null:
			value = AttributeEffectValue.new()
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
@export var emit_added_signal: bool = false:
	set(value):
		assert(can_emit_added_signal() || !emit_added_signal,
		"This type of effect can not emit the added signal")
		emit_added_signal = value
	get():
		return emit_added_signal if can_emit_added_signal() else false

## If true, [signal Attribute.effect_applied] will be emitted every time an
## [ActiveAttributeEffect] of this effect is successfully applied on an [Attribute].
## [br]NOTE: ONLY AVAILABLE FOR [enum Type.PERMANENT] as TEMPORARY effects are not reliably applied.
@export var emit_applied_signal: bool = false:
	set(value):
		assert(can_emit_applied_signal() || !emit_applied_signal,
		"This type of effect can not emit the applied signal")
		emit_applied_signal = value
	get():
		return emit_applied_signal if can_emit_applied_signal() else false

## If true, [signal Attribute.effect_removed] will be emitted every time an
## [ActiveAttributeEffect] of this effect is removed from an [Attribute].
@export var emit_removed_signal: bool = false:
	set(value):
		assert(can_emit_removed_signal() || !emit_removed_signal,
		"This type of effect can not emit the removed signal")
		emit_removed_signal = value
	get():
		return emit_removed_signal if can_emit_removed_signal() else false

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
		if has_duration() && duration == null:
			duration = AttributeEffectValue.new()
		if has_period() && period == null:
			period = AttributeEffectValue.new()
		notify_property_list_changed()

## The amount of time in seconds this [AttributeEffect] lasts.
@export var duration: AttributeEffectValue

## If the effect should automatically be applied when it's duration expires.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var apply_on_expire: bool = false:
	set(_value):
		assert(!_value || can_apply_on_expire(), "apply_on_expire can not be true when " +\
		"duration_type != HAS_DURATION or when type != PERKMANENT")
		apply_on_expire = _value
		notify_property_list_changed()
	get():
		return apply_on_expire if can_apply_on_expire() else false

@export_group("Apply Limit")
## TODO RESUME HERE WITH FEATURES

## If true, [member apply_limit_amount] is the maximum amount of times an effect
## can apply. If the limit is hit, the effect is removed immediately.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var apply_limit: bool = false:
	set(_value):
		assert(!apply_limit || can_have_apply_limit(), "apply_limit can not be true when " +\
		"duration_type == INSTANT or when type != PERMANENT")
		apply_limit = _value
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
@export var period: AttributeEffectValue

## If [member period] should apply as a "delay" between when this effect 
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
@export var apply_on_expire_if_period_is_zero: bool = false

@export_group("Stacking")

## The [StackMode] to use when duplicate [AttributeEffect]s are found.
@export var stack_mode: StackMode:
	set(_value):
		if duration_type == DurationType.INSTANT && _value == StackMode.COMBINE:
			stack_mode = StackMode.DENY
			return
		stack_mode = _value
		notify_property_list_changed()

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
@export var add_blocker: bool = false:
	set(value):
		add_blocker = value
		notify_property_list_changed()

## Blocks other [AttributeEffect]s from being added to an [Attribute] if they
## do NOT meet any of these conditions. Only used if [member add_blocker] is true.
@export var add_blockers: Array[AttributeEffectCondition]

## If true, this effect can utilize [member apply_blockers] which
## are sets of [AttributeEffectCondition]s that can block other [AttributeEffect]s
## from applying to any [Attribute] this effect is currently added to.
## Only applicable for non-instant effects, and only applicable for non-instant effects.
@export var apply_blocker: bool = false:
	set(value):
		apply_blocker = value
		notify_property_list_changed()

## Blocks other [AttributeEffect]s from being applied to an [Attribute] if they
## do NOT meet any of these conditions. Only used if [member apply_blocker] is true,
## and only applicable for non-instant effects.
@export var apply_blockers: Array[AttributeEffectCondition]

@export_group("Modifiers")

## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the value of other [AttributeEffect]s. Only applicable for non-instant effects.
@export var value_modifier: bool = false:
	set(value):
		value_modifier = value
		notify_property_list_changed()

## Modifies the [member value] of other [AttributeEffect]s.
## Only used if [member value_modifier] is true, and only applicable for
## non-instant effects.
@export var value_modifiers: AttributeEffectModifierArray

## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the period of other [AttributeEffect]s. Only applicable for non-instant effects.
@export var period_modifier: bool = false:
	set(value):
		period_modifier = value
		notify_property_list_changed()

## Modifies the [member period] of other [AttributeEffect]s.
## Only used if [member period_modifier] is true, and only applicable for
## non-instant effects.
@export var period_modifiers: AttributeEffectModifierArray

## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the duration of other [AttributeEffect]s. Only applicable for non-instant effects.
@export var duration_modifier: bool = false:
	set(value):
		duration_modifier = value
		notify_property_list_changed()

## Modifies the [member duration] of other [AttributeEffect]s.
## Only used if [member duration_modifier] is true, and only applicable for
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
	AttributeEffectFeatureManager.validate_property(self, property)


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


## Populates all of the [DerivedModifier]s present on this effect with
## [param attribute], see [method DerivedModifier.populate] for more information.
## Must be done at runtime before creating an [ActiveAttributeEffect] of this resource
## each time this resource is loaded or when a new instance.
func populate_derived_modifiers(attribute: Attribute, context: String = "") -> void:
	if value != null:
		value.populate_derived(attribute, context)
	if duration != null:
		duration.populate_derived(attribute, context)
	if period != null:
		period.populate_derived(attribute, context)
	if value_modifiers != null:
		value_modifiers.populate_derived(attribute, context)
	if period_modifiers != null:
		period_modifiers.populate_derived(attribute, context)
	if duration_modifiers != null:
		duration_modifiers.populate_derived(attribute, context)


## Shorthand function to create an [ActiveAttributeEffect] for this [AttributeEffect].
func create_active_effect() -> ActiveAttributeEffect:
	# TODO more verbose method of checking if derived are populated
	# TODO cleanup
	assert(value == null || value.is_all_derived_populated(), "a DerivedModifier in value" + \
	"is not populated")
	assert(duration == null || duration.is_all_derived_populated(), "a DerivedModifier in duration" + \
	"is not populated")
	assert(period == null || period.is_all_derived_populated(), "a DerivedModifier in period" + \
	"is not populated")
	assert(value_modifiers == null || value_modifiers.is_all_derived_populated(), "a DerivedModifier in value_modifiers" + \
	"is not populated")
	assert(period_modifiers == null || period_modifiers.is_all_derived_populated(), "a DerivedModifier in period_modifiers" + \
	"is not populated")
	assert(duration_modifiers == null || duration_modifiers.is_all_derived_populated(), "a DerivedModifier in duration_modifiers" + \
	"is not populated")
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
	return duration_type == DurationType.INSTANT


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
	return add_blocker || apply_blocker


## Returns true if this effect can be a modifier of value, duration, or period.
func can_be_modifier() -> bool:
	return !is_instant()


## Returns true if this effect is a value, duration, or period modifier.
func is_any_modifier() -> bool:
	return value_modifier || duration_modifier || period_modifier


## Whether or not this effect can emit [signal Attribute.effect_added].
func can_emit_added_signal() -> bool:
	return duration_type != DurationType.INSTANT


## Whether or not this effect can emit [signal Attribute.effect_applied].
func can_emit_applied_signal() -> bool:
	return type == Type.PERMANENT


## Whether or not this effect can emit [signal Attribute.effect_removed].
func can_emit_removed_signal() -> bool:
	return duration_type != DurationType.INSTANT


## Whether or not this effect supports [member apply_on_expire]
func can_apply_on_expire() -> bool:
	return duration_type == DurationType.HAS_DURATION && type == Type.PERMANENT


## Whether or not this effect supports [member apply_on_expire_if_period_is_zero]
func can_apply_on_expire_if_period_is_zero() -> bool:
	return !apply_on_expire && has_period()


## Whether or not this effect supports [member apply_limit] & [member apply_limit_amount]
func can_have_apply_limit() -> bool:
	return duration_type != DurationType.INSTANT && type == Type.PERMANENT


## Returns true if this effect has a [member duration].
func has_duration() -> bool:
	return duration_type == DurationType.HAS_DURATION


## Returns true if this effect has a [member period].
func has_period() -> bool:
	return type == Type.PERMANENT && !is_instant()


## If this effect is stackable.
func is_stackable() -> bool:
	return stack_mode == AttributeEffect.StackMode.COMBINE

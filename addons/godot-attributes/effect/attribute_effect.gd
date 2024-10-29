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

var _ignore_loading: bool = false
@export_storage var _loading_start: bool:
	set(_value):
		_loading_start = _value
		print("SET _loading_start=", _value)
		if !_ignore_loading:
			_loading = true

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
@export var type: Type = \
AttributeEffectFeatureManager.i().get_default_value(self, &"type"):
	set(_value):
		print("SET: Type")
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"type", _value):
			type = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"type")

## If true, this effect must have a [member value] which applies to an [Attribute].
@export var has_value: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"has_value"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"has_value", _value):
			has_value = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"has_value")

## The value that is applied to an [Attribute]'s value (base or current, based on
## [member type]).
@export var value: AttributeEffectValue = \
AttributeEffectFeatureManager.i().get_default_value(self, &"value"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"value", _value):
			value = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"value")

## Determines how the [member value] is applied to an [Attribute] (i.e. added, multiplied, etc).
@export var value_calculator: AttributeEffectCalculator = \
AttributeEffectFeatureManager.i().get_default_value(self, &"value_calculator"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"value_calculator", _value):
			value_calculator = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"value_calculator")

@export_group("Signals")

## If true, [signal Attribute.effect_added] will be emitted every time an
## [ActiveAttributeEffect] of this effect is added to an [Attribute].
@export var emit_added_signal: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"emit_added_signal"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"emit_added_signal", _value):
			emit_added_signal = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"emit_added_signal")

## If true, [signal Attribute.effect_applied] will be emitted every time an
## [ActiveAttributeEffect] of this effect is successfully applied on an [Attribute].
## [br]NOTE: ONLY AVAILABLE FOR [enum Type.PERMANENT] as TEMPORARY effects are not reliably applied.
@export var emit_applied_signal: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"emit_applied_signal"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"emit_applied_signal", _value):
			emit_applied_signal = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"emit_applied_signal")

## If true, [signal Attribute.effect_removed] will be emitted every time an
## [ActiveAttributeEffect] of this effect is removed from an [Attribute].
@export var emit_removed_signal: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"emit_removed_signal"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"emit_removed_signal", _value):
			emit_removed_signal = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"emit_removed_signal")

@export_group("Duration")

## How long the effect lasts.
@export var duration_type: DurationType = \
AttributeEffectFeatureManager.i().get_default_value(self, &"duration_type"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"duration_type", _value):
			duration_type = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"duration_type")

## The amount of time in seconds this [AttributeEffect] lasts.
@export var duration: AttributeEffectValue = \
AttributeEffectFeatureManager.i().get_default_value(self, &"duration"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"duration", _value):
			duration = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"duration")

## If the effect should automatically be applied when it's duration expires.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var apply_on_expire: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"apply_on_expire"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"apply_on_expire", _value):
			apply_on_expire = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"apply_on_expire")

@export_group("Apply Limit")

## can apply. If the limit is hit, the effect is removed immediately.
## If true, [member apply_limit_amount] is the maximum amount of times an effect
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var apply_limit: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"apply_limit"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"apply_limit", _value):
			apply_limit = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"apply_limit")

## The maximum amount of times this effect can be applied to an [Attribute], inclusive. If this
## number is reached, the effect is then instantly removed from the [Attribute].
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export_range(1, 100, 1, "or_greater", "hide_slider") var apply_limit_amount: int = \
AttributeEffectFeatureManager.i().get_default_value(self, &"apply_limit_amount"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"apply_limit_amount", _value):
			apply_limit_amount = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"apply_limit_amount")

## If true, whenever this effect's apply is blocked by an [AttributeEffectCondition],
## the internal apply count used in the apply limit system will still increment.
@export var count_apply_if_blocked: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"count_apply_if_blocked"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"count_apply_if_blocked", _value):
			count_apply_if_blocked = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"count_apply_if_blocked")

@export_group("Period")

## Amount of time, in seconds, between when this effect is applied to an [Attribute].
## [br]Zero or less means every frame.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var period: AttributeEffectValue = \
AttributeEffectFeatureManager.i().get_default_value(self, &"period"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"period", _value):
			period = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"period")

## If [member period] should apply as a "delay" between when this effect 
## is added to an [Attribute] and its first time applying.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var initial_period: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"initial_period"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"initial_period", _value):
			initial_period = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"initial_period")

## For special edge cases, if true the effect will be applied on it's expiration if
## the remaining period has reached 0.0 at the same frame. If [member _apply_on_expire]
## is true, this property is meaningless.
## [br]For example, if an effect has a duration of 5 seconds, and a period of 1, it
## will be applied when it expires as the remaining period for the next application
## will reach zero on the same frame.
## [br]NOTE: Only available for [enum Type.PERMANENT] effects.
@export var apply_on_expire_if_period_is_zero: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"apply_on_expire_if_period_is_zero"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, 
		&"apply_on_expire_if_period_is_zero", _value):
			apply_on_expire_if_period_is_zero = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"apply_on_expire_if_period_is_zero")

@export_group("Stacking")

## The [StackMode] to use when duplicate [AttributeEffect]s are found.
@export var stack_mode: StackMode = \
AttributeEffectFeatureManager.i().get_default_value(self, &"stack_mode"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"stack_mode", _value):
			stack_mode = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"stack_mode")

@export_group("Conditions")

## Whether or not this effect supports [member add_condition]s. Added for internal efficiency.
@export var has_add_conditions: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"has_add_conditions"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"has_add_conditions", _value):
			has_add_conditions = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"has_add_conditions")


## All [AttributeEffectCondition]s that must be met for this effect to be
## added to an [Attribute]. This array can safely be directly modified or set.
##[br]NOTE: Not supported for INSTANT effects, as they are just applied & not added.
@export var add_conditions: Array[AttributeEffectCondition] = \
AttributeEffectFeatureManager.i().get_default_value(self, &"add_conditions"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"add_conditions", _value):
			add_conditions = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"add_conditions")

## Whether or not this effect supports [member apply_condition]s. Added for internal efficiency.
@export var has_apply_conditions: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"has_apply_conditions"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"has_apply_conditions", _value):
			has_apply_conditions = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"has_apply_conditions")


## All [AttributeEffectCondition]s that must be met for this effect to be
## applied to an [Attribute]. This array can safely be directly modified or set.[br]
## [br]NOTE: When using with TEMPORARY effects, [method Attribute.update_current_value]
## will need to be called manually if a condition changes. That fucntion is only automatically
## called when an effect is added/removed or a PERMANENT effect is applied.
@export var apply_conditions: Array[AttributeEffectCondition] = \
AttributeEffectFeatureManager.i().get_default_value(self, &"apply_conditions"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"apply_conditions", _value):
			apply_conditions = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"apply_conditions")

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
@export var add_blocker: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"add_blocker"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"add_blocker", _value):
			add_blocker = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"add_blocker")

## Blocks other [AttributeEffect]s from being added to an [Attribute] if they
## do NOT meet any of these conditions. Only used if [member add_blocker] is true.
@export var add_blockers: Array[AttributeEffectCondition] = \
AttributeEffectFeatureManager.i().get_default_value(self, &"add_blockers"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"add_blockers", _value):
			add_blockers = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"add_blockers")

## If true, this effect can utilize [member apply_blockers] which
## are sets of [AttributeEffectCondition]s that can block other [AttributeEffect]s
## from applying to any [Attribute] this effect is currently added to.
## Only applicable for non-instant effects, and only applicable for non-instant effects.
@export var apply_blocker: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"apply_blocker"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"apply_blocker", _value):
			apply_blocker = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"apply_blocker")

## Blocks other [AttributeEffect]s from being applied to an [Attribute] if they
## do NOT meet any of these conditions. Only used if [member apply_blocker] is true,
## and only applicable for non-instant effects.
@export var apply_blockers: Array[AttributeEffectCondition] = \
AttributeEffectFeatureManager.i().get_default_value(self, &"apply_blockers"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"apply_blockers", _value):
			apply_blockers = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"apply_blockers")

@export_group("Modifiers")

## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the value of other [AttributeEffect]s. Only applicable for non-instant effects.
@export var value_modifier: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"value_modifier"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"value_modifier", _value):
			value_modifier = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"value_modifier")

## Modifies the [member value] of other [AttributeEffect]s.
## Only used if [member value_modifier] is true, and only applicable for
## non-instant effects.
@export var value_modifiers: AttributeEffectModifierArray = \
AttributeEffectFeatureManager.i().get_default_value(self, &"value_modifiers"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"value_modifiers", _value):
			value_modifiers = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"value_modifiers")

## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the period of other [AttributeEffect]s. Only applicable for non-instant effects.
@export var period_modifier: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"period_modifier"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"period_modifier", _value):
			period_modifier = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"period_modifier")

## Modifies the [member period] of other [AttributeEffect]s.
## Only used if [member period_modifier] is true, and only applicable for
## non-instant effects.
@export var period_modifiers: AttributeEffectModifierArray = \
AttributeEffectFeatureManager.i().get_default_value(self, &"period_modifiers"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"period_modifiers", _value):
			period_modifiers = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"period_modifiers")

## If true, this effect has [member value_modifiers] which once applied to an [Attribute] will
## modify the duration of other [AttributeEffect]s. Only applicable for non-instant effects.
@export var duration_modifier: bool = \
AttributeEffectFeatureManager.i().get_default_value(self, &"duration_modifier"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"duration_modifier", _value):
			duration_modifier = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"duration_modifier")

## Modifies the [member duration] of other [AttributeEffect]s.
## Only used if [member duration_modifier] is true, and only applicable for
## non-instant effects.
@export var duration_modifiers: AttributeEffectModifierArray \
= AttributeEffectFeatureManager.i().get_default_value(self, &"duration_modifiers"):
	set(_value):
		if AttributeEffectFeatureManager.i().validate_user_set_value(self, &"duration_modifiers", _value):
			duration_modifiers = _value
			AttributeEffectFeatureManager.i().notify_value_changed(self, &"duration_modifiers")

@export_group("Metadata")

## A simple [Dictionary] that can be used to store metadata for effects. Not
## used in any of the Attribute system's internals.
@export var metadata: Dictionary[Variant, Variant]

@export_storage var _loading_end: bool:
	set(_value):
		_loading_end = _value
		print("SET _loading_end=", _value)
		if !_ignore_loading:
			_loading = false

var _loaded: bool = false
var _loading: bool = false:
	set(_value):
		if _loaded: # Skip if already loaded
			return
		_loading = _value
		if _loading:
			print("LOADING")
		else:
			print("STOPPED LOADING")

var _hooks_by_function: Dictionary[AttributeEffectHook._Function, Array]
var _block_runtime_modifications: bool = false:
	set(value):
		_block_runtime_modifications = true

func _init(_id: StringName = "") -> void:
	print("_init")
	changed
	id = _id
	if Engine.is_editor_hint():
		return
	# Hook initialization
	for _function: int in AttributeEffectHook._Function.values():
		_hooks_by_function[_function] = []


# Internal used to detect when this script is being loaded. DO NOT CALL MANUALLY.
func _toggle_load() -> bool:
	_loading = !_loading
	return false


func _validate_property(property: Dictionary) -> void:
	AttributeEffectFeatureManager.i().validate_property(self, property)


func _property_can_revert(property: StringName) -> bool:
	return AttributeEffectFeatureManager.i().is_feature(property)


func _property_get_revert(property: StringName) -> Variant:
	return AttributeEffectFeatureManager.i().get_default_value(self, property)


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

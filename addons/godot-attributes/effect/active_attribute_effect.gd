## Represents an individual instance of an [AttributeEffect] that is or 
## can be actively applied to an [Attribute].
class_name ActiveAttributeEffect extends Resource

## The remaining duration in seconds, can not be set to less than 0.0.
var _remaining_duration: float:
	set(_value):
		var previous: float = _remaining_duration
		_remaining_duration = max(0.0, _value)

## Customizable metadata for this [ActiveAttributeEffect], for use with conditions,
## hooks, etc. Not in use by the Attribute system itself, but used with some of
## the built in conditions, hooks, & modifiers.
var meta: Dictionary[Variant, Variant] = {}

## The remaining amount of time, in seconds, until this effect is next triggered.
## Can be manually set before applying to an [Attribute] to create an initial
## delay.
var _remaining_period: float = 0.0

var _effect: AttributeEffect
## The [NodePath] to the source [Node] of this [AttributeEffect].
var _initialized: bool = false
var _expired: bool = false
var _is_added: bool = false
var _stack_count: int = 1
var _apply_count: int = 0
var _is_applying: bool = false

var _last_blocked_by: AttributeEffectCondition
var _last_blocked_by_source: WeakRef = weakref(null)

var _last_add_result: Attribute.AddEffectResult = Attribute.AddEffectResult.NEVER_ADDED

var _tick_added_on: int = -1
var _tick_last_processed: int = -1
var _tick_last_applied: int = -1

var _active_duration: float = 0.0

# The total value of the effect that is pending application to an attribute
var _pending_effect_value: float
# The current value of the attribute, before the effect value is applied. Base value
# for PERMANENT actives, current value for TEMPORARY.
var _pending_prior_attribute_value: float
# The raw (unvalidated) value of the attribute AFTER the effect value is to be applied. Base value
# for PERMANENT actives, current value for TEMPORARY.
var _pending_raw_attribute_value: float
# The validated value of the attribute AFTER the effect value is to be applied. Base value
# for PERMANENT actives, current value for TEMPORARY.
var _pending_final_attribute_value: float
# TODO: get_pending_differential() method - difference between final & prior

# The total value this effect had when last applied to the attribute
var _last_effect_value: float
# The attribute value BEFORE this effect was last applied to it. Base value
# for PERMANENT actives, current value for TEMPORARY.
var _last_prior_attribute_value: float
# The raw (unvalidated) value of the attribute after this effect was last applied to it. Base value
# for PERMANENT actives, current value for TEMPORARY.
var _last_raw_attribute_value: float
# The validated value of the attribute after this effect was last applied to it. Base value
# for PERMANENT actives, current value for TEMPORARY.
var _last_final_attribute_value: float
# TODO: get_last_differential() method - difference between final & prior


func _init(effect: AttributeEffect) -> void:
	assert(effect != null, "effect is null")
	_effect = effect


## Returns the [AttributeEffect] instance this effect was created for.
func get_effect() -> AttributeEffect:
	return _effect


# TODO document
func get_remaining_period() -> float:
	return _remaining_period


# TODO document
func get_remaining_duration() -> float:
	return _remaining_duration


## Whether or not this instance has been initialized by an [Attribute].
## [br]Initialization means that the default duration & initial period have been set
## so this effect can be processed & applied.
func is_initialized() -> bool:
	return _initialized


## Returns true if this active effect is currently added to an [Attribute], false if not.
func is_added() -> bool:
	return _is_added


## Returns the tick this active effect was added to an [Attribute] on.
func get_tick_added_on() -> int:
	return _tick_added_on


## Returns the last tick (see [method Attribute._get_ticks]) this active effect was processed on. This
## tick may be unreliable to determine when it was last processed if scene tree pausing has
## been activated, as this is adjusted accordingly.
func get_tick_last_processed() -> int:
	return _tick_last_processed


## Returns the last [method Time.get_ticks_msec] this active effect was applied on. -1 if it has not
## yet been applied. Always returns -1 for TEMPORARY effects.
func get_tick_last_applied() -> int:
	return _tick_last_applied


## Returns the amount of time, in seconds, since this active effect last applied to the [Attribute].
## If [method has_applied] returns false, 0.0 is returned.
func get_seconds_since_last_apply() -> float:
	if !has_applied():
		return 0.0
	return Attribute._ticks_to_seconds(Attribute._get_ticks() - _tick_last_applied)


## Returns true if the effect has been applied. Always returns false for
## TEMPORARY effects.
func has_applied() -> bool:
	return _tick_last_applied > -1


## Returns the total amount of duration, in seconds, this active effect has been active for.
## [b]NOTE: Includes any time the [Attribute] spent in a paused state.[/b] Use
## [method get_active_duration] to omit the time spent paused.
func get_total_duration() -> float:
	return Attribute._ticks_to_seconds(Attribute._get_ticks() - _tick_added_on)


## Returns total amount of duration, in seconds, this active effect has been active for. Does not
## include time that was passed when an [Attribute] was paused.
func get_active_duration() -> float:
	return _active_duration


## Returns the sum of [member remaining_duration] and [method get_active_duration],
## which represents the total amount of time, in seconds, this effect is expected to live for.
func get_active_expected_duration() -> float:
	return _remaining_duration + _active_duration


## Returns the pending total value of the effect.
func get_pending_effect_value() -> float:
	return _pending_effect_value


## Returns the [Attribute]s value at the current point in time before applying this effect.
func get_pending_prior_attribute_value() -> float:
	return _pending_prior_attribute_value


## Returns what will be the raw, unvalidated value of the [Attribute] AFTER this effect
## is to be applied.
func get_pending_raw_attribute_value() -> float:
	return _pending_raw_attribute_value


## Returns what will be the final, validated value of the [Attribute] AFTER thiss effect
## is to be applied.
func get_pending_final_attribute_value() -> float:
	return _pending_final_attribute_value


## Returns [method get_pending_raw_attribute_value] - [method get_pending_prior_attribute_value]
## which returns the [b]raw[/b] total difference this effect will have on the [Attribute] before
## applying to it, not accounting for validation of the new attribute value.
func get_pending_raw_difference() -> float:
	return _pending_raw_attribute_value - _pending_prior_attribute_value


## Returns [method get_pending_final_attribute_value] - [method get_pending_prior_attribute_value]
## which returns the total difference this effect will have on the [Attribute] before
## applying to it.
func get_pending_difference() -> float:
	return _pending_final_attribute_value - _pending_prior_attribute_value


## Returns the total value of this effect after it was last applied to the [Attribute].
func get_last_effect_value() -> float:
	return _last_effect_value


## Returns the [Attribute]'s prior value before this effect was last applied to it.
func get_last_prior_attribute_value() -> float:
	return _last_prior_attribute_value


## Returns the raw, unvalidated value of the [Attribute] before this effect was last applied to it.
func get_last_raw_attribute_value() -> float:
	return _last_raw_attribute_value


## Returns the final, validated value of the [Attribute] after this effect was last applied to it.
func get_last_final_attribute_value() -> float:
	return _last_final_attribute_value


## Returns [method get_last_raw_attribute_value] - [method get_last_prior_attribute_value]
## which returns the [b]raw[/b] total difference this effect had on the [Attribute]'s value when it
## was last applied to it, not accounting for validation of the set attribute value.
func get_last_raw_difference() -> float:
	return _pending_raw_attribute_value - _pending_prior_attribute_value


## Returns [method get_last_final_attribute_value] - [method get_last_prior_attribute_value]
## which returns the total difference this effect had on the [Attribute]'s value when it
## was last applied to it.
func get_last_difference() -> float:
	return _last_final_attribute_value - _last_prior_attribute_value


## If currently blocked, returns the [AttributeEffectCondition] that blocked this active effect
## when being added to an effect or in applying. Returns null if not currently blocked.
func get_last_blocked_by() -> AttributeEffectCondition:
	return _last_blocked_by


## If currently blocked, returns the [ActiveAttributeEffect] which owns the
## [method get_last_blocked_by] condition. May be this instance, or may be another
## [ActiveAttributeEffect] which is a "blocker".[br]
## NOTE: This could also return null even if [member _last_blocked_by] is not null 
## as internally it uses a weakref to prevent circular dependencies causing memory
## leaks (if 2 effects block each other).
func get_last_blocked_by_source() -> ActiveAttributeEffect:
	return _last_blocked_by_source.get_ref()


## Returns the [enum Attribute.AddEffectResult] from the last attempt to add this
## active effect to an [Attribute].
func get_last_add_result() -> Attribute.AddEffectResult:
	return _last_add_result


## Amount of times this [ActiveAttributeEffect] was applied to an [Attribute]. Does not
## track for TEMPORARY effects, thus the value is always 0 in that case.
func get_apply_count() -> int:
	return _apply_count


## Returns true if this effect is currently applying and thus not blocked by a condition.
func is_applying() -> bool:
	return _is_applying


## Returns true if [method get_effect] has an apply limit & this active effect's [method get_apply_count]
## has either met or exceeded the [member AttributeEffect.apply_limit_amount].
func hit_apply_limit() -> bool:
	return _effect.apply_limit && _apply_count >= _effect.apply_limit_amount


## Returns true if the effect expired due to duration, false if not. Can be useful
## to see if this active effect was manually removed from an [Attribute] or if it expired.
func is_expired() -> bool:
	return !_effect.is_instant() && _effect.has_duration() && _expired


## Returns the stack count (how many [AttributeEffect]s have been stacked).
## Can't be less than 1.
func get_stack_count() -> int:
	return _stack_count


func _clear_pending_values() -> void:
	_pending_prior_attribute_value = 0.0
	_pending_effect_value = 0.0
	_pending_raw_attribute_value = 0.0
	_pending_final_attribute_value = 0.0


func _to_string() -> String:
	return "ActiveAttributeEffect(_effect.id:%s)" % _effect.id

## Represents an individual instance of an [AttributeEffect] that is applied
## to an [Attribute].
class_name AttributeEffectSpec extends Resource

## The remaining duration in seconds, can not be set to less than 0.0.
var remaining_duration: float:
	set(_value):
		var previous: float = remaining_duration
		remaining_duration = max(0.0, _value)

## Customizable metadata for this [AttributeEffectSpec], for use with conditions,
## callbacks, etc. Not in use by the Attribute system itself, but used with some of
## the built in conditions, callbacks, & modifiers.
var meta: Dictionary[Variant, Variant] = {}

## The remaining amount of time, in seconds, until this effect is next triggered.
## Can be manually set before applying to an [Attribute] to create an initial
## delay.
var remaining_period: float = 0.0

## The pending value that will be set directly to the [Attribute] by this spec.
## Based on 
var pending_attribute_value: float

var _effect: AttributeEffect
## The [NodePath] to the source [Node] of this [AttributeEffect].
var _initialized: bool = false
var _expired: bool = false
var _is_added: bool = false
var _stack_count: int = 1
var _apply_count: int = 0
var _is_applying: bool = false

var _last_blocked_by: AttributeEffectCondition
var _last_add_result: Attribute.AddEffectResult = Attribute.AddEffectResult.NEVER_ADDED

var _tick_added_on: int = -1
var _tick_last_processed: int = -1
var _tick_last_applied: int = -1

var _active_duration: float = 0.0

# Effect's modified value
var _pending_effect_value: float
# Current attribute value
var _pending_current_attribute_value: float
# Raw UNVALIDATED attr value
var _pending_raw_attribute_value: float
# VALIDATED new attr value
var _pending_set_attribute_value: float

# Last effect's modified value
var _last_effect_value: float
var _last_prior_attribute_value: float
var _last_raw_attribute_value: float
var _last_set_attribute_value: float
# TODO: get_last_differential() method

func _init(effect: AttributeEffect) -> void:
	assert(effect != null, "effect is null")
	_effect = effect


## Returns the [AttributeEffect] instance this spec was created for.
func get_effect() -> AttributeEffect:
	return _effect


## Whether or not this instance has been initialized by an [Attribute].
## [br]Initialization means that the default duration & initial period have been set
## so this effect can be processed & applied.
func is_initialized() -> bool:
	return _initialized


## De-initializes the spec (only if already initialized), setting [member remaining_period] 
## and [member remaining_duration] to 0.0.
func deinitialize() -> void:
	if is_initialized():
		remaining_period = 0.0
		remaining_duration = 0.0
		_initialized = false


## Returns true if this spec is currently added to an [Attribute].
func is_added() -> bool:
	return _is_added


## Returns the tick this spec was added to an [Attribute] on.
func get_tick_added_on() -> int:
	return _tick_added_on


## Returns the last tick (see [method Attribute._get_ticks]) this spec was processed on. This
## tick may be unreliable to determine when it was last processed if scene tree pausing has
## been activated, as this is adjusted accordingly.
func get_tick_last_processed() -> int:
	return _tick_last_processed


## Returns the last [method Time.get_ticks_msec] this spec was applied on. -1 if it has not
## yet been applied. Always returns -1 for TEMPORARY effects.
func get_tick_last_applied() -> int:
	return _tick_last_applied


## Returns the amount of time, in seconds, since this spec last applied to the [Attribute].
## If [method has_applied] returns false, 0.0 is returned.
func get_seconds_since_last_apply() -> float:
	if !has_applied():
		return 0.0
	return Attribute._ticks_to_seconds(Attribute._get_ticks() - _tick_last_applied)


## Returns true if the effect has been applied. Always returns false for
## TEMPORARY effects.
func has_applied() -> bool:
	return _tick_last_applied > -1


## Returns the total amount of duration, in seconds, this spec has been active for.
## [b]NOTE: Includes any time the [Attribute] spent in a paused state.[/b] Use
## [method get_active_duration] to omit the time spent paused.
func get_total_duration() -> float:
	return Attribute._ticks_to_seconds(Attribute._get_ticks() - _tick_added_on)


## Returns total amount of duration, in seconds, this spec has been active for. Does not
## include time that was passed when an [Attribute] was paused.
func get_active_duration() -> float:
	return _active_duration


## Returns the sum of [member remaining_duration] and [method get_active_duration],
## which represents the total amount of time, in seconds, this effect is expected to live for.
func get_active_expected_duration() -> float:
	return remaining_duration + _active_duration


### Returns the value retrieved from [member AttributeEffect.value] that is pending
### application to the [Attribute]. If this spec is not in a pending state, 0.0 is returned.
#func get_pending_effect_value() -> float:
	#return _pending_effect_value
#
#
### Returns the value derived from appling the effect's [AttributeEffectCalculator] on the
### [method get_pending_effect_value] & Attribute's value. This is the value that will be set
### directly to the [Attribute]. If this spec is not in a pending state, 0.0 is returned.
#func get_pending_calculated_value() -> float:
	#return _pending_calculated_value
#
#
### Returns
#func get_last_effect_value() -> float:
	#return _last_effect_value


## If currently blocked, returns the [AttributeEffectCondition] that blocked this spec
## when being added to an effect or in applying. Returns null if not currently blocked.
func get_last_blocked_by() -> AttributeEffectCondition:
	return _last_blocked_by


## Returns the [enum Attribute.AddEffectResult] from the last attempt to add this
## spec to an [Attribute].
func get_last_add_result() -> Attribute.AddEffectResult:
	return _last_add_result


## Amount of times this [AttributeEffectSpec] was applied to an [Attribute]. Does not
## track for TEMPORARY effects, thus the value is always 0 in that case.
func get_apply_count() -> int:
	return _apply_count


## Returns true if this effect is currently applying and thus not blocked by a condition, expired,
## or hit its apply limit. False if not.
func is_applying() -> bool:
	return _is_applying


## Returns true if [method get_effect] has an apply limit & this spec's [method get_apply_count]
## has either met or exceeded the [member AttributeEffect.apply_limit_amount].
func hit_apply_limit() -> bool:
	return _effect.has_apply_limit() && _apply_count >= _effect.apply_limit_amount


## Returns true if the effect expired due to duration, false if not. Can be useful
## to see if this spec was manually removed from an [Attribute] or if it expired.
func is_expired() -> bool:
	return !_effect.is_instant() && _effect.has_duration() && _expired


## Returns the stack count (how many [AttributeEffect]s have been stacked).
## Can't be less than 1.
func get_stack_count() -> int:
	return _stack_count


func _clear_pending_values() -> void:
	_pending_current_attribute_value = 0.0
	_pending_effect_value = 0.0
	_pending_raw_attribute_value = 0.0
	_pending_set_attribute_value = 0.0


func _to_string() -> String:
	return "AttributeEffectSpec(_effect.id:%s)" % _effect.id
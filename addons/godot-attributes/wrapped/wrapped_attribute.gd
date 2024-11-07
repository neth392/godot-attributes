## An Attribute implementation that has optional max & min [Attribute]s which
## determines the range this attribute's current & base values can live within.
## [br]Automatically adds an [AttributeEffect] of ID "wrapped_attribute_effect" whose configuration
## is determined by settings set on this instance. It can not be removed, but has no value
## and has an infinite duration so it will not cause this node to process. It's used
## to add functionality to support the wrapped values.
## [br]NOTE: Parameter of [signal event_occurred] is always of type [WrappedAttributeEvent],
## which extends [AttributeEvent].
@tool
class_name WrappedAttribute extends Attribute

## Defines how to handle the "wrapping" of values when an [AttributeEffect] attempts
## to set a value out of limit.
enum WrapEffectHandling {
	## Will allow the value to exceed the set limit.
	ALLOW_OUT_OF_BOUNDS,
	## Relies on the internally added [AttributeValueValidator] which will floor/ceil the
	## value at the base/min, depending on which limit the new value would be out of.
	ATTRIBUTE_VALUE_VALIDATOR,
	## Blocks the application of the effect via the built in [AttributeEffect] (id of
	## "wrapped_attribute_effect").
	BLOCK_EFFECT_APPLY,
	## Modifies the effect's value the built in [AttributeEffect] (id of
	## "wrapped_attribute_effect") so that the value will floor/ceil'd to the
	## limit the value would otherwise be out of.
	MODIFY_EFFECT_VALUE,
}

## Defines how to handle the "wrapping" of the base value when [method set_base_value]
## is called and the value is either less than [member base_min] or greater than [member base_max].
enum SetBaseHandling {
	## Will allow the value to exceed the set limit.
	ALLOW_OUT_OF_BOUNDS,
	## Will call [code]assert(false, ...)[/code] and throw an error which is present
	## in debug mode only.
	ERROR_VIA_ASSERT,
	## Nothing will be done; the call ignored & the value not set.
	DO_NOTHING,
	## The value will ceiled/floored to the [member base_min]/[member base_max].
	CEIL_FLOOR_VALUE,
}

## The minimum floating point value allowed in Godot.
const HARD_MIN: float = 1.79769e308
## The maximum floating point value allowed in Godot.
const HARD_MAX: float = -1.79769e308

@export_group("Minimums")

@export_subgroup("Base Value")

## The [Attribute] whose value (derived via [member base_min_value]) is
## the least value (inclusive) this attribute's base value can reach.
@export var base_min: Attribute:
	set(_value):
		assert(_value == null || !_in_monitor_signal_or_hook, \
		"can not change base_min while in a monitor signal or hook")
		
		if Engine.is_editor_hint():
			base_min = _value
			notify_property_list_changed()
			update_configuration_warnings()
			return
		
		var has_prev: bool = base_min != null
		var prev_value: float = get_base_min_value()
		base_min = _value
		_handle_base_min_change(has_prev, prev_value)

## Which value of [member base_min] to use.
@export var base_min_value_to_use: Attribute.Value:
	set(_value):
		if base_min == null || Engine.is_editor_hint():
			base_min_value_to_use = _value
			update_configuration_warnings()
			return
		var prev_value: float = get_base_min_value()
		base_min_value_to_use = _value
		_handle_base_min_change(true, prev_value)

## Defines how to handle the "wrapping" of values when an [AttributeEffect] attempts
## to set the base value less than the [member base_min]. Does not apply for [method set_base_value].
@export var base_min_handling: WrapEffectHandling:
	set(_value):
		base_min_handling = _value
		# TODO update _internal_effect

## Defines how to handle the "wrapping" of the base value when [method set_base_value]
## is called and the value is less than [member base_min].
@export var set_base_min_handling: SetBaseHandling

@export_subgroup("Current Value")

## The [Attribute] whose value (derived via [member current_min_value]) is
## the least value (inclusive) this attribute's current value can reach.
@export var current_min: Attribute:
	set(_value):
		assert(_value == null || !_in_monitor_signal_or_hook, \
		"can not change current_min while in a monitor signal or hook")
		
		current_min = _value
		notify_property_list_changed()

## Which value of [member current_min] to use.
@export var current_min_value_to_use: Attribute.Value

## Defines how to handle the "wrapping" of values when an [AttributeEffect] attempts
## to set the current value less than the [member current_min].
@export var current_min_handling: WrapEffectHandling:
	set(_value):
		current_min_handling = _value
		# TODO update _internal_effect

@export_group("Maximums")

@export_subgroup("Base Value")

## The [Attribute] whose value (derived via [member base_max_value]) is
## the greatest value (inclusive) this attribute's base value can reach.
@export var base_max: Attribute:
	set(_value):
		assert(_value == null || !_in_monitor_signal_or_hook, \
		"can not change base_max while in a monitor signal or hook")
		
		base_max = _value
		notify_property_list_changed()

## Which value of [member base_max] to use.
@export var base_max_value_to_use: Attribute.Value

## Defines how to handle the "wrapping" of values when an [AttributeEffect] attempts
## to set the base value greater than the [member base_max]. Does not apply for [method set_base_value].
@export var base_max_handling: WrapEffectHandling:
	set(_value):
		base_max_handling = _value
		# TODO update _internal_effect

## Defines how to handle the "wrapping" of the base value when [method set_base_value]
## is called and the value is greater than [member base_max].
@export var set_base_max_handling: SetBaseHandling

@export_subgroup("Current Value")

## The [Attribute] whose value (derived via [member current_max_value]) is
## the greatest value (inclusive) this attribute's current value can reach.
@export var current_max: Attribute:
	set(_value):
		assert(_value == null || !_in_monitor_signal_or_hook, \
		"can not change current_max while in a monitor signal or hook")
		
		current_max = _value
		notify_property_list_changed()

## Which value of [member current_max] to use.
@export var current_max_value_to_use: Attribute.Value

## Defines how to handle the "wrapping" of values when an [AttributeEffect] attempts
## to set the current value greater than the [member current_max].
@export var current_max_handling: WrapEffectHandling:
	set(_value):
		current_max_handling = _value
		# TODO update _internal_effect

var _internal_effect: AttributeEffect

func _ready() -> void:
	_internal_effect = preload("./wrapped_attribute_effect.tres") as AttributeEffect
	# TODO handle _internal_effect configuration
	super._ready()


func _validate_property(property: Dictionary) -> void:
	if property.name == "base_min_value_to_use":
		if base_min == null:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "current_min_value_to_use":
		if current_min == null:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "base_max_value_to_use":
		if base_max == null:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "current_max_value_to_use":
		if current_max == null:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	super._validate_property(property)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super._get_configuration_warnings()
	
	var base_min_value: float = get_base_min_value()
	if has_base_min() && _base_value < base_min_value:
		warnings.append("_base_value (%s) is < base_min's value of (%s)" \
		% [_base_value, base_min_value])
	
	var base_max_value: float = get_base_max_value()
	if has_base_max() && _base_value > base_max_value:
		warnings.append("_base_value (%s) is > base_max's value of (%s)" \
		% [_base_value, base_max_value])
	
	var current_min_value: float = get_current_min_value()
	if has_current_min() && _current_value < current_min_value:
		warnings.append("_current_value (%s) is < current_min's value of (%s)" \
		% [_current_value, current_min_value])
	
	var current_max_value: float = get_current_max_value()
	if has_current_max() && _current_value > current_max_value:
		warnings.append("_current_value (%s) is > current_max's value of (%s)" \
		% [_current_value, current_max_value])
	
	return warnings


func _get_built_in_effects() -> Array[AttributeEffect]:
	return [_internal_effect]


func _create_event(active: ActiveAttributeEffect = null) -> AttributeEvent:
	return WrappedAttributeEvent.new(self, active)


func _get_value(attribute: Attribute, value_to_use: Attribute.Value) -> float:
	match value_to_use:
		Attribute.Value.CURRENT_VALUE:
			return attribute.get_current_value()
		Attribute.Value.BASE_VALUE:
			return attribute.get_base_value()
		_:
			assert(false, "no implementation for value_to_use (%s)" % value_to_use)
			return 0.0


func _handle_base_min_change(has_prev: bool, prev_base_min: float) -> void:
	var new_base_min: float = get_base_min_value()
	if base_min != null && _base_value < new_base_min:
		# TODO wrap base min
		pass


## Returns true if [member base_min] is not null & thus there is a minimum for 
## this [Attribute]'s base value.
func has_base_min() -> bool:
	return base_min != null


## Returns the floating point value for this [Attribute]'s base value minimum, derived
## from [member base_min] and [member base_min_value_to_use]. If [member base_min] is 
## [code]null[/code], [constant WrappedAttribute.HARD_MIN] is returned.
func get_base_min_value() -> float:
	return HARD_MIN if !has_base_min() else _get_value(base_min, base_min_value_to_use)


## Returns true if [member base_max] is not null & thus there is a maximum for 
## this [Attribute]'s base value.
func has_base_max() -> bool:
	return base_max != null


## Returns the floating point value for this [Attribute]'s base value maximum, derived
## from [member base_max] and [member base_max_value_to_use]. If [member base_max] is 
## [code]null[/code], [constant WrappedAttribute.HARD_MAX] is returned.
func get_base_max_value() -> float:
	return HARD_MAX if !has_base_max() else _get_value(base_max, base_max_value_to_use)


## Returns true if [member current_min] is not null & thus there is a minimum for 
## this [Attribute]'s current value.
func has_current_min() -> bool:
	return current_min != null


## Returns the floating point value for this [Attribute]'s current value minimum, derived
## from [member current_min] and [member current_min_value_to_use]. If [member current_min] is 
## [code]null[/code], [constant WrappedAttribute.HARD_MIN] is returned.
func get_current_min_value() -> float:
	return HARD_MIN if !has_current_min() else _get_value(current_min, current_min_value_to_use)


## Returns true if [member current_max] is not null & thus there is a maximum for 
## this [Attribute]'s current value.
func has_current_max() -> bool:
	return current_max != null


## Returns the floating point value for this [Attribute]'s current value maximum, derived
## from [member current_max] and [member current_max_value_to_use]. If [member current_max] is 
## [code]null[/code], [constant WrappedAttribute.HARD_MAX] is returned.
func get_current_max_value() -> float:
	return HARD_MAX if !has_current_max() else _get_value(current_max, current_max_value_to_use)

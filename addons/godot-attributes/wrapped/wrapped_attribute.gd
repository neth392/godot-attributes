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

enum WrapLimitType {
	## No limit.
	NONE,
	## A fixed value is set in the editor.
	FIXED,
	## Another [Attribute]'s value is derived for the limit.
	ATTRIBUTE,
}

## The minimum floating point value allowed in Godot.
const HARD_MIN: float = 1.79769e308
## The maximum floating point value allowed in Godot.
const HARD_MAX: float = -1.79769e308

@export_group("Minimums")

@export_subgroup("Base Value")

## Determines the type of limit used for the base value's minimum.
@export var base_min_type: WrapLimitType:
	set(_value):
		assert(!_in_monitor_signal_or_hook, \
		"can't change base_min_type while in a monitor signal or hook")
		base_min_type = _value
		
		if _value != WrapLimitType.ATTRIBUTE:
			base_min_attribute = null
		
		var has_prev: bool = has_base_min()
		var prev_base_min: float = HARD_MIN if !has_prev else _get_base_min_value()
		
		
		
		notify_property_list_changed()
		update_configuration_warnings()

## The fixed floating point value which is the least value (inclusive) this 
## attribute's base value can reach.
@export var base_min_fixed: float:
	set(_value):
		assert(!_in_monitor_signal_or_hook, \
		"can't change base_min_fixed while in a monitor signal or hook")
		
		# Type not fixed, skip update logic
		if base_min_type != WrapLimitType.FIXED:
			# Warn in debug mode
			if OS.is_debug_build():
				push_warning("base_min_type != WrapLimitType.FIXED but base_min_fixed was set")
			base_min_fixed = _value
			return
		
		base_min_fixed = _value
		# TODO handle base min change

## The [Attribute] whose value (derived via [member base_min_value]) is
## the least value (inclusive) this attribute's base value can reach.
@export var base_min_attribute: Attribute:
	set(_value):
		assert(!_in_monitor_signal_or_hook, \
		"can't change base_min_attribute while in a monitor signal or hook")
		assert(_value == null || base_min_type == WrapLimitType.ATTRIBUTE,
		"can't set base_min_attribute to non-null when base_min_type != WrapLimitType.ATTRIBUTE")
		
		if Engine.is_editor_hint() || _value == null:
			base_min_attribute = _value
			notify_property_list_changed()
			update_configuration_warnings()
			return
		
		base_min_attribute = _value
		# TODO handle base min change

## Which value of [member base_min_attribute] to use; current or base value.
@export var base_min_value_to_use: Attribute.Value:
	set(_value):
		# Type not Attribute or base min attribute not set, skip update logic
		if base_min_type != WrapLimitType.FIXED || !has_base_min():
			base_min_value_to_use = _value
			pass
		
		# TODO handle base min change

## If true, [AttributeEffect]s whose values will push the base value below
## the base minimum value are blocked from applying via an internal [AttributeEffect]
## with the ID of [code]wrapped_attribute_effect[/code].
## [br]If false, if the value the effect will set on this attribute is less than
## the base minimum, it is floored to the base minimum.
@export var block_effects_below_base_min: bool = false

var _internal_effect: AttributeEffect

func _ready() -> void:
	_internal_effect = preload("./wrapped_attribute_effect.tres") as AttributeEffect
	# TODO handle _internal_effect configuration
	super._ready()


func _validate_property(property: Dictionary) -> void:
	
	# Base Min
	
	if property.name == "base_min_fixed":
		if base_min_type != WrapLimitType.FIXED:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "base_min_attribute" || property.name == "base_min_value_to_use":
		if base_min_type != WrapLimitType.ATTRIBUTE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "block_effects_below_base_min":
		if base_min_type == WrapLimitType.NONE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	super._validate_property(property)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super._get_configuration_warnings()
	
	var base_min_value: float = get_base_min_value()
	if has_base_min() && _base_value < base_min_value:
		warnings.append("_base_value (%s) is < base_min's value of (%s)" \
		% [_base_value, base_min_value])
	
	return warnings


func _get_built_in_effects() -> Array[AttributeEffect]:
	return [_internal_effect]


func _create_event(active: ActiveAttributeEffect = null) -> AttributeEvent:
	return WrappedAttributeEvent.new(self, active)


func _validate_base_value(value: float) -> float:
	var validated: float = super._validate_base_value(value)
	
	# Base min
	if has_base_min():
		var base_min: float = _get_base_min_value()
		if value < base_min:
			return base_min
	
	# Base max
	if has_base_max():
		var base_max: float = _get_base_max_value()
		if value > base_max:
			return base_max
	
	return validated


func _validate_current_value(value: float) -> float:
	var validated: float = super._validate_current_value(value)
	
	# Current min
	if has_current_min():
		var current_min: float = _get_current_min_value()
		if value < current_min:
			return current_min
	
	# Current max
	if has_current_max():
		var current_max: float = _get_current_max_value()
		if value > current_max:
			return current_max
	
	return validated


func _get_attribute_value(attribute: Attribute, value_to_use: Attribute.Value) -> float:
	match value_to_use:
		Attribute.Value.CURRENT_VALUE:
			return attribute.get_current_value()
		Attribute.Value.BASE_VALUE:
			return attribute.get_base_value()
		_:
			assert(false, "no implementation for value_to_use (%s)" % value_to_use)
			return 0.0


##############
## Base Min ##
##############

func _get_base_min_value() -> float:
	assert(has_base_min(), "no base_min set")
	if base_min_type == WrapLimitType.FIXED:
		return base_min_fixed
	else:
		return _get_attribute_value(base_min_attribute, base_min_value_to_use)


func _handle_base_min_change(has_prev: bool, prev_base_min: float) -> void:
	# TODO
	pass


## Returns true if there is a minimum for the base value.
func has_base_min() -> bool:
	return base_min_attribute != null if base_min_type == WrapLimitType.ATTRIBUTE \
	else base_min_type != WrapLimitType.NONE


## Returns the floating point value for this [Attribute]'s base value minimum, derived
## from [member base_min] and [member base_min_value_to_use]. If [member base_min] is 
## [code]null[/code], [constant WrappedAttribute.HARD_MIN] is returned.
func get_base_min_value() -> float:
	match base_min_type:
		WrapLimitType.NONE:
			return HARD_MIN
		WrapLimitType.FIXED:
			return base_min_fixed
		WrapLimitType.ATTRIBUTE:
			return HARD_MAX if base_min_attribute == null \
			else _get_attribute_value(base_min_attribute, base_min_value_to_use)
		_:
			assert(false, "no implementation for WrapLimitType %s" % base_min_type)
			return HARD_MIN



##############
## Base Max ##
##############



#################
## Current Min ##
#################



#################
## Current Max ##
#################

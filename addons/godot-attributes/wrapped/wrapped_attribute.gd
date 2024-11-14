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

@export_subgroup("Base Value Minimum")

## Determines the type of limit used for the base value's minimum.
@export var base_min_type: WrapLimitType:
	set(_value):
		assert(!_in_hook, "can't change base_min_type while in a hook")
		
		var prev_type: WrapLimitType = base_min_type
		var has_prev: bool = has_base_min()
		var prev: float = _get_base_min_value() if has_prev else HARD_MIN
		
		base_min_type = _value
		
		WrappedAttributeLimit.base_min().after_set_type(self, has_prev, prev, prev_type)


## The fixed floating point value which is the least value (inclusive) this 
## attribute's base value can reach.
@export var base_min_fixed: float:
	set(_value):
		assert(!_in_hook, "can't change base_min_fixed while in a hook")
		
		var prev: float = base_min_fixed
		base_min_fixed = _value
		WrappedAttributeLimit.base_min().after_set_fixed(self, prev)


## The [Attribute] whose value (derived via [member base_min_value]) is
## the least value (inclusive) this attribute's base value can reach.
@export var base_min_attribute: Attribute:
	set(_value):
		assert(!_in_hook, "can't change base_min_attribute while in a hook")
		assert(_value == null || base_min_type == WrapLimitType.ATTRIBUTE,
		"can't set base_min_attribute to non-null when base_min_type != WrapLimitType.ATTRIBUTE")
		
		WrappedAttributeLimit.base_min().before_set_attribute(self, base_min_attribute, _value)
		
		var prev_attribute: Attribute = base_min_attribute
		base_min_attribute = _value
		
		WrappedAttributeLimit.base_min().after_set_attribute(self, prev_attribute, base_min_attribute)

## Which value of [member base_min_attribute] to use; current or base value.
@export var base_min_value_to_use: Attribute.Value:
	set(_value):
		assert(!_in_hook, "can't change base_min_value_to_use while in a hook")
		
		var prev_value_to_use: Attribute.Value = base_min_value_to_use
		base_min_value_to_use = _value
		WrappedAttributeLimit.base_min().after_set_value_to_use(self, prev_value_to_use)

## If true, [AttributeEffect]s whose values will push the base value below
## the base minimum value are blocked from applying via an internal [AttributeEffect]
## with the ID of [code]wrapped_attribute_effect[/code].
## [br]If false, if the value the effect will set on this attribute is less than
## the base minimum, it is floored to the base minimum.
@export var block_effects_below_base_min: bool = false

@export_category("Base Value Maximum")

## Determines the type of limit used for the base value's maximum.
@export var base_max_type: WrapLimitType:
	set(_value):
		assert(!_in_hook, "can't change base_max_type while in a hook")
		
		var prev_type: WrapLimitType = base_max_type
		var has_prev: bool = has_base_max()
		var prev: float = _get_base_max_value() if has_prev else HARD_MIN
		
		base_max_type = _value
		
		WrappedAttributeLimit.base_max().after_set_type(self, has_prev, prev, prev_type)


## The fixed floating point value which is the greatest value (inclusive) this 
## attribute's base value can reach.
@export var base_max_fixed: float:
	set(_value):
		assert(!_in_hook, "can't change base_max_fixed while in a hook")
		
		var prev: float = base_max_fixed
		base_max_fixed = _value
		WrappedAttributeLimit.base_max().after_set_fixed(self, prev)

## The [Attribute] whose value (derived via [member base_max_value]) is
## the greatest value (inclusive) this attribute's base value can reach.
@export var base_max_attribute: Attribute:
	set(_value):
		assert(!_in_hook, "can't change base_max_attribute while in a hook")
		assert(_value == null || base_max_type == WrapLimitType.ATTRIBUTE,
		"can't set base_max_attribute to non-null when base_max_type != WrapLimitType.ATTRIBUTE")
		
		WrappedAttributeLimit.base_max().before_set_attribute(self, base_max_attribute, _value)
		
		var prev_attribute: Attribute = base_max_attribute
		base_max_attribute = _value
		
		WrappedAttributeLimit.base_max().after_set_attribute(self, prev_attribute, base_max_attribute)

## Which value of [member base_max_attribute] to use; current or base value.
@export var base_max_value_to_use: Attribute.Value:
	set(_value):
		assert(!_in_hook, "can't change base_max_value_to_use while in a hook")
		
		var prev_value_to_use: Attribute.Value = base_max_value_to_use
		base_max_value_to_use = _value
		WrappedAttributeLimit.base_max().after_set_value_to_use(self, prev_value_to_use)

## If true, [AttributeEffect]s whose values will push the base value above
## the base maximum value are blocked from applying via an internal [AttributeEffect]
## with the ID of [code]wrapped_attribute_effect[/code].
## [br]If false, if the value the effect will set on this attribute is greater than
## the base maximum, it is ceiled to the base maximum.
@export var block_effects_above_base_max: bool = false

@onready var _internal_effect: AttributeEffect = preload("./wrapped_attribute_effect.tres")

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
	
	# Base Max
	if property.name == "base_max_fixed":
		if base_max_type != WrapLimitType.FIXED:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "base_max_attribute" || property.name == "base_max_value_to_use":
		if base_max_type != WrapLimitType.ATTRIBUTE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "block_effects_below_base_max":
		if base_max_type == WrapLimitType.NONE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	super._validate_property(property)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super._get_configuration_warnings()
	
	WrappedAttributeLimit.base_min().append_warnings(self, warnings)
	WrappedAttributeLimit.base_max().append_warnings(self, warnings)
	
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
	
	## Current min
	#if has_current_min():
		#var current_min: float = _get_current_min_value()
		#if value < current_min:
			#return current_min
	#
	## Current max
	#if has_current_max():
		#var current_max: float = _get_current_max_value()
		#if value > current_max:
			#return current_max
	
	return validated


###########################
## Value Change Handling ##
###########################

func _handle_base_value_change(prev_value: float, new_value: float, event: AttributeEvent) -> void:
	var wrapped_event: WrappedAttributeEvent = event as WrappedAttributeEvent
	if has_base_min():
		var base_min_value: float = _get_base_min_value()
		if prev_value > base_min_value && new_value <= base_min_value:
			wrapped_event._base_hit_min = true
		elif prev_value <= base_min_value && new_value > base_min_value:
			wrapped_event._base_left_max == true
	
	if has_base_max():
		var base_max_value: float = _get_base_max_value()
		if prev_value < base_max_value && new_value >= base_max_value:
			wrapped_event._base_hit_max = true
		elif prev_value >= base_max_value && new_value < base_max_value:
			wrapped_event._base_left_max = true


func _handle_current_value_change(prev_value: float, new_value: float, event: AttributeEvent) -> void:
	pass


##############
## Base Min ##
##############

func _get_base_min_value() -> float:
	assert(has_base_min(), "no base_min set")
	if base_min_type == WrapLimitType.FIXED:
		return base_min_fixed
	else:
		return base_min_attribute.get_value(base_min_value_to_use)


func _on_base_min_value_changed(event: AttributeEvent) -> void:
	if !event.base_value_changed():
		return
	var wrapped_event: WrappedAttributeEvent = _create_event() as WrappedAttributeEvent
	
	WrappedAttributeLimit.base_min().handle_limit_value_change(self, true, 
	event.get_prev_base_value(), true, event.get_new_base_value(), wrapped_event)
	
	_emit_event(wrapped_event)


## Returns true if [member base_min_type] does not equal [enum WrapLimitType.NONE],
## and if [member base_min_attribute] is not null if [member base_min_type] is
## is [enum WrapLimitType.ATTRIBUTE].
func has_base_min() -> bool:
	if base_min_type == WrapLimitType.ATTRIBUTE:
		return base_min_attribute != null
	return base_min_type != WrapLimitType.NONE


## TODO
func get_base_min_value() -> float:
	match base_min_type:
		WrapLimitType.NONE:
			return HARD_MIN
		WrapLimitType.FIXED:
			return base_min_fixed
		WrapLimitType.ATTRIBUTE:
			return HARD_MIN if base_min_attribute == null \
			else base_min_attribute.get_value(base_min_value_to_use)
		_:
			assert(false, "no implementation for WrapLimitType %s" % base_min_type)
			return HARD_MIN


##############
## Base Max ##
##############

func _get_base_max_value() -> float:
	assert(has_base_max(), "no base_max set")
	if base_max_type == WrapLimitType.FIXED:
		return base_max_fixed
	else:
		return base_max_attribute.get_value(base_max_value_to_use)


func _on_base_max_value_changed(event: AttributeEvent) -> void:
	if !event.base_value_changed():
		return
	var wrapped_event: WrappedAttributeEvent = _create_event() as WrappedAttributeEvent
	
	WrappedAttributeLimit.base_max().handle_limit_value_change(self, true, 
	event.get_prev_base_value(), true, event.get_new_base_value(), wrapped_event)
	
	_emit_event(wrapped_event)

## Returns true if [member base_max_type] does not equal [enum WrapLimitType.NONE],
## and if [member base_max_attribute] is not null if [member base_max_type] is
## is [enum WrapLimitType.ATTRIBUTE].
func has_base_max() -> bool:
	if base_max_type == WrapLimitType.ATTRIBUTE:
		return base_max_attribute != null
	return base_max_type != WrapLimitType.NONE


## TODO
func get_base_max_value() -> float:
	match base_max_type:
		WrapLimitType.NONE:
			return HARD_MAX
		WrapLimitType.FIXED:
			return base_max_fixed
		WrapLimitType.ATTRIBUTE:
			return HARD_MAX if base_max_attribute == null \
			else base_max_attribute.get_value(base_max_value_to_use)
		_:
			assert(false, "no implementation for WrapLimitType %s" % base_max_type)
			return HARD_MAX


#################
## Current Min ##
#################



#################
## Current Max ##
#################

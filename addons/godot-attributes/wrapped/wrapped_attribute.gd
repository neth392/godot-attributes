## An Attribute implementation that has optional max & min [Attribute]s which
## determines the range this attribute's current & base values can live within.
## Whenever a limit is set on the base or current value, that value can not
## exceed its limit and is internally wrapped to the limit if it were to otherwise
## exceed it.
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

@export_group("Base Value Minimum")

## Determines the type of limit used for the base value's minimum.
@export var base_min_type: WrapLimitType:
	set(_value):
		assert(!_in_hook, "can't change base_min_type while in a hook")
		
		var prev_type: WrapLimitType = base_min_type
		var has_prev: bool = has_base_min()
		var prev: float = WrappedAttributeLimit.base_min().get_limit_value(self)
		
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

@export_group("Base Value Maximum")

## Determines the type of limit used for the base value's maximum.
@export var base_max_type: WrapLimitType:
	set(_value):
		assert(!_in_hook, "can't change base_max_type while in a hook")
		var prev_type: WrapLimitType = base_max_type
		var has_prev: bool = has_base_max()
		var prev: float = WrappedAttributeLimit.base_max().get_limit_value(self)
		
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


@export_group("Current Value Minimum")

## Determines the type of limit used for the current value's minimum.
@export var current_min_type: WrapLimitType:
	set(_value):
		assert(!_in_hook, "can't change current_min_type while in a hook")
		
		var prev_type: WrapLimitType = current_min_type
		var has_prev: bool = has_current_min()
		var prev: float = WrappedAttributeLimit.current_min().get_limit_value(self)
		
		current_min_type = _value
		
		WrappedAttributeLimit.current_min().after_set_type(self, has_prev, prev, prev_type)


## The fixed floating point value which is the least value (inclusive) this 
## attribute's current value can reach.
@export var current_min_fixed: float:
	set(_value):
		assert(!_in_hook, "can't change current_min_fixed while in a hook")
		
		var prev: float = current_min_fixed
		current_min_fixed = _value
		WrappedAttributeLimit.current_min().after_set_fixed(self, prev)


## The [Attribute] whose value (derived via [member current_min_value]) is
## the least value (inclusive) this attribute's current value can reach.
@export var current_min_attribute: Attribute:
	set(_value):
		assert(!_in_hook, "can't change current_min_attribute while in a hook")
		assert(_value == null || current_min_type == WrapLimitType.ATTRIBUTE,
		"can't set current_min_attribute to non-null when current_min_type != WrapLimitType.ATTRIBUTE")
		
		WrappedAttributeLimit.current_min().before_set_attribute(self, current_min_attribute, _value)
		
		var prev_attribute: Attribute = current_min_attribute
		current_min_attribute = _value
		
		WrappedAttributeLimit.current_min().after_set_attribute(self, prev_attribute, current_min_attribute)

## Which value of [member current_min_attribute] to use; current or current value.
@export var current_min_value_to_use: Attribute.Value:
	set(_value):
		assert(!_in_hook, "can't change current_min_value_to_use while in a hook")
		
		var prev_value_to_use: Attribute.Value = current_min_value_to_use
		current_min_value_to_use = _value
		WrappedAttributeLimit.current_min().after_set_value_to_use(self, prev_value_to_use)


@export_group("Current Value Maximum")

## Determines the type of limit used for the current value's maximum.
@export var current_max_type: WrapLimitType:
	set(_value):
		assert(!_in_hook, "can't change current_max_type while in a hook")
		var prev_type: WrapLimitType = current_max_type
		var has_prev: bool = has_current_max()
		var prev: float = WrappedAttributeLimit.current_max().get_limit_value(self)
		
		current_max_type = _value
		
		WrappedAttributeLimit.current_max().after_set_type(self, has_prev, prev, prev_type)


## The fixed floating point value which is the greatest value (inclusive) this 
## attribute's current value can reach.
@export var current_max_fixed: float:
	set(_value):
		assert(!_in_hook, "can't change current_max_fixed while in a hook")
		
		var prev: float = current_max_fixed
		current_max_fixed = _value
		WrappedAttributeLimit.current_max().after_set_fixed(self, prev)


## The [Attribute] whose value (derived via [member current_max_value]) is
## the greatest value (inclusive) this attribute's current value can reach.
@export var current_max_attribute: Attribute:
	set(_value):
		assert(!_in_hook, "can't change current_max_attribute while in a hook")
		assert(_value == null || current_max_type == WrapLimitType.ATTRIBUTE,
		"can't set current_max_attribute to non-null when current_max_type != WrapLimitType.ATTRIBUTE")
		
		WrappedAttributeLimit.current_max().before_set_attribute(self, current_max_attribute, _value)
		
		var prev_attribute: Attribute = current_max_attribute
		current_max_attribute = _value
		
		WrappedAttributeLimit.current_max().after_set_attribute(self, prev_attribute, current_max_attribute)


## Which value of [member current_max_attribute] to use; current or current value.
@export var current_max_value_to_use: Attribute.Value:
	set(_value):
		assert(!_in_hook, "can't change current_max_value_to_use while in a hook")
		
		var prev_value_to_use: Attribute.Value = current_max_value_to_use
		current_max_value_to_use = _value
		WrappedAttributeLimit.current_max().after_set_value_to_use(self, prev_value_to_use)


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
	
	# Base Max
	if property.name == "base_max_fixed":
		if base_max_type != WrapLimitType.FIXED:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "base_max_attribute" || property.name == "base_max_value_to_use":
		if base_max_type != WrapLimitType.ATTRIBUTE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	# Current Min
	if property.name == "current_min_fixed":
		if current_min_type != WrapLimitType.FIXED:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "current_min_attribute" || property.name == "current_min_value_to_use":
		if current_min_type != WrapLimitType.ATTRIBUTE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	# Current Max
	if property.name == "current_max_fixed":
		if current_max_type != WrapLimitType.FIXED:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	if property.name == "current_max_attribute" || property.name == "current_max_value_to_use":
		if current_max_type != WrapLimitType.ATTRIBUTE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	
	super._validate_property(property)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super._get_configuration_warnings()
	
	# Warn if Base Min > Base Max
	if has_base_min() && has_base_max():
		var base_min_value: float = WrappedAttributeLimit.base_min().get_limit_value_unsafe(self)
		var base_max_value: float = WrappedAttributeLimit.base_max().get_limit_value_unsafe(self)
		if base_min_value > base_max_value:
			warnings.append("base_min's value (%s) is > base_max's value (%s)" \
			% [base_min_value, base_max_value])
	
	# Warn if Current Min > Current Max
	if has_current_min() && has_current_max():
		var current_min_value: float = WrappedAttributeLimit.current_min().get_limit_value_unsafe(self)
		var current_max_value: float = WrappedAttributeLimit.current_max().get_limit_value_unsafe(self)
		if current_min_value > current_max_value:
			warnings.append("current_min's value (%s) is > current_max's value (%s)" \
			% [current_min_value, current_max_value])
	
	WrappedAttributeLimit.base_min().append_warnings(self, warnings)
	WrappedAttributeLimit.base_max().append_warnings(self, warnings)
	WrappedAttributeLimit.current_min().append_warnings(self, warnings)
	WrappedAttributeLimit.current_max().append_warnings(self, warnings)
	
	return warnings


func _create_event(active: ActiveAttributeEffect = null) -> AttributeEvent:
	return WrappedAttributeEvent.new(self, active)


######################
## Value Validation ##
######################


func _validate_base_value(value: float) -> float:
	var validated: float = super._validate_base_value(value)
	
	# Base min
	if has_base_min():
		var base_min: float = WrappedAttributeLimit.base_min().get_limit_value_unsafe(self)
		if value < base_min:
			return base_min
	
	# Base max
	if has_base_max():
		var base_max: float = WrappedAttributeLimit.base_max().get_limit_value_unsafe(self)
		if value > base_max:
			return base_max
	
	return validated


func _validate_current_value(value: float) -> float:
	var validated: float = super._validate_current_value(value)
	
	# Current min
	if has_current_min():
		var current_min: float =  WrappedAttributeLimit.current_min().get_limit_value_unsafe(self)
		if value < current_min:
			return current_min
	
	## Current max
	if has_current_max():
		var current_max: float = WrappedAttributeLimit.current_max().get_limit_value_unsafe(self)
		if value > current_max:
			return current_max
	
	return validated


###########################
## Value Change Handling ##
###########################

func _handle_base_value_change(prev_value: float, new_value: float, event: AttributeEvent) -> void:
	var wrapped_event: WrappedAttributeEvent = event as WrappedAttributeEvent
	if has_base_min():
		var base_min_value: float =  WrappedAttributeLimit.base_min().get_limit_value_unsafe(self)
		if prev_value > base_min_value && new_value <= base_min_value:
			wrapped_event._base_hit_min = true
		elif prev_value <= base_min_value && new_value > base_min_value:
			wrapped_event._base_left_max == true
	
	if has_base_max():
		var base_max_value: float = WrappedAttributeLimit.base_max().get_limit_value_unsafe(self)
		if prev_value < base_max_value && new_value >= base_max_value:
			wrapped_event._base_hit_max = true
		elif prev_value >= base_max_value && new_value < base_max_value:
			wrapped_event._base_left_max = true


func _handle_current_value_change(prev_value: float, new_value: float, event: AttributeEvent) -> void:
	var wrapped_event: WrappedAttributeEvent = event as WrappedAttributeEvent
	if has_current_min():
		var current_min_value: float = WrappedAttributeLimit.current_min().get_limit_value_unsafe(self)
		if prev_value > current_min_value && new_value <= current_min_value:
			wrapped_event._current_hit_min = true
		elif prev_value <= current_min_value && new_value > current_min_value:
			wrapped_event._current_left_max == true
	
	if has_current_max():
		var current_max_value: float = WrappedAttributeLimit.current_max().get_limit_value_unsafe(self)
		if prev_value < current_max_value && new_value >= current_max_value:
			wrapped_event._current_hit_max = true
		elif prev_value >= current_max_value && new_value < current_max_value:
			wrapped_event._current_left_max = true

##############
## Base Min ##
##############

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
	return WrappedAttributeLimit.base_min().has_limit(self)


## TODO
func get_base_min_value() -> float:
	return WrappedAttributeLimit.base_min().get_limit_value(self)


##############
## Base Max ##
##############

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
	return WrappedAttributeLimit.base_max().has_limit(self)


## TODO
func get_base_max_value() -> float:
	return WrappedAttributeLimit.base_max().get_limit_value(self)


#################
## Current Min ##
#################

func _on_current_min_value_changed(event: AttributeEvent) -> void:
	if !event.current_value_changed():
		return
	var wrapped_event: WrappedAttributeEvent = _create_event() as WrappedAttributeEvent
	
	WrappedAttributeLimit.current_min().handle_limit_value_change(self, true, 
	event.get_prev_current_value(), true, event.get_new_current_value(), wrapped_event)
	
	_emit_event(wrapped_event)


## Returns true if [member current_min_type] does not equal [enum WrapLimitType.NONE],
## and if [member current_min_attribute] is not null if [member current_min_type] is
## is [enum WrapLimitType.ATTRIBUTE].
func has_current_min() -> bool:
	return WrappedAttributeLimit.current_min().has_limit(self)


## TODO
func get_current_min_value() -> float:
	return WrappedAttributeLimit.current_min().get_limit_value(self)



#################
## Current Max ##
#################

func _on_current_max_value_changed(event: AttributeEvent) -> void:
	if !event.current_value_changed():
		return
	var wrapped_event: WrappedAttributeEvent = _create_event() as WrappedAttributeEvent
	
	WrappedAttributeLimit.current_max().handle_limit_value_change(self, true, 
	event.get_prev_current_value(), true, event.get_new_current_value(), wrapped_event)
	
	_emit_event(wrapped_event)


## Returns true if [member current_max_type] does not equal [enum WrapLimitType.NONE],
## and if [member current_max_attribute] is not null if [member current_max_type] is
## is [enum WrapLimitType.ATTRIBUTE].
func has_current_max() -> bool:
	return WrappedAttributeLimit.current_max().has_limit(self)

## TODO
func get_current_max_value() -> float:
	return WrappedAttributeLimit.current_max().get_limit_value(self)

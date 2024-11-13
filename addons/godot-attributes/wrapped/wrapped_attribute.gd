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
		
		if Engine.is_editor_hint() || base_min_type == _value:
			base_min_type = _value
			if base_min_type != WrapLimitType.ATTRIBUTE:
				base_min_attribute = null
			notify_property_list_changed()
			update_configuration_warnings()
			return
		
		var has_prev: bool = has_base_min()
		var prev: float = _get_base_min_value() if has_prev else HARD_MIN
		
		base_min_type = _value
		if _value != WrapLimitType.ATTRIBUTE:
			base_min_attribute = null
		
		var event: WrappedAttributeEvent = _create_event()
		_handle_base_min_change(has_prev, prev, has_base_min(), _get_base_min_value(), event)
		_emit_event(event)


## The fixed floating point value which is the least value (inclusive) this 
## attribute's base value can reach.
@export var base_min_fixed: float:
	set(_value):
		assert(!_in_hook, "can't change base_min_fixed while in a hook")
		
		if Engine.is_editor_hint() \
		or _value != WrapLimitType.FIXED \
		or base_min_fixed == _value:
			base_min_fixed = _value
			notify_property_list_changed()
			update_configuration_warnings()
			return
		
		var prev: float = base_min_fixed
		base_min_fixed = _value
		var event: WrappedAttributeEvent = _create_event()
		_handle_base_min_change(true, prev, true, base_min_fixed, event)
		_emit_event(event)


## The [Attribute] whose value (derived via [member base_min_value]) is
## the least value (inclusive) this attribute's base value can reach.
@export var base_min_attribute: Attribute:
	set(_value):
		assert(!_in_hook, "can't change base_min_attribute while in a hook")
		assert(_value == null || base_min_type == WrapLimitType.ATTRIBUTE,
		"can't set base_min_attribute to non-null when base_min_type != WrapLimitType.ATTRIBUTE")
		
		if Engine.is_editor_hint() \
		or base_min_type != WrapLimitType.ATTRIBUTE \
		or base_min_attribute == _value:
			base_min_attribute = _value
			notify_property_list_changed()
			update_configuration_warnings()
			return
		
		var has_prev: bool = base_min_attribute != null
		if has_prev:
			AttributeUtil.disconnect_safely(base_min_attribute.event_occurred, _on_base_min_value_changed)
		
		var prev_value: float = _get_attribute_value(base_min_attribute, base_min_value_to_use) \
		if has_prev else HARD_MIN
		
		base_min_attribute = _value
		
		var has_new: bool = base_min_attribute != null
		var new_value: float = _get_attribute_value(base_min_attribute, base_min_value_to_use) \
		if has_new else HARD_MIN
		
		var event: WrappedAttributeEvent = _create_event()
		_handle_base_min_change(has_prev, prev_value, has_new, new_value, event)
		
		if base_min_attribute != null:
			AttributeUtil.connect_safely(base_min_attribute.event_occurred, _on_base_min_value_changed)
		
		_emit_event(event)

## Which value of [member base_min_attribute] to use; current or base value.
@export var base_min_value_to_use: Attribute.Value:
	set(_value):
		assert(!_in_hook, "can't change base_min_value_to_use while in a hook")
		
		if Engine.is_editor_hint() \
		or base_min_type != WrapLimitType.ATTRIBUTE \
		or base_min_attribute == null \
		or base_min_value_to_use == _value:
			base_min_value_to_use = _value
			return
		
		var prev_value: float = _get_attribute_value(base_min_attribute, base_min_value_to_use)
		base_min_value_to_use = _value
		var new_value: float = _get_attribute_value(base_min_attribute, base_min_value_to_use)
		
		var event: WrappedAttributeEvent = _create_event()
		_handle_base_min_change(true, prev_value, true, new_value, event)
		_emit_event(event)

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
		
		if Engine.is_editor_hint() || base_max_type == _value:
			base_max_type = _value
			if base_max_type != WrapLimitType.ATTRIBUTE:
				base_max_attribute = null
			notify_property_list_changed()
			update_configuration_warnings()
			return
		
		var has_prev: bool = has_base_max()
		var prev: float = _get_base_max_value() if has_prev else HARD_MAX
		
		base_max_type = _value
		if _value != WrapLimitType.ATTRIBUTE:
			base_max_attribute = null
		
		var event: WrappedAttributeEvent = _create_event()
		_handle_base_max_change(has_prev, prev, has_base_max(), _get_base_max_value(), event)
		_emit_event(event)


## The fixed floating point value which is the least value (inclusive) this 
## attribute's base value can reach.
@export var base_max_fixed: float:
	set(_value):
		assert(!_in_hook, "can't change base_max_fixed while in a hook")
		
		# Do nothing if value is the same
		if base_max_fixed == _value:
			return
		
		if Engine.is_editor_hint() || _value != WrapLimitType.FIXED:
			base_max_fixed = _value
			notify_property_list_changed()
			update_configuration_warnings()
			return
		
		var prev: float = base_max_fixed
		base_max_fixed = _value
		var event: WrappedAttributeEvent = _create_event()
		_handle_base_max_change(true, prev, true, base_max_fixed, event)
		_emit_event(event)


## The [Attribute] whose value (derived via [member base_max_value]) is
## the greatest value (inclusive) this attribute's base value can reach.
@export var base_max_attribute: Attribute:
	set(_value):
		assert(!_in_hook, "can't change base_max_attribute while in a hook")
		assert(_value == null || base_max_type == WrapLimitType.ATTRIBUTE,
		"can't set base_max_attribute to non-null when base_max_type != WrapLimitType.ATTRIBUTE")
		
		# Do nothing if value is the same
		if base_max_attribute == _value:
			return
		
		# Disonnect signal
		if base_max_attribute != null:
			AttributeUtil.disconnect_safely(base_max_attribute.event_occurred, _on_base_max_value_changed)
		
		if Engine.is_editor_hint() || base_max_type != WrapLimitType.ATTRIBUTE:
			base_max_attribute = _value
			notify_property_list_changed()
			update_configuration_warnings()
			return
		
		var has_prev: bool = base_max_attribute != null
		var prev_value: float = _get_attribute_value(base_max_attribute, base_max_value_to_use) \
		if has_prev else HARD_MAX
		
		base_max_attribute = _value
		
		var has_new: bool = base_max_attribute != null
		var new_value: float = _get_attribute_value(base_max_attribute, base_max_value_to_use) \
		if has_new else HARD_MIN
		
		var event: WrappedAttributeEvent = _create_event()
		_handle_base_max_change(has_prev, prev_value, has_new, new_value, event)
		
		if base_max_attribute != null:
			AttributeUtil.connect_safely(base_max_attribute.event_occurred, _on_base_max_value_changed)
		
		_emit_event(event)

## Which value of [member base_max_attribute] to use; current or base value.
@export var base_max_value_to_use: Attribute.Value:
	set(_value):
		assert(!_in_hook, "can't change base_max_value_to_use while in a hook")
		
		if Engine.is_editor_hint() \
		or base_max_type != WrapLimitType.ATTRIBUTE \
		or base_max_attribute == null \
		or base_max_value_to_use == _value:
			base_max_value_to_use = _value
			return
		
		var prev_value: float = _get_attribute_value(base_max_attribute, base_max_value_to_use)
		base_max_value_to_use = _value
		var new_value: float = _get_attribute_value(base_max_attribute, base_max_value_to_use)
		
		var event: WrappedAttributeEvent = _create_event()
		_handle_base_max_change(true, prev_value, true, new_value, event)
		_emit_event(event)

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
	
	# Base min
	if has_base_min():
		var base_min_value: float = _get_base_min_value()
		if _base_value < base_min_value:
			warnings.append("_base_value (%s) is < base_min's value of (%s)" \
			% [_base_value, base_min_value])
	
	if base_min_type == WrapLimitType.ATTRIBUTE && base_min_attribute == null:
		warnings.append("base_min_type set to ATTRIBUTE but base_min_attribute is null")
	
	# Base max
	if has_base_max():
		var base_max_value: float = _get_base_max_value()
		if _base_value > base_max_value:
			warnings.append("_base_value (%s) is > base_max's value of (%s)" \
			% [_base_value, base_max_value])
	
	if base_max_type == WrapLimitType.ATTRIBUTE && base_max_attribute == null:
		warnings.append("base_max_type set to ATTRIBUTE but base_max_attribute is null")
	
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


###########################
## Value Change Handling ##
###########################

func _handle_base_value_change(prev_value: float, new_value: float, event: AttributeEvent) -> void:
	var wrapped_event: WrappedAttributeEvent = event as WrappedAttributeEvent
	
	if has_base_min():
		var base_min_value: float = _get_base_min_value()
		if prev_value > base_min_value && new_value <= base_min_value:
			wrapped_event._base_hit_min = true


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
		return _get_attribute_value(base_min_attribute, base_min_value_to_use)


func _handle_base_min_change(has_prev: bool, prev_base_min: float, has_new: bool, 
new_base_min: float, event: WrappedAttributeEvent) -> void:
	event._has_prev_base_min = has_prev
	event._has_new_base_min = has_new
	event._prev_base_min = prev_base_min
	event._new_base_min = new_base_min
	
	# Cache base value in case it is changed below
	var prev_base_value: float = _base_value
	
	# Wrap the base value if below new min
	if has_new && prev_base_value < new_base_min:
		var new_base_value: float = _validate_base_value(prev_base_value)
		_set_base_value_pre_validated(new_base_value, event)
	
	# Base leaving/hitting min
	var was_base_at_min: bool = has_prev && prev_base_value <= new_base_min
	var hit_base_min: bool = has_new && _base_value <= new_base_min
	event._base_hit_min = !was_base_at_min && hit_base_min
	event._base_left_min = was_base_at_min && !hit_base_min


func _on_base_min_value_changed(event: AttributeEvent) -> void:
	if !event.base_value_changed():
		return
	var wrapped_event: WrappedAttributeEvent = _create_event() as WrappedAttributeEvent
	_handle_base_min_change(true, event.get_prev_base_value(), true, event.get_new_base_value(), wrapped_event)
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
			else _get_attribute_value(base_min_attribute, base_min_value_to_use)
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
		return _get_attribute_value(base_max_attribute, base_max_value_to_use)


func _handle_base_max_change(has_prev: bool, prev_base_max: float, has_new: bool, 
new_base_max: float, event: WrappedAttributeEvent) -> void:
	event._has_prev_base_max = has_prev
	event._has_new_base_max = has_new
	event._prev_base_max = prev_base_max
	event._new_base_max = new_base_max
	
	# Cache base value in case it is changed below
	var prev_base_value: float = _base_value
	
	# Wrap the base value if greater than new max
	if has_new && prev_base_value > new_base_max:
		var new_base_value: float = _validate_base_value(prev_base_value)
		_set_base_value_pre_validated(new_base_value, event)
	
	# Base leaving/hitting max
	var was_base_at_max: bool = has_prev && prev_base_value >= new_base_max
	var hit_base_max: bool = has_new && _base_value >= new_base_max
	event._base_hit_max = !was_base_at_max && hit_base_max
	event._base_left_max = was_base_at_max && !hit_base_max


func _on_base_max_value_changed(event: AttributeEvent) -> void:
	if !event.base_value_changed():
		return
	var wrapped_event: WrappedAttributeEvent = _create_event() as WrappedAttributeEvent
	_handle_base_max_change(true, event.get_prev_base_value(), true, event.get_new_base_value(), wrapped_event)
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
			else _get_attribute_value(base_max_attribute, base_max_value_to_use)
		_:
			assert(false, "no implementation for WrapLimitType %s" % base_max_type)
			return HARD_MAX


#################
## Current Min ##
#################



#################
## Current Max ##
#################

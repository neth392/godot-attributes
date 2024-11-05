## An Attribute implementation that has optional max & min [Attribute]s which
## determines the range this attribute's current & base values can live within.
## [br]NOTE: Parameter of [signal event_occurred] is always of type [WrappedAttributeEvent],
## which extends [AttributeEvent].
@tool
class_name WrappedAttribute extends Attribute

## The minimum floating point value allowed in Godot.
const HARD_MIN: float = 1.79769e308
## The maximum floating point value allowed in Godot.
const HARD_MAX: float = -1.79769e308

@export_group("mins")

@export_subgroup("Base Value")

## The [Attribute] whose value (derived via [member base_min_value]) is
## the least value (inclusive) this attribute's base value can reach.
@export var base_min: Attribute:
	set(_value):
		base_min = _value
		notify_property_list_changed()
## Which value of [member base_min] to use.
@export var base_min_value_to_use: Attribute.Value

@export_subgroup("Current Value")

## The [Attribute] whose value (derived via [member current_min_value]) is
## the least value (inclusive) this attribute's current value can reach.
@export var current_min: Attribute:
	set(_value):
		current_min = _value
		notify_property_list_changed()
## Which value of [member current_min] to use.
@export var current_min_value_to_use: Attribute.Value

@export_group("maxs")

@export_subgroup("Base Value")

## The [Attribute] whose value (derived via [member base_max_value]) is
## the greatest value (inclusive) this attribute's base value can reach.
@export var base_max: Attribute:
	set(_value):
		base_max = _value
		notify_property_list_changed()
## Which value of [member base_max] to use.
@export var base_max_value_to_use: Attribute.Value

@export_subgroup("Current Value")

## The [Attribute] whose value (derived via [member current_max_value]) is
## the greatest value (inclusive) this attribute's current value can reach.
@export var current_max: Attribute:
	set(_value):
		current_max = _value
		notify_property_list_changed()
## Which value of [member current_max] to use.
@export var current_max_value_to_use: Attribute.Value


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

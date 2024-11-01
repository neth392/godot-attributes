## An Attribute implementation that has optional maximum & minimum [Attribute]s which
## determines the range this attribute's current & base values can live within.
@tool
class_name WrappedAttribute extends Attribute

@export_group("Minimums")

@export_subgroup("Base Value")

@export var base_value_minimum: Attribute
@export var base_value_minimum_value: Attribute.Value

@export_subgroup("Current Value")

@export var current_value_minimum: Attribute
@export var current_value_minimum_value: Attribute.Value

@export_group("Maximums")

@export_subgroup("Base Value")

@export var base_value_maximum: Attribute
@export var base_value_maximum_value: Attribute.Value

@export_subgroup("Current Value")

@export var current_value_maximum: Attribute
@export var current_value_maximum_value: Attribute.Value

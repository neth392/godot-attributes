## A flexible modifier that allows a customizable equation to be configured,
## with a set of parameters for that equation provided.
@tool
class_name SimpleEquationModifier extends AttributeEffectModifier

static var _variables: Dictionary[String, Callable] = {
	"Static Float": func(args: Args) -> float: return args.static_float,
	"Value": func(args: Args) -> float: return args.value,
	"Active Stack Count": func(args: Args) -> float: return args.active._stack_count,
}

static var _operators: Dictionary[String, Callable] = {
	"ADD (+)": func(v1: float, v2: float) -> float: return v1 + v2,
	"SUBTRACT (-)": func(v1: float, v2: float) -> float: return v1 - v2,
	"MULTIPLY (*)": func(v1: float, v2: float) -> float: return v1 * v2,
	"DIVIDE (/)": func(v1: float, v2: float) -> float: return v1 / v2,
	"EXPONENTIAL (^)": func(v1: float, v2: float) -> float: return pow(v1, v2),
}

@export var variable_one: String:
	set(value):
		variable_one = value
		notify_property_list_changed()
@export var static_float_one: float
@export var operator: String
@export var variable_two: String:
	set(value):
		variable_two = value
		notify_property_list_changed()
@export var static_float_two: float


func _validate_property(property: Dictionary) -> void:
	if property.name == "variable_one" || property.name == "variable_two":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(PackedStringArray(_variables.keys()))
		return
	if property.name == "operator":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(PackedStringArray(_operators.keys()))
		return
	if property.name == "static_float_one":
		if variable_one != "Static Float":
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	if property.name == "static_float_two":
		if variable_two != "Static Float":
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return


func _modify(value: float, attribute: Attribute, active: ActiveAttributeEffect) -> float:
	assert(!operator.is_empty(), "operator is empty")
	assert(_operators.has(operator), "operator (%s) not found in available operators (%s)" \
	% [operator, _operators.keys()])
	assert(!variable_one.is_empty(), "variable_one is empty")
	assert(_variables.has(variable_one), "variable_one (%s) not found in available variables (%s)" \
	% [variable_one, _variables.keys()])
	assert(!variable_two.is_empty(), "variable_two is empty")
	assert(_variables.has(variable_two), "variable_two (%s) not found in available variables (%s)" \
	% [variable_two, _variables.keys()])
	
	var variable_one_value: float = _variables[variable_one].call(Args.new(static_float_one, 
	value, attribute, active))
	var variable_two_value: float = _variables[variable_two].call(Args.new(static_float_two, 
	value, attribute, active))
	
	return _operators[operator].call(variable_one_value, variable_two_value)


class Args extends RefCounted:
	var static_float: float
	var value: float
	var attribute: Attribute
	var active: ActiveAttributeEffect
	
	func _init(_static_float: float, _value: float, _attribute: Attribute, 
	_active: ActiveAttributeEffect) -> void:
		static_float = _static_float
		value = _value
		attribute = _attribute
		active = _active

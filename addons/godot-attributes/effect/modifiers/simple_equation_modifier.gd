## A flexible modifier that allows a customizable equation to be configured,
## with a set of parameters for that equation provided.
@tool
class_name SimpleEquationModifier extends AttributeEffectModifier

## Represents an accessible variable
enum Variable {
	## A static floating point value set in the editor inspector for this modifier.
	STATIC_FLOAT,
	## The [AttributeEffect]'s currently modified value. Accounts for other [AttributeEffectModifier]s
	## that have applied to the effect's value prior to this modifier.
	MODIFIED_EFFECT_VALUE,
	## The [AttributeEffect]'s raw value. Does NOT account for any other [AttributeEffectModifier]s
	## that have applied to the effect's value prior to this modifier.
	RAW_EFFECT_VALUE,
	## The current stack count of the [ActiveAttributeEffect].
	## See [method ActiveAttributeEffect.get_stack_count].
	ACTIVE_STACK_COUNT,
	## The number of times the [ActiveAttributeEffect] has been applied.
	## See [method ActiveAttributeEffect.get_apply_count].
	ACTIVE_APPLY_COUNT,
}

static var _variables: Dictionary[Variable, Callable] = {
	Variable.STATIC_FLOAT: func(args: Args) -> float: return args.static_float,
	Variable.MODIFIED_EFFECT_VALUE: func(args: Args) -> float: return args.value,
	Variable.RAW_EFFECT_VALUE: func(args: Args) -> float: return args.active.get_effect().value.get_raw(),
	Variable.ACTIVE_STACK_COUNT: func(args: Args) -> float: return args.active._stack_count,
}

## Determines the operator of [variable_one] and [variable_two]'s equation. 
enum Operator {
	## Add [member variable_two] to [member variable_one].
	ADD,
	## Subtract [member variable_two] from [member variable_one].
	SUBTRACT,
	## Multiply [member variable_one] by [member variable_two].
	MULTIPLY,
	## Divide [member variable_one] by [member variable_two].
	DIVIDE,
	## Raise [member variable_one] to the power of [member variable_two].
	EXPONENTIAL,
}

static var _operators: Dictionary[Operator, Callable] = {
	Operator.ADD: func(v1: float, v2: float) -> float: return v1 + v2,
	Operator.SUBTRACT: func(v1: float, v2: float) -> float: return v1 - v2,
	Operator.MULTIPLY: func(v1: float, v2: float) -> float: return v1 * v2,
	Operator.DIVIDE: func(v1: float, v2: float) -> float: return v1 / v2,
	Operator.EXPONENTIAL: func(v1: float, v2: float) -> float: return pow(v1, v2),
}

@export var variable_one: Variable:
	set(value):
		variable_one = value
		notify_property_list_changed()
@export var static_float_one: float
@export var operator: Operator
@export var variable_two: Variable:
	set(value):
		variable_two = value
		notify_property_list_changed()
@export var static_float_two: float


func _validate_property(property: Dictionary) -> void:
	if property.name == "static_float_one":
		if variable_one != Variable.STATIC_FLOAT:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	if property.name == "static_float_two":
		if variable_two != Variable.STATIC_FLOAT:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return


func _modify(value: float, attribute: Attribute, active: ActiveAttributeEffect) -> float:
	assert(_operators.has(operator), "operator (%s) not found in available operators (%s)" \
	% [operator, _operators.keys()])
	assert(_variables.has(variable_one), "variable_one (%s) not found in available variables (%s)" \
	% [variable_one, _variables.keys()])
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

## A flexible modifier that allows a customizable equation to be configured,
## with a set of parameters for that equation provided.
@tool
class_name SimpleEquationModifier extends AttributeEffectModifier

## Represents an accessible variable
enum Variable {
	## The [AttributeEffect]'s currently modified value. Accounts for other [AttributeEffectModifier]s
	## that have applied to the effect's value prior to this modifier.
	MODIFIED_EFFECT_VALUE = 0,
	## The [AttributeEffect]'s raw value. Does NOT account for any other [AttributeEffectModifier]s
	## that have applied to the effect's value prior to this modifier.
	RAW_EFFECT_VALUE = 1,
	## A fixed floating point value set in the editor inspector for this modifier.
	FIXED_FLOAT = 100,
	## The current stack count of the [ActiveAttributeEffect].
	## See [method ActiveAttributeEffect.get_stack_count].
	ACTIVES_STACK_COUNT = 200,
	## The number of times the [ActiveAttributeEffect] has been applied.
	## See [method ActiveAttributeEffect.get_apply_count].
	ACTIVES_APPLY_COUNT = 201,
	## The remaining duration of the [ActiveAttributeEffect].
	ACTIVES_REMAINING_DURATION = 202,
	## The remaining period of the [ActiveAttributeEffect].
	ACTIVES_REMAINING_PERIOD = 203,
	## The base value of the [Attribute]
	ATTRIBUTES_BASE_VALUE = 300,
	## The current value of the [Attribute]
	ATTRIBUTES_CURRENT_VALUE = 301,
}

static var _variable_getters: Dictionary[Variable, Callable] = {
	Variable.FIXED_FLOAT: func(args: Args) -> float: return args.fixed_float,
	Variable.MODIFIED_EFFECT_VALUE: func(args: Args) -> float: return args.value,
	Variable.RAW_EFFECT_VALUE: func(args: Args) -> float: return args.active.get_effect().value.get_raw(),
	Variable.ACTIVES_STACK_COUNT: func(args: Args) -> float: return args.active.get_stack_count(),
	Variable.ACTIVES_APPLY_COUNT: func(args: Args) -> float: return args.active.get_apply_count(),
	Variable.ACTIVES_REMAINING_DURATION: func(args: Args) -> float: return args.active.get_remaining_duration(),
	Variable.ACTIVES_REMAINING_PERIOD: func(args: Args) -> float: return args.active.get_remaining_period(),
	Variable.ATTRIBUTES_BASE_VALUE: func(args: Args) -> float: return args.attribute.get_base_value(),
	Variable.ATTRIBUTES_CURRENT_VALUE: func(args: Args) -> float: return args.attribute.get_current_value(),
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

static var _operator_calculators: Dictionary[Operator, Callable] = {
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
@export var fixed_float_one: float
@export var operator: Operator
@export var variable_two: Variable:
	set(value):
		variable_two = value
		notify_property_list_changed()
@export var fixed_float_two: float


func _validate_property(property: Dictionary) -> void:
	if property.name == "fixed_float_one":
		if variable_one != Variable.FIXED_FLOAT:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	if property.name == "fixed_float_two":
		if variable_two != Variable.FIXED_FLOAT:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return


func _modify(value: float, attribute: Attribute, active: ActiveAttributeEffect) -> float:
	assert(_operator_calculators.has(operator), "operator (%s) not found in _operator_calculators (%s)" \
	% [operator, _operator_calculators.keys()])
	assert(_variable_getters.has(variable_one), "variable_one (%s) not found in _variable_getters (%s)" \
	% [variable_one, _variable_getters.keys()])
	assert(_variable_getters.has(variable_two), "variable_two (%s) not found in _variable_getters (%s)" \
	% [variable_two, _variable_getters.keys()])
	
	var variable_one_value: float = _variable_getters[variable_one].call(Args.new(fixed_float_one, 
	value, attribute, active))
	var variable_two_value: float = _variable_getters[variable_two].call(Args.new(fixed_float_two, 
	value, attribute, active))
	
	return _operator_calculators[operator].call(variable_one_value, variable_two_value)


class Args extends RefCounted:
	var fixed_float: float
	var value: float
	var attribute: Attribute
	var active: ActiveAttributeEffect
	
	func _init(_fixed_float: float, _value: float, _attribute: Attribute, 
	_active: ActiveAttributeEffect) -> void:
		fixed_float = _fixed_float
		value = _value
		attribute = _attribute
		active = _active

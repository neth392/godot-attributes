extends GutTest

var modifier: SimpleEquationModifier

func before_all() -> void:
	modifier = SimpleEquationModifier.new()


func after_all() -> void:
	modifier = null


func test_variable_getter_exists_for_variable(param = 
use_parameters(SimpleEquationModifier.Variable.keys())) -> void:
	var variable_value: int = SimpleEquationModifier.Variable[param]
	assert_has(modifier._variable_getters, variable_value, "no getter found for variable %s" % param)


func test_operator_calculator_exists_for_variable(param = 
use_parameters(SimpleEquationModifier.Operator.keys())) -> void:
	var operator_value: int = SimpleEquationModifier.Operator[param]
	assert_has(modifier._operator_calculators, operator_value, "no calculator found for operator %s" % param)

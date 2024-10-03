## Modifies a value based on the current stack count of an [ActiveAttributeEffect].
@tool
class_name StackModifier extends AttributeEffectModifier

enum Mode {
	## Multiplies the value by the stack count
	MULTIPLY_BY_STACK,
	## Divides the value by the stack count
	DIVIDE_BY_STACK,
	## Raises the value to the power of the stack count.
	TO_POWER_OF_STACK,
}

## The [enum Mode] to be used.
@export var mode: Mode


func _modify(value: float, attribute: Attribute, active: ActiveAttributeEffect) -> float:
	assert(active._effect.stack_mode == AttributeEffect.StackMode.COMBINE,
	"stack_mode != COMBINE for active._effect: %s" % active._effect)
	
	return _calculate(value, active.get_stack_count())


func _calculate(value: float, stack_count: int) -> float:
	match mode:
		Mode.MULTIPLY_BY_STACK:
			return value * stack_count
		Mode.DIVIDE_BY_STACK:
			return value / stack_count
		Mode.TO_POWER_OF_STACK:
			return pow(value, stack_count)
		_:
			assert(false, "no logic written for mode: %s" % mode)
			return value

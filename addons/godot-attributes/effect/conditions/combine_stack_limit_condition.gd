## Condition that when used as an "add" condition, will block the stacking of active effects
## beyond a configured limit. For effects where [member AttributeEffect.stack_mode]
## is [enum AttributeEffect.StackMode.COMBINE].
class_name CombineStackLimitCondition extends AttributeEffectCondition

## The maximum stack count, inclusive.
@export var stack_limit: int

func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	return active.get_stack_count() < stack_limit

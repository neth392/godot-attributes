## Condition that has a single bool value which is the condition result.
## Not really useful except for in testing.
@tool
class_name StaticCondition extends AttributeEffectCondition

## The static value of this condition.
@export var static_value: bool


func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	return static_value

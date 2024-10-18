## Abstract class to check if an [Attribute] and [ActiveAttributeEffect] meets a condition 
## for the active to be applied.
## [br]Some useful considerations when designing your own conditions:
## [br] - [method ActiveAttributeEffect.get_pending_value] can be used to determine if
## the active should apply based on it's potential value. TODO FIX THIS NOTE
@tool
class_name AttributeEffectCondition extends Resource

## If true, emits a signal from an [Attribute] when this condition fails to be met
## when used as an add or block condition on an [AttributeEffect].
@export var emit_blocked_signal: bool = false

## If true, the condition result is negated.
@export var negate: bool = false

## An optional message explaining why this condition has blocked an [AttributeEffect]
## from being applied.
@export_multiline var message: String

## Tests that the [param attribute] & [param active] meets this condition.
## [br]WARNING: Do NOT override this or [member negate] will not apply.
func meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	var meets: bool = _meets_condition(attribute, active)
	if negate:
		return !meets
	return meets


## Returns true if the [param attribute] & [param active] meets the conditions. Should NOT
## modify or mutate either parameter.
## [br]NOTE: OVERRIDE THIS
func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	return true

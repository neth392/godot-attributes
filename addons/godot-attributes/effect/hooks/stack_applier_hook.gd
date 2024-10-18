## A hook which causes an [ActiveAttributeEffect] to apply when its stack
## count changes, configurable for different behaviors.
@tool
class_name StackApplierHook extends AttributeEffectHook

enum ApplyCountMode {
	FIXED_AMOUNT,
	
}

func _after_stack_changed(attribute: Attribute, active: ActiveAttributeEffect,
event: AttributeEvent, previous_stack_count: int) -> void:
	pass

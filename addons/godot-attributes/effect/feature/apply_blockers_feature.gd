@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"apply_blockers"


func _get_depends_on() -> Array[StringName]:
	return [&"apply_blocker"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	var array: Array[AttributeEffectCondition] = []
	if !effect.apply_blocker:
		array.make_read_only()
	return array


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.apply_blocker


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return effect.apply_blocker || value.is_empty()


func _before_value_set(value: Variant, effect: AttributeEffect) -> void:
	if !effect.apply_blocker:
		value.make_read_only()


func _get_requirements_string(value: Variant) -> String:
	if !value.is_empty():
		return "effect.apply_blocker == true"
	else:
		return NO_REQUIREMENTS

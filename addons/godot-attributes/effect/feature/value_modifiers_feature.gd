@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"value_modifiers"


func _get_depends_on() -> Array[StringName]:
	return [&"value_modifier"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return null if !effect.value_modifier else AttributeEffectModifierArray.new()


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.value_modifier


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return (value != null) == effect.value_modifier


func _get_requirements_string(value: Variant) -> String:
	if value != null:
		return "effect.value_modifier == true"
	else:
		return "effect.value_modifier == false"

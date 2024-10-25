@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"duration_modifiers"


func _get_depends_on() -> Array[StringName]:
	return [&"duration_modifier"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return null if !effect.duration_modifier else AttributeEffectModifierArray.new()


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.duration_modifier


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return (value != null) == effect.duration_modifier


func _get_requirements_string(value: Variant) -> String:
	if value != null:
		return "effect.duration_modifier == true"
	else:
		return "effect.duration_modifier == false"

@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"emit_added_signal"


func _get_default_value() -> Variant:
	return false


func _get_depends_on() -> Array[StringName]:
	return [&"duration_type"]


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.duration_type != AttributeEffect.DurationType.INSTANT


func _meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return !value || effect.duration_type != AttributeEffect.DurationType.INSTANT


func _get_requirements_string(value: Variant) -> String:
	return "duration_type != AttributeEffect.DurationType.INSTANT"

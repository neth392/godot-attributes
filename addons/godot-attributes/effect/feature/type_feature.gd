@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"type"


func _get_depends_on() -> Array[StringName]:
	return []


func _get_default_value(effect: AttributeEffect) -> Variant:
	return AttributeEffect.Type.TEMPORARY


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return true


func _get_requirements_string(value: Variant) -> String:
	return NO_REQUIREMENTS

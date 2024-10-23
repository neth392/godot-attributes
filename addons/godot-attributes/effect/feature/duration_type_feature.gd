@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"duration_type"


func _get_default_value() -> Variant:
	return AttributeEffect.DurationType.INFINITE


func _get_depends_on() -> Array[StringName]:
	return [&"type"]


func _override_hint_string(effect: AttributeEffect, hint_string: String) -> String:
	# Hide INSTANT in editor when not feasible
	if !_meets_requirements(AttributeEffect.DurationType.INSTANT, effect):
		return format_enum(AttributeEffect.DurationType, [AttributeEffect.DurationType.INSTANT])
	return hint_string


func _meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	assert(value is AttributeEffect.DurationType, "duration_type value must be " + \
	"of type AttributeEffect.DurationType")
	match value:
		AttributeEffect.DurationType.INSTANT:
			return effect.type == AttributeEffect.Type.PERMANENT
		_:
			return true


func _get_requirements_string(value: Variant) -> String:
	match value:
		AttributeEffect.DurationType.INSTANT:
			return "type == AttributeEffect.Type.PERMANENT"
		_:
			return NO_REQUIREMENTS

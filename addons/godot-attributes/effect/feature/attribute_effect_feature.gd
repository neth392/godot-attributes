## Represents a feature in an [AttributeEffect] of which certain requirements
## must be met to configure this feature.
@tool
class_name AttributeEffectFeature extends Object

const NO_REQUIREMENTS: String = "NO REQUIREMENTS"


## Helper method for _validate_property.
func format_enum(_enum: Dictionary, exclude: Array) -> String:
	var hint_string: Array[String] = []
	for name: String in _enum.keys():
		var value: int = _enum[name]
		if exclude.has(value):
			continue
		hint_string.append("%s:%s" % [name.to_camel_case().capitalize(), value])
	return ",".join(hint_string)


## Returns the property name in [AttributeEffect] this feature is related to.
func _get_property_name() -> StringName:
	assert(false, "_get_property_name not implemented")
	return &""


## Returns the default value when the feature can't be configured.
func _get_default_value() -> Variant:
	assert(false, "_get_requirements_string not implemented")
	return null


## Returns an array of property names of other features this feature depends on.
## For use in sorting the internal feature array.
func _get_depends_on() -> Array[StringName]:
	assert(false, "_get_depends_on not implemented")
	return []


## Returns whether or not to show this feature in the editor inspector. Optional,
## returns true by default.
func _show_in_editor(effect: AttributeEffect) -> bool:
	return true


## Allows overriding the property.hint_string in _validate_property. Optional.
func _override_hint_string(effect: AttributeEffect, hint_string: String) -> String:
	return hint_string


## Returns true if the [param effect]'s requirements are met for this feature to be
## configurable, false if not.
func _meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	assert(false, "_meets_requirements not implemented")
	return false


## Returns the requirements for this feature to be set to [param value].
func _get_requirements_string(value: Variant) -> String:
	assert(false, "_get_requirements_string not implemented")
	return ""

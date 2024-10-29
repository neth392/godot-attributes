## Represents a property ("feature") in [AttributeEffect]. Contains the logic for each individual
## property, separating it from the spaghetti mess that [AttributeEffect] once was.
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


## Returns an array of property names of other features this feature depends on.
## For use in sorting the internal feature array.
func _get_depends_on() -> Array[StringName]:
	assert(false, "_get_depends_on not implemented")
	return []


## Returns the default value when needed by the editor for an invalid value.
func _get_default_value(effect: AttributeEffect) -> Variant:
	assert(false, "_get_requirements_string not implemented")
	return null


## Returns whether or not to show this feature in the editor inspector. Optional,
## returns true by default.
func _show_in_editor(effect: AttributeEffect) -> bool:
	return true


## Returns whether or not to make this property read only in the editor inspector. Optional,
## retunrs false by default.
func _make_read_only(effect: AttributeEffect) -> bool:
	return false


## Allows overriding the property.hint_string in _validate_property. Optional,
## returns [param hint_string] by default.
func _override_hint_string(effect: AttributeEffect, hint_string: String) -> String:
	return hint_string


## Returns true if the [param value] meets the [param effect]'s requirements, false if not.
func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	assert(false, "_value_meets_requirements not implemented")
	return false


## Called when the [param value] is about to be set to the propery on [param effect].
## Optional, does nothing by default
func _before_value_set(value: Variant, effect: AttributeEffect) -> void:
	pass


## Returns the requirements for this feature to be set to [param value].
func _get_requirements_string(value: Variant) -> String:
	assert(false, "_get_requirements_string not implemented")
	return ""


func _to_string() -> String:
	return "AttributeEffectFeature(property_name=%s)" % _get_property_name()

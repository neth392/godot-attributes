# TODO Document
class_name AttributeIDCondition extends AttributeEffectCondition

enum Use {
	## Use the [Attribute]'s [member Attribute.id].
	ATTRIBUTE_ID,
	## Use the [AttributeContainer]'s [member AttributeContainer.id].
	ATTRIBUTE_CONTAINER_ID,
}

enum CompareMode {
	EQUALS,
	EQUALS_IGNORE_CASE,
	BEGINS_WITH,
	ENDS_WITH,
	CONTAINS,
}

## Determines which ID to use.
@export var use: Use
## The method of comparing the ID to [member value].
@export var mode: CompareMode
## The value to compare to, used by [param mode].
@export var value: String


func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	var id: String = _get_id(attribute)
	return _compare(id)


func _compare(id: String) -> bool:
	match mode:
		CompareMode.EQUALS:
			return id == value
		CompareMode.EQUALS_IGNORE_CASE:
			return id.to_lower() == value.to_lower()
		CompareMode.BEGINS_WITH:
			return id.begins_with(value)
		CompareMode.ENDS_WITH:
			return id.ends_with(value)
		CompareMode.CONTAINS:
			return id.contains(value)
		_:
			assert(false, "no implementation for mode %s" % mode)
			return false


func _get_id(attribute: Attribute) -> String:
	match use:
		Use.ATTRIBUTE_ID:
			return attribute.id
		Use.ATTRIBUTE_CONTAINER_ID:
			assert(attribute.get_container() != null, "%s's container is null" % attribute)
			return attribute.get_container().id
		_:
			assert(false, "no implementation for 'use' %s" % use)
			return ""

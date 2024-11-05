class_name WrappedAttributeEvent extends AttributeEvent

var _current_value_hit_minimum: bool = false

func _init(attribute: WrappedAttribute, active: ActiveAttributeEffect = null) -> void:
	super._init(attribute, active)


func get_attribute() -> WrappedAttribute:
	return _attribute


func is_current_value_hit_minimum_event() -> bool:
	return _current_value_hit_minimum

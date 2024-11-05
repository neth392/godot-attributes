class_name WrappedAttributeEvent extends AttributeEvent

var _base_hit_min: bool = false
var _base_hit_max: bool = false
var _current_hit_min: bool = false
var _current_hit_max: bool = false

func _init(attribute: WrappedAttribute, active: ActiveAttributeEffect = null) -> void:
	super._init(attribute, active)


func get_attribute() -> WrappedAttribute:
	return _attribute


func is_base_hit_min_event() -> bool:
	return _base_hit_min


func is_base_hit_max_event() -> bool:
	return _base_hit_max


func is_current_hit_min_event() -> bool:
	return _current_hit_min


func is_current_hit_max_event() -> bool:
	return _current_hit_max

class_name WrappedAttributeEvent extends AttributeEvent

var _base_hit_min: bool = false
var _base_min_changed: bool = false
var _has_prev_base_min: bool = false
var _has_new_base_min: bool = false
var _prev_base_min: float
var _new_base_min: float


func _init(attribute: WrappedAttribute, active: ActiveAttributeEffect = null) -> void:
	super._init(attribute, active)


func get_attribute() -> WrappedAttribute:
	return _attribute


## Returns true if this base value of the [WrappedAttribute] hit its minimum.
## Does not return true if the base value was already at or below the minimum.
func is_base_hit_min_event() -> bool:
	return _base_hit_min


## Returns true if the base mininum's value changed.
func is_base_min_changed_event() -> bool:
	return _base_min_changed

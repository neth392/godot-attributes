## An AttributeEvent extension which adds several more properties related to
## [WrappedAttribute] events.
class_name WrappedAttributeEvent extends AttributeEvent

var _base_hit_min: bool = false
var _base_left_min: bool = false
var _has_prev_base_min: bool = false
var _has_new_base_min: bool = false
var _prev_base_min: float
var _new_base_min: float

var _base_hit_max: bool = false
var _base_left_max: bool = false
var _has_prev_base_max: bool = false
var _has_new_base_max: bool = false
var _prev_base_max: float
var _new_base_max: float

var _current_hit_min: bool = false
var _current_left_min: bool = false
var _has_prev_current_min: bool = false
var _has_new_current_min: bool = false
var _prev_current_min: float
var _new_current_min: float

var _current_hit_max: bool = false
var _current_left_max: bool = false
var _has_prev_current_max: bool = false
var _has_new_current_max: bool = false
var _prev_current_max: float
var _new_current_max: float


func _init(attribute: WrappedAttribute, active: ActiveAttributeEffect = null) -> void:
	super._init(attribute, active)


func get_attribute() -> WrappedAttribute:
	return _attribute


##############
## Base Min ##
##############

## Returns true if the base value of the [WrappedAttribute] was previously greater
## than the minimum but is equal to the minimum.
func is_base_hit_min_event() -> bool:
	return _base_hit_min


## Returns true if the base value of the [WrappedAttribute] was previously equal to
## the minimum but is now greater than the minimum.
func is_base_left_min_event() -> bool:
	return _base_left_min


## Returns true if the base minimum's value changed.
func is_base_min_changed_event() -> bool:
	return _prev_base_min != _new_base_min


## Returns true if this is a base min change event (see [method is_base_min_changed_event])
## and there was a previous minimum set (non-null attribute or fixed value).
func has_prev_base_min() -> bool:
	return _has_prev_base_min


## Returns true if this is a base min change event (see [method is_base_min_changed_event])
## and the new minimum is a non-null [Attribute] or fixed value.
func has_new_base_min() -> bool:
	return _has_new_base_min


## Returns the previous base min value, or [constant WrappedAttribute.HARD_MIN] if one
## was not set (see [method has_prev_base_min]).
func get_prev_base_min() -> float:
	return _prev_base_min


## Returns the new base min value, or [constant WrappedAttribute.HARD_MIN] if the 
## minimum was removed (see [method has_new_base_min]).
func get_new_base_min() -> float:
	return _new_base_min


##############
## Base Max ##
##############

## Returns true if the base value of the [WrappedAttribute] was previously less
## than the maximum but is equal to the maximum.
func is_base_hit_max_event() -> bool:
	return _base_hit_max


## Returns true if the base value of the [WrappedAttribute] was previously equal to
## the maximum but is now less than the maximum.
func is_base_left_max_event() -> bool:
	return _base_left_max


## Returns true if the base maximum's value changed.
func is_base_max_changed_event() -> bool:
	return _prev_base_max != _new_base_max


## Returns true if this is a base max change event (see [method is_base_max_changed_event])
## and there was a previous maximum set (non-null attribute or fixed value).
func has_prev_base_max() -> bool:
	return _has_prev_base_max


## Returns true if this is a base max change event (see [method is_base_max_changed_event])
## and the new maximum is a non-null [Attribute] or fixed value.
func has_new_base_max() -> bool:
	return _has_new_base_max


## Returns the previous base max value, or [constant WrappedAttribute.HARD_MAX] if one
## was not set (see [method has_prev_base_max]).
func get_prev_base_max() -> float:
	return _prev_base_max


## Returns the new base max value, or [constant WrappedAttribute.HARD_MAX] if the 
## maximum was removed (see [method has_new_base_max]).
func get_new_base_max() -> float:
	return _new_base_max


#################
## Current Min ##
#################

## Returns true if the current value of the [WrappedAttribute] was previously greater
## than the minimum but is equal to the minimum.
func is_current_hit_min_event() -> bool:
	return _current_hit_min


## Returns true if the current value of the [WrappedAttribute] was previously equal to
## the minimum but is now greater than the minimum.
func is_current_left_min_event() -> bool:
	return _current_left_min


## Returns true if the current minimum's value changed.
func is_current_min_changed_event() -> bool:
	return _prev_current_min != _new_current_min


## Returns true if this is a current min change event (see [method is_current_min_changed_event])
## and there was a previous minimum set (non-null attribute or fixed value).
func has_prev_current_min() -> bool:
	return _has_prev_current_min


## Returns true if this is a current min change event (see [method is_current_min_changed_event])
## and the new minimum is a non-null [Attribute] or fixed value.
func has_new_current_min() -> bool:
	return _has_new_current_min


## Returns the previous current min value, or [constant WrappedAttribute.HARD_MIN] if one
## was not set (see [method has_prev_current_min]).
func get_prev_current_min() -> float:
	return _prev_current_min


## Returns the new current min value, or [constant WrappedAttribute.HARD_MIN] if the 
## minimum was removed (see [method has_new_current_min]).
func get_new_current_min() -> float:
	return _new_current_min


#################
## Current Max ##
#################

## Returns true if the current value of the [WrappedAttribute] was previously less
## than the maximum but is equal to the maximum.
func is_current_hit_max_event() -> bool:
	return _current_hit_max


## Returns true if the current value of the [WrappedAttribute] was previously equal to
## the maximum but is now less than the maximum.
func is_current_left_max_event() -> bool:
	return _current_left_max


## Returns true if the current maximum's value changed.
func is_current_max_changed_event() -> bool:
	return _prev_current_max != _new_current_max


## Returns true if this is a current max change event (see [method is_current_max_changed_event])
## and there was a previous maximum set (non-null attribute or fixed value).
func has_prev_current_max() -> bool:
	return _has_prev_current_max


## Returns true if this is a current max change event (see [method is_current_max_changed_event])
## and the new maximum is a non-null [Attribute] or fixed value.
func has_new_current_max() -> bool:
	return _has_new_current_max


## Returns the previous current max value, or [constant WrappedAttribute.HARD_MAX] if one
## was not set (see [method has_prev_current_max]).
func get_prev_current_max() -> float:
	return _prev_current_max


## Returns the new current max value, or [constant WrappedAttribute.HARD_MAX] if the 
## maximum was removed (see [method has_new_current_max]).
func get_new_current_max() -> float:
	return _new_current_max

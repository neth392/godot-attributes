class_name TestArray extends Resource

var array: Array 
var next: int = 0

func _init(_array: Array) -> void:
	array = _array


func _iter_init(iter: Array) -> bool:
	return false


func _iter_get(iter: Variant) -> Variant:
	return null


func _iter_next(iter: Array) -> bool:
	return false

extends Node



func _ready() -> void:
	var callable: Callable = func(variant = null):
		return
	print(callable.call())

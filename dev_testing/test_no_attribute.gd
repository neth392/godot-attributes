extends Node

func _ready() -> void:
	var boo: bool = true
	var str: Variant = Test.new() if !boo else "hi!"
	print(str)


class Test extends Object:
	
	func _init() -> void:
		print("INITIATED")

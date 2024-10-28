extends Node

func _ready() -> void:
	var test1: TestResource = load("res://dev_testing/test_resource.tres")
	test1.test5 = false
	print("next!")
	
	var test2: TestResource = TestResource.new()
	print("STOP")

extends Node



func _ready() -> void:
	var test: TestResource = load("res://tests/test_resource.tres") as TestResource
	test.string = "heyooo"
	print(test.string)

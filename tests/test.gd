extends Node



func _ready() -> void:
	var test_class: TestClass = TestClass.new()
	var iterations: int = 10_000_000
	PerformanceTest.test_performance("Direct Access", iterations, 
	func() -> void:
		test_class.str1
		test_class.str2
		test_class.str3
	)
	var str1: StringName = &"str1"
	var str2: StringName = &"str2"
	var str3: StringName = &"str3"
	PerformanceTest.test_performance("String Access", iterations, 
	func() -> void:
		test_class.get(str1)
		test_class.get(str2)
		test_class.get(str3)
	)


class TestClass extends Object:
	var str1: String = "Hi1!"
	var str2: String = "Hi2!"
	var str3: String = "Hi3!"

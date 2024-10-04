class_name PerformanceTest extends Object

static func test_performance(prefix: String, iterations: int, callable: Callable) -> void:
	var start_time: int = Time.get_ticks_usec()
	for i in iterations:
		callable.call()
	var end_time: int = Time.get_ticks_usec()
	print(prefix, float(end_time - start_time) / 1_000_000.0,"s")

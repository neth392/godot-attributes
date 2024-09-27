extends Node



func _ready() -> void:
	var iterations: int = 100_000
	var _array_one: Array = []
	var _array_two: Array = []
	for i in iterations:
		var array1: Array = []
		var array2: Array = []
		for ii in 100:
			array1.append(ii)
			array2.append(ii)
		_array_one.append(array1)
		_array_two.append(array2)
	
	var start_time1: float = Time.get_ticks_usec()
	for i in iterations:
		var array: Array
		array.erase()
		_array_one[i].erase(50)
	var end_time1: float = Time.get_ticks_usec()
	print("Erase: ", (end_time1 - start_time1) / 1_000_000.0)
	
	var start_time2: float = Time.get_ticks_usec()
	for i in iterations:
		_array_two[i].remove_at(51)
	var end_time2: float = Time.get_ticks_usec()
	print("remove at: ", (end_time2 - start_time2) / 1_000_000.0)

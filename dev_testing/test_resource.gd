class_name TestResource extends Resource

@export var test1: String = "hi!":
	set(value):
		test1 = value
		print("SET: test1, loading=%s" % _loading)
@export var test2: bool = false:
	set(value):
		test2 = value
		print("SET: test2, loading=%s" % _loading)
@export var test3: bool = false:
	set(value):
		test3 = value
		print("SET: test3, loading=%s" % _loading)
@export var test4: bool = false:
	set(value):
		test4 = value
		print("SET: test4, loading=%s" % _loading)
@export var test5: bool = false:
	set(value):
		test5 = value
		print("SET: test5, loading=%s" % _loading)
@export var test6: String = "trueHi":
	set(value):
		test6 = value
		print("SET: test6, loading=%s" % _loading)

@export_storage var _end_loading: bool = false:
	set(value):
		_loading = false

var _loading: bool = true:
	set(value):
		_loading = value
		if _loading:
			print("START LOADING")
		else:
			print("END LOADING")

func _init() -> void:
	_loading = true

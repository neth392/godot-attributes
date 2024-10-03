class_name TestResource extends Resource

@export var string: String = "hi!":
	set(value):
		if _block_modifications:
			print("MODIFICATIONS BLOCKED")
		else:
			string = value

@export_storage var _block_modifications: bool = false:
	set(value):
		print("set!")
		_block_modifications = !Engine.is_editor_hint()

func _notification(what: int) -> void:
	print(what)

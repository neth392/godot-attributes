extends AttributeDepdententTest


func test_ticks_to_second() -> void:
	assert_eq(5.0, Attribute._ticks_to_seconds(5_000_000), "_ticks_to_seconds calculation error")


func test_not_processing_with_no_effects() -> void:
	assert_false(attribute.is_processing(), "attribute is processing when it shouldn't be")


func test_not_physics_processing_with_no_effects() -> void:
	assert_false(attribute.is_physics_processing(), "attribute is physics processing when " + \
	"it shouldn't be")


func test_set_base_value() -> void:
	var new_base_value: float = 100.0
	attribute.set_base_value(new_base_value)

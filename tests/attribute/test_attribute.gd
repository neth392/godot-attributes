extends AttributeDepdententTest


func test_ticks_to_second() -> void:
	assert_eq(5.0, Attribute._ticks_to_seconds(5_000_000), "_ticks_to_seconds calculation error")


func test_not_processing_with_no_effects() -> void:
	assert_false(attribute.is_processing(), "attribute is processing when it shouldn't be")


func test_not_physics_processing_with_no_effects() -> void:
	assert_false(attribute.is_physics_processing(), "attribute is physics processing when " + \
	"it shouldn't be")


func test_set_base_value_equals_provided_param() -> void:
	var new_base_value: float = 100.0
	attribute.set_base_value(new_base_value)
	assert_eq(attribute.get_base_value(), new_base_value, "set_base_value did not update the value")


func test_set_base_value_does_not_emit_event_occurred_for_same_value() -> void:
	var new_base_value: float = attribute.get_base_value()
	attribute.set_base_value(new_base_value)
	assert_signal_not_emitted(attribute, "event_occurred", "event_occurred was emitted from " +\
	" set_base_value even though the new value was the same as the previous")


func test_set_base_value_emits_event_occurred_for_new_value() -> void:
	var new_base_value: float = 100.0
	attribute.set_base_value(new_base_value)
	assert_signal_emitted(attribute, "event_occurred", "event_occurred was not emitted from " +\
	"set_base_value with a new value")

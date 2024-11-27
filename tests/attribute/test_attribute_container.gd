extends AttributeDepdententTest

const TEST_TAGS: Array[StringName] = [&"test_tag_1", &"test_tag_2"]

func _init() -> void:
	super._init(InstanceMode.BEFORE_EACH, true, InstanceMode.NONE, false)


func test_id_changed_emitted_with_new_id() -> void:
	var new_container: AttributeContainer = AttributeContainer.new(CONTAINER_ID)
	watch_signals(new_container)
	new_container.id = CONTAINER_ID + "_new"
	assert_signal_emitted_with_parameters(new_container, "id_changed", [CONTAINER_ID])
	new_container.free()


func test_id_changed_not_emitted_with_same_id() -> void:
	var new_container: AttributeContainer = AttributeContainer.new(CONTAINER_ID)
	watch_signals(new_container)
	new_container.id = CONTAINER_ID
	assert_signal_not_emitted(new_container, "id_changed")
	new_container.free()


func test_add_tag_adds_to_internal_dictionary() -> void:
	container.add_tag(TEST_TAGS[0])
	assert_has(container._tags.keys(), TEST_TAGS[0])


func test_add_tag_emits_tag_added() -> void:
	container.add_tag(TEST_TAGS[0])
	assert_signal_emitted_with_parameters(container, "tag_added", [TEST_TAGS[0]])


func test_add_tag_returns_true_if_tag_added() -> void:
	assert_true(container.add_tag(TEST_TAGS[0]))


func test_add_tag_returns_false_if_tag_already_added() -> void:
	container.add_tag(TEST_TAGS[0])
	assert_false(container.add_tag(TEST_TAGS[0]))


func test_add_tags_calls_add_tag() -> void:
	container.add_tags(TEST_TAGS)
	assert_called(container, "add_tag", [TEST_TAGS[0]])
	assert_called(container, "add_tag", [TEST_TAGS[1]])


func test_add_tags_returns_true_if_new_tag_added() -> void:
	container.add_tag(TEST_TAGS[0])
	assert_true(container.add_tags(TEST_TAGS))


func test_add_tags_returns_false_if_tags_already_added() -> void:
	container.add_tags(TEST_TAGS)
	assert_false(container.add_tags(TEST_TAGS))


func test_default_tags_are_added_via_add_tag() -> void:
	var new_container: AttributeContainer = partial_double_container()
	new_container.default_tags = TEST_TAGS
	add_child_autoqfree(new_container)
	assert_called(new_container, "add_tag", [new_container.default_tags[0]])
	assert_called(new_container, "add_tag", [new_container.default_tags[1]])


func test_has_tag() -> void:
	container.add_tag(TEST_TAGS[0])
	assert_true(container.has_tag(TEST_TAGS[0]))
	assert_false(container.has_tag(TEST_TAGS[1]))

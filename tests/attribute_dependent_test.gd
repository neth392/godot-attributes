## GutTest implementation
class_name AttributeDepdententTest extends GutTest

const CONTAINER_ID: StringName = &"test_container"
const ATTRIBUTE_ID: StringName = &"test_attribute"

var container: AttributeContainer
var attribute: Attribute

func before_all() -> void:
	container = AttributeContainer.new(CONTAINER_ID)
	add_child(container)


func after_all() -> void:
	remove_child(container)
	container.free()
	container = null


func before_each() -> void:
	attribute = Attribute.new(ATTRIBUTE_ID)
	watch_signals(attribute)
	container.add_child(attribute)
	autoqfree(attribute)


func after_each() -> void:
	container.remove_child(attribute)

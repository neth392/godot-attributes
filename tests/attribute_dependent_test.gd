## GutTest implementation
class_name AttributeDepdententTest extends GutTest

const CONTAINER_ID: StringName = &"test_container"
const ATTRIBUTE_ID: StringName = &"test_attribute"

var container: AttributeContainer
var attribute: Attribute

func before_all() -> void:
	container = AttributeContainer.new(CONTAINER_ID)


func after_all() -> void:
	container.queue_free()
	container = null


func before_each() -> void:
	attribute = Attribute.new(ATTRIBUTE_ID)


func after_each() -> void:
	attribute.queue_free()
	attribute = null

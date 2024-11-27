class_name AttributeDepdententTest extends GutTest

## Used to determine when to create a new instance of one of the relevant nodes.
enum InstanceMode {
	NONE,
	## A new instance is created before each test.
	BEFORE_EACH,
	## A new instance is created before all tests & reused for each.
	BEFORE_ALL
}

const CONTAINER_ID: StringName = &"test_container"
const ATTRIBUTE_ID: StringName = &"test_attribute"

var container: AttributeContainer
var attribute: Attribute

var _container_instance_mode: InstanceMode
var _attribute_instance_mode: InstanceMode

func _init(container_instance: InstanceMode, attribute_instance: InstanceMode) -> void:
	_container_instance_mode = container_instance
	_attribute_instance_mode = attribute_instance


func before_all() -> void:
	if _container_instance_mode == InstanceMode.BEFORE_ALL:
		_create_container()
	if _attribute_instance_mode == InstanceMode.BEFORE_ALL:
		_create_attribute()


func before_each() -> void:
	if _container_instance_mode == InstanceMode.BEFORE_EACH:
		_create_container()
		autoqfree(container)
	if _attribute_instance_mode == InstanceMode.BEFORE_EACH:
		_create_attribute()
		autoqfree(attribute)


func after_all() -> void:
	if _attribute_instance_mode == InstanceMode.BEFORE_ALL:
		remove_child(attribute)
		attribute.free()
		attribute = null
	if _container_instance_mode == InstanceMode.BEFORE_ALL:
		remove_child(container)
		container.free()
		container = null


func _create_container() -> void:
	if container != null:
		remove_child(container)
		container.free()
	container = AttributeContainer.new(CONTAINER_ID)
	watch_signals(container)
	add_child(container)


func _create_attribute() -> void:
	if attribute != null:
		container.remove_child(attribute)
		attribute.free()
	attribute = Attribute.new(ATTRIBUTE_ID)
	watch_signals(attribute)
	container.add_child(attribute)

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
var _double_container: bool = false
var _attribute_instance_mode: InstanceMode
var _double_attribute: bool = false

func _init(container_instance: InstanceMode, double_container: bool, attribute_instance: InstanceMode,
double_attribute: bool) -> void:
	_container_instance_mode = container_instance
	_double_container = double_container
	_attribute_instance_mode = attribute_instance
	_double_attribute = double_attribute


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
	_destroy_attribute()
	_destroy_container()


func _create_container() -> void:
	_destroy_container()
	container = AttributeContainer.new(CONTAINER_ID) if !_double_container else partial_double_container()
	watch_signals(container)
	add_child(container)


func _create_attribute() -> void:
	_destroy_attribute()
	attribute = Attribute.new(ATTRIBUTE_ID) if !_double_attribute else partial_double_attribute()
	watch_signals(attribute)
	container.add_child(attribute)


func _destroy_container() -> void:
	if container != null:
		if container.is_inside_tree():
			remove_child(container)
		container.free()
		container = null


func _destroy_attribute() -> void:
	if attribute != null:
		if attribute.is_inside_tree():
			container.remove_child(attribute)
		attribute.free()
	attribute = null


func partial_double_container() -> AttributeContainer:
	return partial_double(AttributeContainer).new(CONTAINER_ID)


func partial_double_attribute() -> Attribute:
	return partial_double(Attribute).new(ATTRIBUTE_ID)

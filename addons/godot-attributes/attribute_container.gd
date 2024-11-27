## Container node for [Attribute]s allowing siblings to communicate with each other
## by searching this container for [member Attribute.id].
@tool
@icon("res://addons/godot-attributes/assets/attribute_container_icon.svg")
class_name AttributeContainer extends Node

## Emitted when [member id] changes.
signal id_changed(prev_id: StringName)

## Emitted when the [param attribute] is added to this container.
signal attribute_added(attribute: Attribute)

## Emitted when the [param attriubte] is removed from this container.
signal attribute_removed(attribute: Attribute)

## Emitted when [param tag] is added to this container.
signal tag_added(tag: StringName)

## Emitted when [param tag] is removed from this container.
signal tag_removed(tag: StringName)

## The ID of this container. Should not be changed at runtime.
@export var id: StringName:
	set(value):
		assert(!is_node_ready(), "can not change id at runtime")
		var prev_id: StringName = id
		id = value
		if id != prev_id:
			id_changed.emit(prev_id)

## Tags to be added to the internal _tags [Dictionary] in _ready.
@export var default_tags: Array[StringName]

var _attributes: Dictionary[StringName, WeakRef] = {}
var _tags: Dictionary[StringName, Variant] = {}


## Constructs a new instance with [member id] as [param _id].
func _init(_id: StringName = &"") -> void:
	id = _id


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exited_tree)


func _ready() -> void:
	for tag: String in default_tags:
		add_tag(StringName(tag))


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	child_entered_tree.disconnect(_on_child_entered_tree)
	child_exiting_tree.disconnect(_on_child_exited_tree)
	_attributes.clear()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	
	var ids: PackedStringArray = PackedStringArray()
	
	for child: Node in get_children():
		if child is Attribute:
			if child.id.is_empty():
				warnings.append("Child (%s) has no ID set" % child.name)
				continue
			if ids.has(child.id):
				warnings.append("Attributes with duplicate ids found (%s)" % child.id)
			else:
				ids.append(child.id)
		else:
			warnings.append("child (%s) not of type Attribute" % child.name)
	
	if ids.is_empty():
		warnings.append("No valid Attribute children found")
	
	return warnings


## Adds the [param tag], returning true if added, false if not as it already existed.
func add_tag(tag: StringName) -> bool:
	if !has_tag(tag):
		_tags[tag] = null
		tag_added.emit(tag)
		return true
	return false


## Adds all of the [param tags] which are not yet added, returning true if one or
## more tags were added, false if none were added as they already existed.
func add_tags(tags: Array[StringName]) -> bool:
	assert(!tags.has(""), "tags has empty element")
	var added: bool = false
	for tag in tags:
		added = add_tag(tag) || added
	return added


## Returns true if the [param] tag exists on this container, false if not.
func has_tag(tag: StringName) -> bool:
	return _tags.has(tag)


## Removes the [param tag], retunrs true if it existed & was removed, false if not.
func remove_tag(tag: StringName) -> bool:
	if _tags.erase(tag):
		tag_removed.emit(tag)
		return true
	return false


## Removes all of the [param tags] that are present.
func remove_tags(tags: Array[StringName]) -> bool:
	var removed: bool = false
	for tag in tags:
		removed = remove_tag(tag) || removed
	return removed


func has_attribute_id(id: StringName) -> void:
	return _attributes.has(id)


## Returns the [Attribute] with the specified [member id].
func get_attribute(id: StringName) -> Attribute:
	return _attributes.get(id).get_ref()


func _on_child_entered_tree(child: Node) -> void:
	if child is Attribute:
		assert(!child.id.is_empty(), "child (%s)'s id is empty" % child.name)
		assert(!_attributes.has(child.id), "duplicate Attribute ids found (%s)" % child.id)
		_attributes[child.id] = weakref(child)
		AttributeUtil.connect_safely(child.id_changed, _on_attribute_id_changed)
		attribute_added.emit(child)


func _on_child_exited_tree(child: Node) -> void:
	if !is_inside_tree():
		return
	if child is Attribute:
		AttributeUtil.disconnect_safely(child.id_changed, _on_attribute_id_changed)
		_attributes.erase(child.id)
		attribute_removed.emit(child)


func _on_attribute_id_changed(prev_id: StringName) -> void:
	var attribute_ref: WeakRef = _attributes[prev_id]
	var attribute: Attribute = attribute_ref.get_ref() as Attribute
	if attribute == null:
		_attributes.erase(prev_id)
		return
	assert(!_attributes.has(attribute.id), ("a child Attribute's id changed from '%s' to '%s'" + \
	"but another child Attribute with new id '%s' already exists") \
	% [prev_id, attribute.id, attribute.id])
	_attributes.erase(prev_id)
	_attributes[attribute.id] = weakref(attribute)

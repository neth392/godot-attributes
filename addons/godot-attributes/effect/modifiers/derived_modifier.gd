## Overrides an [AttributeEffect]'s value with the value of another, distant [Attribute].
@tool
class_name DerivedModifier extends AttributeEffectModifier

const _META_KEY: StringName = &"DerivedModifierCache"

## How to handle situations where the [Attribute] being derived from is missing &
## not found in the scene tree. For example, that [Attribute]'s owner could've been
## queue_free'd.
enum IfAttributeMissing {
	## The last successfully retrieved value from the [Attribute] is always cached
	## (in the [ActiveAttributeEffect]'s meta) and used if the attribute becomes
	## inaccessible. Recommended for most cases.
	CACHE_FIRST_VALUE,
	## An error will be thrown via [method assert] in DEBUG MODE ONLY.
	THROW_ERROR_DEBUG_ONLY,
	## This modifier will be skipped.
	SKIP,
}

## The value of the [Attribute] to use, either base value or current value.
@export var value_to_use: Attribute.Value

## The [member Attribute.id] of the [Attribute] to use. Any [Attribute] passed to
## [method populate] with this ID will be accepted as long as the [member context]
## matches the context parameter of that method. 
@export var attribute_id: StringName

## An optional context for use in [method populate] to allow more fine-grain population
## of the [Attribute] whose value this modifier is derived from. One example is you may have several
## [Attribute]s with the same ID, say "Health", and several [DerivedModifier]s on one [AttributeEffect]
## which derive from different Attribute instances but both with the "Health" id. For one modifier,
## this context could be "enemy1", and another could be "enemy2". Then when you call [method populate]
## with each attribute, the differing context will ensure the correct [DerivedModifier] is populated.
@export var context: String

## How to handle not being able to locate the [Attribute] the value is derived from.
@export var if_attribute_missing: IfAttributeMissing

@export_storage var _attribute_path: NodePath

var _attribute_ref: WeakRef = weakref(null)

## Populates the internal [Attribute] reference with [param attribute] so its value can be derived
## when needed. Will only work if the [member Attribute.id] matches [member id], otherwise
## nothing happens.
## [br][param _context] is an optional parameter which must match [member context] in order
## for the population to be successful. If it does not match, nothing happens.
func populate(attribute: Attribute, _context: String = "") -> void:
	assert(attribute != null, "attribute is null")
	if context == _context && attribute_id == attribute.id:
		_attribute_path = attribute.get_path()
		_attribute_ref = weakref(attribute)


## Returns true if the necessary information to derive a value from the [Attribute]
## is populated, false if not.
func is_populated() -> bool:
	return !_attribute_path.is_empty()


func _modify(value: float, attribute: Attribute, active: ActiveAttributeEffect) -> float:
	assert(is_populated(), "no attribute was populated to this modifier for attribute_id=%s, context=%s" \
	% [attribute_id, context])
	var derived_from: Attribute = get_derived_from(attribute)
	if derived_from != null:
		if if_attribute_missing == IfAttributeMissing.CACHE_FIRST_VALUE:
			var attribute_value: float = get_attribute_value(derived_from)
			active.meta[_META_KEY] = attribute_value
			return attribute_value
		
		return get_attribute_value(derived_from)
	
	match if_attribute_missing:
		IfAttributeMissing.CACHE_FIRST_VALUE:
			assert(active.meta.has(_META_KEY), "meta key (%s) not present in %s's meta" \
			% [_META_KEY, active])
			return active.meta[_META_KEY]
		IfAttributeMissing.SKIP:
			return value
		IfAttributeMissing.THROW_ERROR_DEBUG_ONLY:
			assert(false, "attribute node @ path (%s) no longer findable" % _attribute_path)
			return value
		_:
			assert(false, "no implementation for if_attribute_missing %s" % if_attribute_missing)
			return value


func get_derived_from(node: Node) -> Attribute:
	if _attribute_ref.get_ref() != null:
		return _attribute_ref.get_ref() as Attribute
	
	var attribute: Node = node.get_node(_attribute_path)
	if attribute == null:
		return null
	assert(attribute is Attribute, "node @ _attribute_path (%s) not of type Attribute" % _attribute_path)
	_attribute_ref = weakref(attribute)
	return attribute as Attribute


func get_attribute_value(attribute: Attribute) -> float:
	match value_to_use:
		Attribute.Value.BASE_VALUE:
			return attribute.get_base_value()
		Attribute.Value.CURRENT_VALUE:
			return attribute.get_current_value()
		_:
			assert(false, "no implementation written for value_to_use %s" % value_to_use)
			return 0.0

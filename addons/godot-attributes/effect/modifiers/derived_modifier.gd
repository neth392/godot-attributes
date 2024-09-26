## Overrides an [AttributeEffect]'s value with the value of an [Attribute]. Internally,
## it uses a [NodePath] to locate the [Attribute]. So ensure your [NodePath]s remain constant
## across saving & loading.
class_name DerivedModifier extends AttributeEffectModifier


## Constructs a new [DerivedMofifier] instance from the [param attribute] and
## [param _value_to_use].
static func from_attribute(attribute: Attribute, 
_value_to_use: Attribute.Value = Attribute.Value.CURRENT_VALUE) -> DerivedModifier:
	assert(attribute != null, "attribute is null")
	var modifier: DerivedModifier = DerivedModifier.new()
	modifier.attribute_path = attribute.get_path()
	modifier.value_to_use = _value_to_use
	return modifier


## Constructs a new [DerivedMofifier] instance from the [param _attribute_path] and
## [param _value_to_use].
static func from_attribute_path(_attribute_path: NodePath, 
_value_to_use: Attribute.Value = Attribute.Value.CURRENT_VALUE) -> DerivedModifier:
	assert(!_attribute_path.is_empty(), "_attribute_path is empty")
	assert(_attribute_path.is_absolute(), "_attribute_path(%s) not absolute" % _attribute_path)
	var modifier: DerivedModifier = DerivedModifier.new()
	modifier.attribute_path = _attribute_path
	modifier.value_to_use = _value_to_use
	return modifier


## The path to the [Attribute] to derive from. Must be absolute (can not be relative).
@export_node_path("Attribute") var attribute_path: NodePath:
	set(value):
		assert(value.is_empty() || value.is_absolute(), "attribute_path(%s) is not absolute" % value)
		attribute_path = value

## The value to use of the [Attribute].
@export var value_to_use: Attribute.Value

# Internal cache of the [Attribute] instance.
var _cache: WeakRef


func _modify(value: float, attribute: Attribute, active: ActiveAttributeEffect) -> float:
	var derived_from: Attribute = get_derived_from(attribute)
	assert(derived_from != null, "could not find attribute @ node path (%s)" % attribute_path) 
	match value_to_use:
		Attribute.Value.CURRENT_VALUE:
			return derived_from.get_current_value()
		Attribute.Value.BASE_VALUE:
			return derived_from.get_base_value()
		_:
			assert(false, "no implementation for Attribute.Value(value_to_use)=%s" % value_to_use)
			return 0


func get_derived_from(source_node: Node) -> Attribute:
	var derived_from: Attribute = _cache.get_ref()
	if derived_from != null:
		assert(derived_from is Attribute, "Node @ attribute_path (%s) is not of type Attribute" \
		% attribute_path)
		return derived_from
	derived_from = source_node.get_node(attribute_path) as Attribute
	assert(derived_from != null, "no Attribute @ attribute_path (%s)" % attribute_path)
	_cache = weakref(derived_from)
	return derived_from

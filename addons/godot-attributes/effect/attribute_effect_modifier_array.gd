## Wrapper of an [Array] of [AttributeEffectModifier]s that ensures they are always
## properly sorted by [member AttributeEffectModifier.priority]. It is cumbersome
## in the inspector, but worth it for the less complex code.
class_name AttributeEffectModifierArray extends Resource

## For use in [method Array.sort_custom], returns a bool so that the modifier with
## the greater priority is in front of the other in the array (descending order)
static func _sort_a_before_b(a: AttributeEffectModifier, b: AttributeEffectModifier) -> bool:
	return a.priority > b.priority


## The [AttributeEffectModifier]s of this instance.
@export var _modifiers: Array[AttributeEffectModifier]:
	set(value):
		if !Engine.is_editor_hint():
			assert(!_modifiers.has(null), "_modifiers has null element")
			value.sort_custom(_sort_a_before_b)
			
			# Add to derived modifiers
			_derived_modifiers.clear()
			for modifier: AttributeEffectModifier in value:
				if modifier is DerivedModifier:
					_derived_modifiers.append(modifier)
		
		_modifiers = value

# Internal array of [DerivedMofifier]s to allow quicker population of the necessary
# fields. Order does not matter, and won't be stored as its auto populated by _modifiers.
var _derived_modifiers: Array[DerivedModifier]

## Returns true if the [param modifier] exists, false if not.
func has(modifier: AttributeEffectModifier) -> bool:
	return _modifiers.has(modifier)


## Adds the [param modifier], returning true if added, false if 
## [member AttributeEffectModifier.duplicate_instances] is true & another instance
## existed already.
func add(modifier: AttributeEffectModifier) -> bool:
	assert(modifier != null, "modifier is null")
	if !modifier.duplicate_instances && _modifiers.has(modifier):
		return false
	
	var index: int = 0
	for other_modifier: AttributeEffectModifier in _modifiers:
		if _sort_a_before_b(modifier, other_modifier):
			_modifiers.insert(index, modifier)
			break
		index += 1
	if index == _modifiers.size(): # Wasn't added in loop, append it to back
		_modifiers.append(modifier)
	
	# Add to derived modifiers
	if modifier is DerivedModifier:
		_derived_modifiers.append(modifier)
	
	return true


## Removes all instances of the [param modifier].
func remove(modifier: AttributeEffectModifier) -> void:
		while _modifiers.has(modifier):
			_modifiers.erase(modifier)
		# Remove from derived modifiers
		if modifier is DerivedModifier:
			_derived_modifiers.erase(modifier)


## Removes the first instance of [param modifier].
func remove_first(modifier: AttributeEffectModifier) -> void:
	_modifiers.erase(modifier)
	# Remove from derived modifiers if no longer in _modifiers
	if modifier is DerivedModifier && !_modifiers.has(modifier):
		_derived_modifiers.erase(modifier)


## Modifies the [param value] by applying the [member _modifiers] to it. [param attribute]
## and [param active] are the context.
func modify_value(value: float, attribute: Attribute, active: ActiveAttributeEffect) -> float:
	var modified_value: float = value
	for modifier: AttributeEffectModifier in _modifiers:
		if !modifier.should_modify(attribute, active):
			continue
		modified_value = modifier._modify(modified_value, attribute, active)
		if modifier.stop_processing_modifiers:
			return modified_value
	return modified_value


## Returns true if there are any instances of a [DerivedModifier] in this array.
func has_derived() -> bool:
	return !_derived_modifiers.is_empty()


## Populates all [DerivedModifier]s (if any exist) with the [param attribute].
## See [method DerivedModifier.populate] for more information.
func populate_derived(attribute: Attribute, context: String = "") -> void:
	for derived_modifier: DerivedModifier in _derived_modifiers:
		derived_modifier.populate(attribute, context)


## Returns true if all [DerivedModifier]s are populated, false if not.
func is_all_derived_populated() -> bool:
	for derived_modifier: DerivedModifier in _derived_modifiers:
		if !derived_modifier.is_populated():
			return false
	return true

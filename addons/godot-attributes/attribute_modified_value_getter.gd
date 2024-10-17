## Utility class used to get the modified value, period, and duration of
## an [ActiveAttriubteEffect]. The logic for all of those is the same but
## there are a few different paramters, so I've abstracted it out here to maintain
## that core logic.
class_name AttributeModifiedValueGetter extends Object

static var _value: AttributeModifiedValueGetter = Value.new()
static var _period: AttributeModifiedValueGetter = Period.new()
static var _duration: AttributeModifiedValueGetter = Duration.new()

static func value() -> AttributeModifiedValueGetter:
	return _value


static func period() -> AttributeModifiedValueGetter:
	return _period


static func duration() -> AttributeModifiedValueGetter:
	return _duration


func get_modified(attribute: Attribute, active: ActiveAttributeEffect) -> float:
	var modified_value: AttributeUtil.Reference = AttributeUtil.Reference.new(\
	_get_modifiable_value(active.get_effect()).get_modified(attribute, active))
	
	_get_modifier_actives(attribute._actives).for_each(
		func(modifier: ActiveAttributeEffect) -> void:
			if modifier.is_added() && !modifier.is_expired():
				modified_value.ref = _get_modifiers(modifier.get_effect())\
				.modify_value(modified_value.ref, attribute, active)
	, false) # Unsafe iteration as mutations won't be made during it.
	
	return modified_value.ref


func _get_modifiable_value(effect: AttributeEffect) -> ModifiableValue:
	assert(false, "_get_modifiable_value not implemented")
	return null


func _get_modifier_actives(cluster: ActiveAttributeEffectCluster) -> ActiveAttributeEffectArray:
	assert(false, "_get_modifier_actives not implemented")
	return null


func _get_modifiers(effect: AttributeEffect) -> AttributeEffectModifierArray:
	assert(false, "_get_modifiers not implemented")
	return null


class Value extends AttributeModifiedValueGetter:
	
	func _get_modifiable_value(effect: AttributeEffect) -> ModifiableValue:
		return effect.value
	
	func _get_modifier_actives(cluster: ActiveAttributeEffectCluster) -> ActiveAttributeEffectArray:
		return cluster.value_modifiers
	
	func _get_modifiers(effect: AttributeEffect) -> AttributeEffectModifierArray:
		return effect.value_modifiers


class Period extends AttributeModifiedValueGetter:
	
	func _get_modifiable_value(effect: AttributeEffect) -> ModifiableValue:
		return effect.period_in_seconds
	
	func _get_modifier_actives(cluster: ActiveAttributeEffectCluster) -> ActiveAttributeEffectArray:
		return cluster.period_modifiers
	
	func _get_modifiers(effect: AttributeEffect) -> AttributeEffectModifierArray:
		return effect.period_modifiers


class Duration extends AttributeModifiedValueGetter:
	
	func _get_modifiable_value(effect: AttributeEffect) -> ModifiableValue:
		return effect.duration_in_seconds
	
	func _get_modifier_actives(cluster: ActiveAttributeEffectCluster) -> ActiveAttributeEffectArray:
		return cluster.duration_modifiers
	
	func _get_modifiers(effect: AttributeEffect) -> AttributeEffectModifierArray:
		return effect.duration_in_seconds

## Manages all [AttributeEffectFeature]s, providing the interface to interact with them across
## the project.
@tool
class_name AttributeEffectFeatureManager extends Object

static var _features: Array[AttributeEffectFeature]
static var _features_by_property: Dictionary[StringName, AttributeEffectFeature]

static func _init() -> void:
	_features.append(preload("./add_blocker_feature.gd").new())
	_features.append(preload("./add_blockers_feature.gd").new())
	_features.append(preload("./add_conditions_feature.gd").new())
	_features.append(preload("./apply_blocker_feature.gd").new())
	_features.append(preload("./apply_blockers_feature.gd").new())
	_features.append(preload("./apply_conditions_feature.gd").new())
	_features.append(preload("./apply_limit_amount_feature.gd").new())
	_features.append(preload("./apply_limit_feature.gd").new())
	_features.append(preload("./apply_on_expire_feature.gd").new())
	_features.append(preload("./apply_on_expire_if_period_is_zero_feature.gd").new())
	_features.append(preload("./count_apply_if_blocked_feature.gd").new())
	_features.append(preload("./duration_feature.gd").new())
	_features.append(preload("./duration_modifiers_feature.gd").new())
	_features.append(preload("./duration_modifier_feature.gd").new())
	_features.append(preload("./duration_type_feature.gd").new())
	_features.append(preload("./emit_added_signal_feature.gd").new())
	_features.append(preload("./emit_applied_signal_feature.gd").new())
	_features.append(preload("./emit_removed_signal_feature.gd").new())
	_features.append(preload("./has_value_feature.gd").new())
	_features.append(preload("./initial_period_feature.gd").new())
	_features.append(preload("./period_feature.gd").new())
	_features.append(preload("./period_modifiers_feature.gd").new())
	_features.append(preload("./period_modifier_feature.gd").new())
	_features.append(preload("./stack_mode_feature.gd").new())
	_features.append(preload("./type_feature.gd").new())
	_features.append(preload("./value_calculator_feature.gd").new())
	_features.append(preload("./value_feature.gd").new())
	_features.append(preload("./value_modifiers_feature.gd").new())
	_features.append(preload("./value_modifier_feature.gd").new())
	
	# Add to dictionary for quicker lookups later
	for feature: AttributeEffectFeature in _features:
		_features_by_property[feature._get_property_name()] = feature
	
	# Assert no circular dependencies & that all dependencies exist
	if OS.is_debug_build():
		for featureA: AttributeEffectFeature in _features:
			for depends_on: StringName in featureA._get_depends_on():
				assert(_features_by_property.has(depends_on), "feature %s's dependency %s is missing" \
				% [featureA._get_property_name(), depends_on])
				
				var featureB: AttributeEffectFeature = _features_by_property[depends_on]
				
				assert(!featureB._get_depends_on().has(featureA._get_property_name()),
				"circular dependencies detected between features %s & %s" \
				% [featureA._get_property_name(), featureB._get_property_name()])
	
	# Sort by dependencies
	_features.sort_custom(func(a: AttributeEffectFeature, b: AttributeEffectFeature) -> bool:
		# A goes before B if B depends on A
		return b._get_depends_on().has(a._get_property_name())
	)


## Validates the property (same as [method _validate_property]) but must be manually called
## by other [method _validate_property] implementations.
static func validate_property(effect: AttributeEffect, property: Dictionary) -> void:
	assert(_features_by_property.has(property.name), ("property (%s) not found in " + \
	"_features_by_property") % property.name)
	var feature: AttributeEffectFeature = _features_by_property[property.name]
	
	# Editor visibility
	if !feature._show_in_editor(effect):
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif feature._make_read_only(effect):
		property.usage |= PROPERTY_USAGE_READ_ONLY
	
	# Hint String
	property.hint_string = feature._override_hint_string(effect, property.hint_string)


static func validate_user_set_value(effect: AttributeEffect, property_name: StringName, value: Variant) -> bool:
	assert(_features.has(property_name), "no feature found for property_name %s" % property_name)
	# TODO is this needed in the editor?
	
	var feature: AttributeEffectFeature = _features_by_property[property_name]
	
	if !feature._value_meets_requirements(value, effect):
		var requirements: String = feature._get_requirements_string(value)
		push_warning(("AttributeEffect(id=%s) does not meet the requirements to set property (%s) " + \
		"to value (%s), property will not be set. Requirements: %s") \
		% [effect.id, property_name, value, requirements])
		return false
	
	return true


static func notify_value_changed(effect: AttributeEffect, property_name: StringName) -> void:
	pass

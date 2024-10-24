## Manages all [AttributeEffectFeature]s, providing the interface to interact with them across
## the project.
@tool
class_name AttributeEffectFeatureManager extends Object

static var _features: Array[AttributeEffectFeature]
static var _features_by_property: Dictionary[StringName, AttributeEffectFeature]

static func _init() -> void:
	# Load features
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

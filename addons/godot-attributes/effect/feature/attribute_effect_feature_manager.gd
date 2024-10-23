class_name AttributeEffectFeatureManager extends Object

static var _features: Array[AttributeEffectFeature]
static var _features_by_property: Dictionary[StringName, AttributeEffectFeature]

static func _init() -> void:
	# Load features
	_features.append(preload("./duration_type_feature.gd").new())
	_features.append(preload("./emit_added_signal_feature.gd").new())
	_features.append(preload("./emit_applied_signal_feature.gd").new())
	_features.append(preload("./emit_removed_signal_feature.gd").new())
	_features.append(preload("./type_feature.gd").new())
	
	# Sort by dependencies
	_features.sort_custom(func(a: AttributeEffectFeature, b: AttributeEffectFeature) -> bool:
		# A goes before B if B depends on A
		return b._get_depends_on().has(a._get_property_name())
	)
	
	# Add to dictionary for quicker lookups later
	for feature: AttributeEffectFeature in _features:
		_features_by_property[feature._get_property_name()] = feature

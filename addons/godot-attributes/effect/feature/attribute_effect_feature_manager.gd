## Manages all [AttributeEffectFeature]s, providing the interface to interact with them across
## the project.
@tool
class_name AttributeEffectFeatureManager extends Object

static var _instance: AttributeEffectFeatureManager

## Returns the singleton instance of [AttributeEffectFeatureManager]
static func i() -> AttributeEffectFeatureManager:
	if _instance == null:
		_instance = AttributeEffectFeatureManager.new()
	return _instance

var _features_by_property: Dictionary[StringName, AttributeEffectFeature]
var _depended_on_by: Dictionary[StringName, Array]

func _init() -> void:
	var _loaded_features: Array[AttributeEffectFeature] = []
	_loaded_features.append(preload("./add_blocker_feature.gd").new())
	_loaded_features.append(preload("./add_blockers_feature.gd").new())
	_loaded_features.append(preload("./add_conditions_feature.gd").new())
	_loaded_features.append(preload("./apply_blocker_feature.gd").new())
	_loaded_features.append(preload("./apply_blockers_feature.gd").new())
	_loaded_features.append(preload("./apply_conditions_feature.gd").new())
	_loaded_features.append(preload("./apply_limit_amount_feature.gd").new())
	_loaded_features.append(preload("./apply_limit_feature.gd").new())
	_loaded_features.append(preload("./apply_on_expire_feature.gd").new())
	_loaded_features.append(preload("./apply_on_expire_if_period_is_zero_feature.gd").new())
	_loaded_features.append(preload("./count_apply_if_blocked_feature.gd").new())
	_loaded_features.append(preload("./duration_feature.gd").new())
	_loaded_features.append(preload("./duration_modifiers_feature.gd").new())
	_loaded_features.append(preload("./duration_modifier_feature.gd").new())
	_loaded_features.append(preload("./duration_type_feature.gd").new())
	_loaded_features.append(preload("./emit_added_signal_feature.gd").new())
	_loaded_features.append(preload("./emit_applied_signal_feature.gd").new())
	_loaded_features.append(preload("./emit_removed_signal_feature.gd").new())
	_loaded_features.append(preload("./has_add_conditions_feature.gd").new())
	_loaded_features.append(preload("./has_apply_conditions_feature.gd").new())
	_loaded_features.append(preload("./has_value_feature.gd").new())
	_loaded_features.append(preload("./initial_period_feature.gd").new())
	_loaded_features.append(preload("./irremovable_feature.gd").new())
	_loaded_features.append(preload("./period_feature.gd").new())
	_loaded_features.append(preload("./period_modifiers_feature.gd").new())
	_loaded_features.append(preload("./period_modifier_feature.gd").new())
	_loaded_features.append(preload("./stack_mode_feature.gd").new())
	_loaded_features.append(preload("./type_feature.gd").new())
	_loaded_features.append(preload("./value_calculator_feature.gd").new())
	_loaded_features.append(preload("./value_feature.gd").new())
	_loaded_features.append(preload("./value_modifiers_feature.gd").new())
	_loaded_features.append(preload("./value_modifier_feature.gd").new())
	
	# Add to dictionary for quicker lookups later
	for feature: AttributeEffectFeature in _loaded_features:
		_features_by_property[feature._get_property_name()] = feature
	
	# Assert no circular dependencies & that all dependencies exist
	if OS.is_debug_build():
		for featureA: AttributeEffectFeature in _loaded_features:
			for depends_on: StringName in featureA._get_depends_on():
				assert(_features_by_property.has(depends_on), "feature %s's dependency %s is missing" \
				% [featureA._get_property_name(), depends_on])
				
				var featureB: AttributeEffectFeature = _features_by_property[depends_on]
				
				assert(!featureB._get_depends_on().has(featureA._get_property_name()),
				"circular dependencies detected between features %s & %s" \
				% [featureA._get_property_name(), featureB._get_property_name()])
	
	# Add to depend on by
	for feature: AttributeEffectFeature in _loaded_features:
		for depends_on_name: StringName in feature._get_depends_on():
			var depends_on: AttributeEffectFeature = _features_by_property[depends_on_name]
			if !_depended_on_by.has(depends_on._get_property_name()):
				_depended_on_by[depends_on._get_property_name()] = [feature]
			else:
				_depended_on_by[depends_on._get_property_name()].append(feature)


## Returns true if the [param property_name] represents an [AttributeEffectFeature].
func is_feature(property_name: StringName) -> bool:
	return _features_by_property.has(property_name)


## Validates the property (same as [method _validate_property]) but must be manually called
## by other [method _validate_property] implementations.
func validate_property(effect: AttributeEffect, property: Dictionary) -> void:
	if !_features_by_property.has(property.name):
		return
	var feature: AttributeEffectFeature = _features_by_property[property.name]
	
	# Editor visibility
	if !feature._show_in_editor(effect):
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif feature._make_read_only(effect):
		property.usage |= PROPERTY_USAGE_READ_ONLY
	
	# Hint String
	property.hint_string = feature._override_hint_string(effect, property.hint_string)


func validate_user_set_value(effect: AttributeEffect, property_name: StringName, value: Variant) -> bool:
	assert(_features_by_property.has(property_name), "no feature found for property_name %s" % property_name)
	
	# Ignore loading
	if effect._loading:
		return true
	
	var feature: AttributeEffectFeature = _features_by_property[property_name]
	
	if !feature._value_meets_requirements(value, effect):
		var requirements: String = feature._get_requirements_string(value)
		push_warning(("AttributeEffect(id=%s) does not meet the requirements \nto set property (%s) " + \
		"to value (%s), property will not be set.\nRequirements: %s") \
		% [effect.id, property_name, _var_to_string(value), requirements])
		return false
	
	feature._before_value_set(value, effect)
	
	return true


func notify_value_changed(effect: AttributeEffect, property_name: StringName) -> void:
	if !_depended_on_by.has(property_name):
		return
	
	effect.notify_property_list_changed()
	
	# Skip if the effect is still loading
	if effect._loading:
		return
	
	for feature: AttributeEffectFeature in _depended_on_by[property_name]:
		var current_value: Variant = effect.get(feature._get_property_name())
		
		if !feature._value_meets_requirements(current_value, effect):
			var requirements: String = feature._get_requirements_string(current_value)
			var new_value: Variant = feature._get_default_value(effect)
			if !Engine.is_editor_hint():
				push_warning(("AttributeEffect(id=%s) no longer meets requirements for \nproperty (%s) to " + \
				"equal (%s), setting value to default (%s).\nRequirements: %s") \
				% [effect.id, feature._get_property_name(), _var_to_string(current_value), 
			_var_to_string(new_value), requirements])
			effect.set(feature._get_property_name(), new_value)


func after_load(effect: AttributeEffect) -> void:
	pass


func get_default_value(effect: AttributeEffect, property_name: StringName) -> Variant:
	assert(_features_by_property.has(property_name), "no property with name %s found" \
	% property_name)
	return _features_by_property[property_name]._get_default_value(effect)


func _var_to_string(variant: Variant) -> String:
	match typeof(variant):
		TYPE_ARRAY:
			return "read-only Array" if variant.is_read_only() else "mutable Array"
		TYPE_OBJECT:
			return variant.get_script().get_global_name()
		_:
			return str(variant)

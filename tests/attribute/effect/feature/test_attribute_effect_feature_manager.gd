extends GutTest

const FEATURE_DIR: String = "res://addons/godot-attributes/effect/feature"

var file_paths: Array[String] = []
var test_effect: AttributeEffect

func before_all() -> void:
	test_effect = AttributeEffect.new("test")
	
	# Load file paths
	var files: PackedStringArray = DirAccess.get_files_at(FEATURE_DIR)
	for file_name: String in files:
		if file_name.get_extension() == "gd": 
			file_paths.append(file_name)
	# Erase base class & manager
	file_paths.erase("attribute_effect_feature.gd")
	file_paths.erase("attribute_effect_feature_manager.gd")
	# Initialize AttributeEffectFeatureManager
	AttributeEffectFeatureManager.i()


func after_all() -> void:
	test_effect = null
	AttributeEffectFeatureManager.i().free()
	AttributeEffectFeatureManager._instance = null


func test_every_feature_is_registered(file_name: String = use_parameters(file_paths)) -> void:
	var exists: bool = false
	var string: String = ""
	var feature: AttributeEffectFeature = null
	for _feature: AttributeEffectFeature in AttributeEffectFeatureManager.i()._features_by_property.values():
		if _feature.get_script().resource_path.get_file() == file_name:
			exists = true
			feature = _feature
			break
	assert_true(exists, "feature file not registered: %s" % file_name)


func test_default_value_meets_requirements(feature: AttributeEffectFeature = 
use_parameters(AttributeEffectFeatureManager.i()._features_by_property.values())) -> void:
	
	var default_value: Variant = feature._get_default_value(test_effect)
	assert_true(feature._value_meets_requirements(default_value, test_effect),
	"default_value (%s) of feature (%s) does meet requirements, returned string = %s" \
	% [default_value, feature, feature._get_requirements_string(default_value)])

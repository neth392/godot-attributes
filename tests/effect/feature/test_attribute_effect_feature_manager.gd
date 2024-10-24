extends GutTest

var file_paths: Array
var features_by_index: Array[Array]

func before_all() -> void:
	# Load file paths
	var files: PackedStringArray = DirAccess.get_files_at("res://addons/godot-attributes/effect/feature")
	file_paths = Array(files)
	# Erase base class & manager
	file_paths.erase("attribute_effect_feature.gd")
	file_paths.erase("attribute_effect_feature_manager.gd")
	# Initialize AttributeEffectFeatureManager
	AttributeEffectFeatureManager._init()
	
	for index: int in AttributeEffectFeatureManager._features.size():
		features_by_index.append([index, AttributeEffectFeatureManager._features[index]])


func test_assert_every_feature_is_registered(file_name = use_parameters(file_paths)) -> void:
	var exists: bool = false
	var string: String = ""
	for feature: AttributeEffectFeature in AttributeEffectFeatureManager._features:
		print(feature.get_script().resource_path.get_file())
		if feature.get_script().resource_path.get_file() == file_name:
			exists = true
			break
	assert_true(exists, "feature file not registered: %s" % file_name)


func test_assert_features_properly_sorted(params = use_parameters(features_by_index)) -> void:
	var index: int = params[0]
	var feature: AttributeEffectFeature = params[1] as AttributeEffectFeature
	for depends_on_name: String in feature._get_depends_on():
		var depends_on: AttributeEffectFeature = AttributeEffectFeatureManager._features_by_property[depends_on_name]
		var depends_on_index: int = AttributeEffectFeatureManager._features.find(depends_on)
		assert_lt(depends_on_index, index, "%s not sorted after one of its dependencies %s" % [feature, depends_on])

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
	AttributeEffectFeatureManager.i()


func after_all() -> void:
	AttributeEffectFeatureManager.i().free()
	AttributeEffectFeatureManager._instance = null


func tes_every_feature_is_registered(file_name = use_parameters(file_paths)) -> void:
	var exists: bool = false
	var string: String = ""
	for feature: AttributeEffectFeature in AttributeEffectFeatureManager.i()._features_by_property.values():
		if feature.get_script().resource_path.get_file() == file_name:
			exists = true
			break
	assert_true(exists, "feature file not registered: %s" % file_name)


func test_default_values_all_compatible() -> void:
	# TODO implement
	pass_test("NOT YET IMPLEMENTED")
	pass

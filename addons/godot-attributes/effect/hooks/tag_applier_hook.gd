## Hook that adds tags to an [Attribute]'s [AttributeContainer] when it is added,
## and if configured (and the effect is not instant) removes the tags afterwards.
@tool
class_name TagApplierHook extends AttributeEffectHook

const META_TAG: StringName = &"TagApplierHook.tags"

## The tags to be added when the [AttributeEffect] is added.
@export var tags: Array[StringName]

## If true, [member Attribute.tags] are included in the tags applied.
@export var include_effect_tags: bool = false

## Whether or not the tags should be removed afterwards.
@export var remove_after: bool = true

## If true, this hook will cache the tags applied by an [ActiveAttributeEffect]
## to it's [member ActiveAttributeEffect.meta] and use that list when removing tags. 
## Best for cases where [member tags] (or [member Attribute.tags] if 
## [member include_effect_tags] is true) are dynamically modified during runtime 
## which could lead to "forgotten" tags on an [AttributeContainer]. If false, 
## tags are retrieved directly from [member tags] (& possibly [member Attribute.tags]).
@export var cache_tags_to_remove: bool = false

@export_group("Debug Errors")

## If true and [function Attribute.get_container] is null, a debug error will be thrown.
@export var error_on_no_container: bool = false

func _validate_property(property: Dictionary) -> void:
	if property.name == "cache_tags_to_remove":
		if !remove_after:
			property.usage = PROPERTY_USAGE_STORAGE


func _before_active_added(attribute: Attribute, active: ActiveAttributeEffect,
event: AttributeEvent) -> void:
	var container: AttributeContainer = attribute.get_container()
	if container != null:
		var tags_to_apply: Array[StringName] = tags.duplicate()
		
		if include_effect_tags && !active.get_effect().tags.is_empty():
			tags_to_apply.append_array(active.get_effect().tags)
		
		if cache_tags_to_remove:
			active.meta[META_TAG] = tags_to_apply
		
		attribute.get_container().add_tags(tags_to_apply)
	elif error_on_no_container:
		assert(false, "no container for attribute: %s" % attribute)


func _before_active_removed(attribute: Attribute, active: ActiveAttributeEffect, 
event: AttributeEvent) -> void:
	if !remove_after:
		return
	var container: AttributeContainer = attribute.get_container()
	if container != null:
		if cache_tags_to_remove:
			assert(active.meta.has(META_TAG), "meta key (%s) not in active.meta for active (%s)" \
			 % [META_TAG, active])
			attribute.get_container().remove_tags(active.meta[META_TAG])
		else:
			attribute.get_container().remove_tags(tags)
			if include_effect_tags && !active.get_effect().tags.is_empty():
				attribute.get_container().remove_tags(active.get_effect().tags)
	elif error_on_no_container:
		assert(false, "no container for attribute: %s" % attribute)

## TODO docs
class_name WrappedAttributeBlockCondition extends AttributeEffectCondition


func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	if !active.get_effect().has_value:
		return true
	
	if attribute is WrappedAttribute:
		# Permanent effects
		if active.get_effect().is_permanent():
			if attribute.has_base_min():
				var base_min_value: float = attribute._get_base_min_value()
				# If configured, block if new value will be < base min
				if attribute.block_effects_lt_base_min \
				and active.get_pending_raw_attribute_value() < base_min_value:
					return false
				
				# Block apply if already <= base & new value will be at or <= as well
				if attribute.get_base_value() <= base_min_value \
				and active.get_pending_final_attribute_value() <= base_min_value:
					return false
				
		# Temporary effects
		else:
			pass
		pass
	
	return true

## Contains the logic for a [WrappedAttribute]'s limits. Created to ensure the
## logic of the limits are not copy/pasted. It is overly abstracted but that
## ensures any changes only need to be made to 1 place, not several, securing
## the integrity of the code.
@tool
class_name WrappedAttributeLimit extends RefCounted

static var _base_value_accessor: AttributeValueAccessor = BaseValueAccessor.new()
static var _current_value_accessor: AttributeValueAccessor = CurrentValueAccessor.new()

static var _min_limit_interface: LimitInterface = MinLimit.new()
static var _max_limit_interface: LimitInterface = MaxLimit.new()

static var _base_min: WrappedAttributeLimit = BaseMinLimit.new()
static var _base_max: WrappedAttributeLimit = BaseMaxLimit.new()
static var _current_min: WrappedAttributeLimit = CurrentMinLimit.new()
static var _current_max: WrappedAttributeLimit = CurrentMaxLimit.new()

static func base_min() -> WrappedAttributeLimit:
	return _base_min

static func base_max() -> WrappedAttributeLimit:
	return _base_max

static func current_min() -> WrappedAttributeLimit:
	return _current_min

static func current_max() -> WrappedAttributeLimit:
	return _current_max


var _attribute_value_accessor: AttributeValueAccessor
var _limit_interface: LimitInterface


func _init(attribute_value_accessor: AttributeValueAccessor, 
limit_interface: LimitInterface) -> void:
	_attribute_value_accessor = attribute_value_accessor
	_limit_interface = limit_interface


func after_set_type(instance: WrappedAttribute, has_prev_limit: bool, prev_limit_value: float, 
prev_type: WrappedAttribute.WrapLimitType) -> void:
	# Nullify attribute if type is not attribute to avoid rogue reference to Node
	if _get_limit_type(instance) != WrappedAttribute.WrapLimitType.ATTRIBUTE:
		_nullify_attribute(instance)
	
	# In editor or type was set to the same, don't emit event or handle the change
	if Engine.is_editor_hint() || _get_limit_type(instance) == prev_type:
		# Notify the editor
		instance.notify_property_list_changed()
		instance.update_configuration_warnings()
		return
	
	var event: WrappedAttributeEvent = instance._create_event()
	var has_new_limit: bool = has_limit(instance)
	
	var new_limit_value: float = get_limit_value_unsafe(instance) if has_new_limit \
	else _limit_interface._get_hard_limit()
	
	handle_limit_value_change(instance, has_prev_limit, prev_limit_value, has_new_limit,
	new_limit_value, event)
	instance._emit_event(event)


func after_set_fixed(instance: WrappedAttribute, prev_value: float) -> void:
	var new_value: float = _get_fixed(instance)
	
	if Engine.is_editor_hint() \
	or _get_limit_type(instance) != WrappedAttribute.WrapLimitType.FIXED \
	or prev_value == new_value:
		instance.notify_property_list_changed()
		instance.update_configuration_warnings()
		return
	
	var event: WrappedAttributeEvent = instance._create_event()
	handle_limit_value_change(instance, true, prev_value, true, new_value, event)
	instance._emit_event(event)


func before_set_attribute(instance: WrappedAttribute, current_attribute: Attribute,
 new_attribute: Attribute) -> void:
	
	if Engine.is_editor_hint() \
	or _get_limit_type(instance) != WrappedAttribute.WrapLimitType.ATTRIBUTE \
	or current_attribute == null || current_attribute == new_attribute:
		return
	
	# Disconnect from the signal
	AttributeUtil.disconnect_safely(current_attribute.event_occurred, 
	_get_limit_attribute_signal_handler(instance))


func after_set_attribute(instance: WrappedAttribute, prev_attribute: Attribute,
 new_attribute: Attribute) -> void:
	if Engine.is_editor_hint() \
	or _get_limit_type(instance) != WrappedAttribute.WrapLimitType.ATTRIBUTE \
	or prev_attribute == new_attribute:
		instance.notify_property_list_changed()
		instance.update_configuration_warnings()
		return
	
	var has_prev: bool = prev_attribute != null
	var prev_value: float = prev_attribute.get_value(_get_limit_value_to_use(instance)) \
	if has_prev else _limit_interface._get_hard_limit()
	
	var has_new: bool = new_attribute != null
	var new_value: float = new_attribute.get_value(_get_limit_value_to_use(instance)) \
	if has_new else _limit_interface._get_hard_limit()
	
	# Connect to signal
	if has_new:
		AttributeUtil.connect_safely(new_attribute.event_occurred, 
		_get_limit_attribute_signal_handler(instance))
	
	# Handle value changing if new attribute diff val than old attribute
	if prev_value != new_value:
		var event: WrappedAttributeEvent = instance._create_event()
		handle_limit_value_change(instance, has_prev, prev_value, has_new, new_value, event)
		instance._emit_event(event)


func after_set_value_to_use(instance: WrappedAttribute, prev_value_to_use: Attribute.Value) -> void:
	var attribute: Attribute = _get_limit_attribute(instance)
	var new_value_to_use: Attribute.Value = _get_limit_value_to_use(instance)
	
	if Engine.is_editor_hint() \
	or _get_limit_type(instance) != WrappedAttribute.WrapLimitType.ATTRIBUTE \
	or attribute == null \
	or new_value_to_use == prev_value_to_use:
		return
	
	var prev_value: float = attribute.get_value(prev_value_to_use)
	var new_value: float = attribute.get_value(new_value_to_use)
	
	var event: WrappedAttributeEvent = instance._create_event()
	handle_limit_value_change(instance, true, prev_value, true, new_value, event)
	instance._emit_event(event)


func handle_limit_value_change(instance: WrappedAttribute, has_prev_limit: bool, 
prev_limit_value: float,has_new_limit: bool, new_limit_value: float, 
event: WrappedAttributeEvent) -> void:
	var prev_attribute_value: float = _attribute_value_accessor._get_attribute_value(instance)
	
	# Detect if it was at the limit
	var was_at_limit: bool = has_prev_limit \
	and _limit_interface._is_at_or_equal_to_limit(prev_attribute_value, prev_limit_value)
	
	var hit_limit: bool = false
	
	# Wrap the attribute value if outside of new limit
	if has_new_limit:
		var new_attribute_value: float = prev_attribute_value
		
		# Value is out of bounds
		if _limit_interface._is_out_of_bounds(prev_attribute_value, new_limit_value):
			# Validate & set new attribute value
			new_attribute_value = _attribute_value_accessor._validate_and_set_attribute_value(
			instance, prev_attribute_value, event)
			# Limit was hit
			hit_limit = true
		else:
			# Detect if at limit
			hit_limit = _limit_interface._is_at_or_equal_to_limit(new_attribute_value, 
			new_limit_value)
	
	# Populate the event
	_populate_event(event, has_prev_limit, has_new_limit, prev_limit_value, new_limit_value, 
	!was_at_limit && hit_limit, was_at_limit &&  !hit_limit)


func append_warnings(instance: WrappedAttribute, warnings: PackedStringArray) -> void:
	# Warn if initial value is out of bounds
	if has_limit(instance):
		var limit_value: float = get_limit_value_unsafe(instance)
		var attribute_value: float = _attribute_value_accessor._get_attribute_value(instance)
		
		if _limit_interface._is_out_of_bounds(attribute_value, limit_value):
			warnings.append("%s (%s) is %s %s's value of (%s)" \
			% [_attribute_value_accessor._get_value_display_name(), attribute_value,
			_limit_interface._get_oob_operator_display(), _get_limit_display_name(), limit_value])
	
	# Warn if type set to ATTRIBUTE but attribute is null
	if _get_limit_type(instance) == WrappedAttribute.WrapLimitType.ATTRIBUTE \
	and _get_limit_attribute(instance) == null:
		warnings.append("base_min_type set to ATTRIBUTE but base_min_attribute is null")


func get_limit_value(instance: WrappedAttribute) -> float:
	match _get_limit_type(instance):
		WrappedAttribute.WrapLimitType.NONE:
			return _limit_interface._get_hard_limit()
		WrappedAttribute.WrapLimitType.FIXED:
			return _get_fixed(instance)
		WrappedAttribute.WrapLimitType.ATTRIBUTE:
			var attribute: Attribute = _get_limit_attribute(instance)
			return _limit_interface._get_hard_limit() if attribute == null \
			else attribute.get_value(_get_limit_value_to_use(instance))
		_:
			assert(false, "no implementation for WrapLimitType %s" % _get_limit_type(instance))
			return _limit_interface._get_hard_limit()


func get_limit_value_unsafe(instance: WrappedAttribute) -> float:
	assert(has_limit(instance), "no %s limit for instance (%s)" \
	% [_get_limit_display_name(), instance])
	var type: WrappedAttribute.WrapLimitType = _get_limit_type(instance)
	if type == WrappedAttribute.WrapLimitType.FIXED:
		return _get_fixed(instance)
	return _get_limit_attribute(instance).get_value(_get_limit_value_to_use(instance))


func has_limit(instance: WrappedAttribute) -> bool:
	match _get_limit_type(instance):
		WrappedAttribute.WrapLimitType.ATTRIBUTE:
			return _get_limit_attribute(instance) != null
		WrappedAttribute.WrapLimitType.FIXED:
			return true
		_:
			return false


func _get_limit_type(instance: WrappedAttribute) -> WrappedAttribute.WrapLimitType:
	assert(false, "_get_limit_type not implemented")
	return -1


func _get_fixed(instance: WrappedAttribute) -> float:
	assert(false, "_get_fixed not implemented")
	return 0.0


func _nullify_attribute(instance: WrappedAttribute) -> void:
	assert(false, "_nullify_attribute not implemented")


func _get_limit_attribute(instance: WrappedAttribute) -> Attribute:
	assert(false, "_get_limit_attribute not implemented")
	return null


func _get_limit_value_to_use(instance: WrappedAttribute) -> Attribute.Value:
	assert(false, "_get_limit_value_to_use not implemented")
	return -1


func _get_limit_attribute_signal_handler(instance: WrappedAttribute) -> Callable:
	assert(false, "_get_limit_attribute_callable not implemented")
	return Callable()


func _populate_event(event: WrappedAttributeEvent, has_prev_limit: bool, has_new_limit: bool, 
prev_limit_value: float, new_limit_value: float, hit_limit: bool, left_limit: bool) -> void:
	assert(false, "_populate_event not implemented")


func _get_limit_display_name() -> String:
	assert(false, "_get_limit_display_name not implemented")
	return ""


class AttributeValueAccessor extends RefCounted:
	
	func _get_attribute_value(instance: WrappedAttribute) -> float:
		assert(false, "_get_attribute_value not implemented")
		return 0.0
	
	
	func _validate_and_set_attribute_value(instance: WrappedAttribute, value: float, 
	event: WrappedAttributeEvent) -> float:
		assert(false, "_validate_and_set_attribute_value not implemented")
		return 0.0
	
	
	func _get_value_display_name() -> String:
		assert(false, "_get_value_display_name not implemented")
		return ""


class BaseValueAccessor extends AttributeValueAccessor:
	
	func _get_attribute_value(instance: WrappedAttribute) -> float:
		return instance._base_value
	
	
	func _validate_and_set_attribute_value(instance: WrappedAttribute, value: float, 
	event: WrappedAttributeEvent) -> float:
		var new_base_value: float = instance._validate_base_value(value)
		instance._set_base_value_pre_validated(new_base_value, event)
		return new_base_value
	
	
	func _get_value_display_name() -> String:
		return "base_value"


class CurrentValueAccessor extends AttributeValueAccessor:
	
	func _get_attribute_value(instance: WrappedAttribute) -> float:
		return instance._current_value
	
	
	func _validate_and_set_attribute_value(instance: WrappedAttribute, value: float, 
	event: WrappedAttributeEvent) -> float:
		instance._update_current_value(event)
		return instance._current_value
	
	
	func _get_value_display_name() -> String:
		return "current_value"


class LimitInterface extends RefCounted:
	
	func _get_hard_limit() -> float:
		assert(false, "_get_hard_limit not implemented")
		return 0.0
	
	
	func _is_at_or_equal_to_limit(value: float, limit: float) -> bool:
		assert(false, "_is_at_or_equal_to_limit not implemented")
		return false
	
	
	func _is_out_of_bounds(value: float, limit: float) -> bool:
		assert(false, "_is_out_of_bounds not implemented")
		return false
	
	
	func _get_oob_operator_display() -> String:
		assert(false, "_get_oob_operator_display not implemented")
		return ""


class MinLimit extends LimitInterface:
	
	func _get_hard_limit() -> float:
		return WrappedAttribute.HARD_MIN
	
	
	func _is_at_or_equal_to_limit(value: float, limit: float) -> bool:
		return value <= limit
	
	
	func _is_out_of_bounds(value: float, limit: float) -> bool:
	
		return value < limit
	
	func _get_oob_operator_display() -> String:
		return "<"


class MaxLimit extends LimitInterface:
	
	func _get_hard_limit() -> float:
		return WrappedAttribute.HARD_MAX
	
	
	func _is_at_or_equal_to_limit(value: float, limit: float) -> bool:
		return value >= limit
	
	
	func _is_out_of_bounds(value: float, limit: float) -> bool:
		return value > limit
	
	
	func _get_oob_operator_display() -> String:
		return ">"


class BaseMinLimit extends WrappedAttributeLimit:
	
	func _init() -> void:
		super._init(WrappedAttributeLimit._base_value_accessor, 
		WrappedAttributeLimit._min_limit_interface)
	
	
	func _get_limit_type(instance: WrappedAttribute) -> WrappedAttribute.WrapLimitType:
		return instance.base_min_type
	
	
	func _get_fixed(instance: WrappedAttribute) -> float:
		return instance.base_min_fixed
	
	
	func _nullify_attribute(instance: WrappedAttribute) -> void:
		instance.base_min_attribute = null
	
	
	func _populate_event(event: WrappedAttributeEvent, has_prev_limit: bool, has_new_limit: bool, 
	prev_limit_value: float, new_limit_value: float, hit_limit: bool, left_limit: bool) -> void:
		
		event._has_prev_base_min = has_prev_limit
		event._has_new_base_min = has_new_limit
		event._prev_base_min = prev_limit_value
		event._new_base_min = new_limit_value
		event._base_hit_min = hit_limit
		event._base_left_min = left_limit
	
	
	func _get_limit_attribute(instance: WrappedAttribute) -> Attribute:
		return instance.base_min_attribute
	
	
	func _get_limit_value_to_use(instance: WrappedAttribute) -> Attribute.Value:
		return instance.base_min_value_to_use
	
	
	func _get_limit_attribute_signal_handler(instance: WrappedAttribute) -> Callable:
		return instance._on_base_min_value_changed
	
	
	func _get_limit_display_name() -> String:
		return "base_min"


class BaseMaxLimit extends WrappedAttributeLimit:
	
	func _init() -> void:
		super._init(WrappedAttributeLimit._base_value_accessor, 
		WrappedAttributeLimit._max_limit_interface)
	
	
	func _get_limit_type(instance: WrappedAttribute) -> WrappedAttribute.WrapLimitType:
		return instance.base_max_type
	
	
	func _get_fixed(instance: WrappedAttribute) -> float:
		return instance.base_max_fixed
	
	
	func _nullify_attribute(instance: WrappedAttribute) -> void:
		instance.base_max_attribute = null
	
	
	func _populate_event(event: WrappedAttributeEvent, has_prev_limit: bool, has_new_limit: bool, 
	prev_limit_value: float, new_limit_value: float, hit_limit: bool, left_limit: bool) -> void:
		
		event._has_prev_base_max = has_prev_limit
		event._has_new_base_max = has_new_limit
		event._prev_base_max = prev_limit_value
		event._new_base_max = new_limit_value
		event._base_hit_max = hit_limit
		event._base_left_max = left_limit
	
	
	func _get_limit_attribute(instance: WrappedAttribute) -> Attribute:
		return instance.base_max_attribute
	
	
	func _get_limit_value_to_use(instance: WrappedAttribute) -> Attribute.Value:
		return instance.base_max_value_to_use
	
	
	func _get_limit_attribute_signal_handler(instance: WrappedAttribute) -> Callable:
		return instance._on_base_max_value_changed
	
	
	func _get_limit_display_name() -> String:
		return "base_max"


class CurrentMinLimit extends WrappedAttributeLimit:
	
	func _init() -> void:
		super._init(WrappedAttributeLimit._current_value_accessor, 
		WrappedAttributeLimit._min_limit_interface)
	
	
	func _get_limit_type(instance: WrappedAttribute) -> WrappedAttribute.WrapLimitType:
		return instance.current_min_type
	
	
	func _get_fixed(instance: WrappedAttribute) -> float:
		return instance.current_min_fixed
	
	
	func _nullify_attribute(instance: WrappedAttribute) -> void:
		instance.current_min_attribute = null
	
	
	func _populate_event(event: WrappedAttributeEvent, has_prev_limit: bool, has_new_limit: bool, 
	prev_limit_value: float, new_limit_value: float, hit_limit: bool, left_limit: bool) -> void:
		
		event._has_prev_current_min = has_prev_limit
		event._has_new_current_min = has_new_limit
		event._prev_current_min = prev_limit_value
		event._new_current_min = new_limit_value
		event._current_hit_min = hit_limit
		event._current_left_min = left_limit
	
	
	func _get_limit_attribute(instance: WrappedAttribute) -> Attribute:
		return instance.current_min_attribute
	
	
	func _get_limit_value_to_use(instance: WrappedAttribute) -> Attribute.Value:
		return instance.current_min_value_to_use
	
	
	func _get_limit_attribute_signal_handler(instance: WrappedAttribute) -> Callable:
		return instance._on_current_min_value_changed
	
	
	func _get_limit_display_name() -> String:
		return "current_min"


class CurrentMaxLimit extends WrappedAttributeLimit:
	
	func _init() -> void:
		super._init(WrappedAttributeLimit._current_value_accessor, 
		WrappedAttributeLimit._max_limit_interface)
	
	
	func _get_limit_type(instance: WrappedAttribute) -> WrappedAttribute.WrapLimitType:
		return instance.current_max_type
	
	
	func _get_fixed(instance: WrappedAttribute) -> float:
		return instance.current_max_fixed
	
	
	func _nullify_attribute(instance: WrappedAttribute) -> void:
		instance.current_max_attribute = null
	
	
	func _populate_event(event: WrappedAttributeEvent, has_prev_limit: bool, has_new_limit: bool, 
	prev_limit_value: float, new_limit_value: float, hit_limit: bool, left_limit: bool) -> void:
		
		event._has_prev_current_max = has_prev_limit
		event._has_new_current_max = has_new_limit
		event._prev_current_max = prev_limit_value
		event._new_current_max = new_limit_value
		event._current_hit_max = hit_limit
		event._current_left_max = left_limit
	
	
	func _get_limit_attribute(instance: WrappedAttribute) -> Attribute:
		return instance.current_max_attribute
	
	
	func _get_limit_value_to_use(instance: WrappedAttribute) -> Attribute.Value:
		return instance.current_max_value_to_use
	
	
	func _get_limit_attribute_signal_handler(instance: WrappedAttribute) -> Callable:
		return instance._on_current_max_value_changed
	
	
	func _get_limit_display_name() -> String:
		return "current_max"

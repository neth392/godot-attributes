extends Node

var tick_started: int
var health_attribute: Attribute

func _ready():
	tick_started = Time.get_ticks_usec()
	var attr_scene: PackedScene = load("res://dev_testing/health_attribute.tscn") as PackedScene
	
	health_attribute = $AttributeContainer/WrappedAttribute
	#$AttributeContainer.add_child(health_attribute)
	
	# Connect value signals
	health_attribute.event_occurred.connect(_event_current_value_changed)
	health_attribute.event_occurred.connect(_event_base_value_changed)
	
	# Connect effect signals
	health_attribute.event_occurred.connect(_event_active_added)
	health_attribute.event_occurred.connect(_event_active_applied)
	health_attribute.event_occurred.connect(_event_active_removed)
	health_attribute.event_occurred.connect(_event_active_stack_count_changed)
	health_attribute.event_occurred.connect(_event_active_add_blocked)
	health_attribute.event_occurred.connect(_event_active_apply_blocked)
	
	if health_attribute is WrappedAttribute:
		health_attribute.event_occurred.connect(_event_base_hit_min)
		health_attribute.event_occurred.connect(_event_base_left_min)
		health_attribute.event_occurred.connect(_event_base_min_changed)
		
		health_attribute.event_occurred.connect(_event_base_hit_max)
		health_attribute.event_occurred.connect(_event_base_left_max)
		health_attribute.event_occurred.connect(_event_base_max_changed)
		
		health_attribute.event_occurred.connect(_event_current_hit_min)
		health_attribute.event_occurred.connect(_event_current_left_min)
		health_attribute.event_occurred.connect(_event_current_min_changed)
		
		health_attribute.event_occurred.connect(_event_current_hit_max)
		health_attribute.event_occurred.connect(_event_current_left_max)
		health_attribute.event_occurred.connect(_event_current_max_changed)
	
	var drain_effect: AttributeEffect = load("res://dev_testing/drain_effect.tres") as AttributeEffect
	
	health_attribute.add_effect(drain_effect)


func _print(message: String) -> void:
	print("0%.4f" % ((Time.get_ticks_usec() - tick_started) / 1_000_000.0), "s: ", message)
	pass


func _event_current_value_changed(event: AttributeEvent) -> void:
	if !event.current_value_changed():
		return
	_print("EVENT: current_value_changed: new_value=%s, prev_current_value=%s" \
	% [event.get_new_current_value(), event.get_prev_current_value()])


func _event_base_value_changed(event: AttributeEvent) -> void:
	if !event.base_value_changed():
		return
	_print("EVENT: base_value_changed: new_value=%s, prev_base_value=%s, active=%s" \
	% [event.get_new_base_value(), event.get_prev_base_value(), event.get_active_effect()])
	if event.get_new_base_value() <= 50.0:
		pass


func _event_active_added(event: AttributeEvent) -> void:
	if !event.is_add_event():
		return
	_print("EVENT: active_added: active=%s" % [event.get_active_effect()])


func _event_active_applied(event: AttributeEvent) -> void:
	if !event.is_apply_event():
		return
	_print("EVENT: active_applied: active=%s" % [event.get_active_effect()])


func _event_active_removed(event: AttributeEvent) -> void:
	if !event.is_remove_event():
		return
	_print("EVENT: active_removed: active=%s" % [event.get_active_effect()])


func _event_active_stack_count_changed(event: AttributeEvent) -> void:
	if !event.active_stack_count_changed():
		return
	_print("EVENT: active_stack_count_changed: active=%s, previous_stack_count=%s" \
	% [event.get_active_effect(), event.get_prev_active_stack_count()])


func _event_active_add_blocked(event: AttributeEvent) -> void:
	if !event.is_add_block_event():
		return
	var effect: ActiveAttributeEffect = event.get_active_effect()
	_print("EVENT: active_add_blocked: blocked=%s, blocked_by=%s, blocked_by_source=%s" \
	% [effect, effect.get_last_blocked_by().message, effect.get_last_blocked_by_source().get_effect().id])


func _event_active_apply_blocked(event: AttributeEvent) -> void:
	if !event.is_apply_blocked_event():
		return
	var effect: ActiveAttributeEffect = event.get_active_effect()
	_print("EVENT: active_apply_blocked: blocked=%s, blocked_by=%s, blocked_by_source=%s" \
	% [effect, effect.get_last_blocked_by().message, effect.get_last_blocked_by_source().get_effect().id])


func _event_base_hit_min(event: WrappedAttributeEvent) -> void:
	if !event.is_base_hit_min_event():
		return
	_print("EVENT: base_hit_min, base=%s, min=%s" \
	% [health_attribute.get_base_value(), health_attribute.get_base_min_value()])


func _event_base_left_min(event: WrappedAttributeEvent) -> void:
	if !event.is_base_left_min_event():
		return
	_print("EVENT: base_left_min, base=%s, min=%s" \
	% [health_attribute.get_base_value(), health_attribute.get_base_min_value()])


func _event_base_min_changed(event: WrappedAttributeEvent) -> void:
	if !event.is_base_min_changed_event():
		return
	_print("EVENT: base_min_changed, prev_base_min=%s, new_base_min=%s" \
	% [event.get_prev_base_min(), event.get_new_base_min()])


func _event_base_hit_max(event: WrappedAttributeEvent) -> void:
	if !event.is_base_hit_max_event():
		return
	_print("EVENT: base_hit_max, base=%s, max=%s" \
	% [health_attribute.get_base_value(), health_attribute.get_base_max_value()])


func _event_base_left_max(event: WrappedAttributeEvent) -> void:
	if !event.is_base_left_max_event():
		return
	_print("EVENT: base_left_max, base=%s, max=%s" \
	% [health_attribute.get_base_value(), health_attribute.get_base_max_value()])


func _event_base_max_changed(event: WrappedAttributeEvent) -> void:
	if !event.is_base_max_changed_event():
		return
	_print("EVENT: base_max_changed, prev_base_max=%s, new_base_max=%s" \
	% [event.get_prev_base_max(), event.get_new_base_max()])


func _event_current_hit_min(event: WrappedAttributeEvent) -> void:
	if !event.is_current_hit_min_event():
		return
	_print("EVENT: current_hit_min, current=%s, min=%s" \
	% [health_attribute.get_current_value(), health_attribute.get_current_min_value()])


func _event_current_left_min(event: WrappedAttributeEvent) -> void:
	if !event.is_current_left_min_event():
		return
	_print("EVENT: current_left_min, current=%s, min=%s" \
	% [health_attribute.get_current_value(), health_attribute.get_current_min_value()])


func _event_current_min_changed(event: WrappedAttributeEvent) -> void:
	if !event.is_current_min_changed_event():
		return
	_print("EVENT: current_min_changed, prev_current_min=%s, new_current_min=%s" \
	% [event.get_prev_current_min(), event.get_new_current_min()])


func _event_current_hit_max(event: WrappedAttributeEvent) -> void:
	if !event.is_current_hit_max_event():
		return
	_print("EVENT: current_hit_max, current=%s, max=%s" \
	% [health_attribute.get_current_value(), health_attribute.get_current_max_value()])


func _event_current_left_max(event: WrappedAttributeEvent) -> void:
	if !event.is_current_left_max_event():
		return
	_print("EVENT: current_left_max, current=%s, max=%s" \
	% [health_attribute.get_current_value(), health_attribute.get_current_max_value()])


func _event_current_max_changed(event: WrappedAttributeEvent) -> void:
	if !event.is_current_max_changed_event():
		return
	_print("EVENT: current_max_changed, prev_current_max=%s, new_current_max=%s" \
	% [event.get_prev_current_max(), event.get_new_current_max()])

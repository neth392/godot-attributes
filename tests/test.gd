extends Node

@onready var health_attribute: Attribute = $AttributeContainer/Attribute

var tick_started: int

func _ready():
	tick_started = Time.get_ticks_usec()
	# Connect value signals
	health_attribute.monitor_current_value_changed.connect(_monitor_current_value_changed)
	health_attribute.event_occurred.connect(_event_current_value_changed)
	health_attribute.monitor_base_value_changed.connect(_monitor_base_value_changed)
	health_attribute.event_occurred.connect(_event_base_value_changed)
	
	# Connect effect signals
	health_attribute.monitor_active_added.connect(_monitor_active_added)
	health_attribute.event_occurred.connect(_event_active_added)
	health_attribute.monitor_active_applied.connect(_monitor_active_applied)
	health_attribute.event_occurred.connect(_event_active_applied)
	health_attribute.monitor_active_removed.connect(_monitor_active_removed)
	health_attribute.event_occurred.connect(_event_active_removed)
	health_attribute.monitor_active_stack_count_changed.connect(_monitor_active_stack_count_changed)
	health_attribute.event_occurred.connect(_event_active_stack_count_changed)
	health_attribute.monitor_active_add_blocked.connect(_monitor_active_add_blocked)
	health_attribute.event_occurred.connect(_event_active_add_blocked)
	health_attribute.monitor_active_apply_blocked.connect(_monitor_active_apply_blocked)
	health_attribute.event_occurred.connect(_event_active_apply_blocked)
	
	var drain_effect: AttributeEffect = load("res://tests/drain_effect.tres") as AttributeEffect
	health_attribute.add_active(drain_effect.create_active_effect())


func _print(message: String) -> void:
	print("0%.4f" % ((Time.get_ticks_usec() - tick_started) / 1_000_000.0), "s: ", message)


func _monitor_current_value_changed(prev_current_value: float) -> void:
	_print("MONITOR: current_value_changed: new_value=%s, prev_current_value=%s" \
	% [health_attribute.get_current_value(), prev_current_value])


func _event_current_value_changed(event: AttributeEvent) -> void:
	if !event.current_value_changed():
		return
	_print("EVENT: current_value_changed: new_value=%s, prev_current_value=%s" \
	% [event.get_new_current_value(), event.get_prev_current_value()])


func _monitor_base_value_changed(prev_base_value: float, active: ActiveAttributeEffect) -> void:
	_print("MONITOR: base_value_changed: new_value=%s, prev_base_value=%s, active=%s" \
	% [health_attribute.get_base_value(), prev_base_value, active])


func _event_base_value_changed(event: AttributeEvent) -> void:
	if !event.base_value_changed():
		return
	_print("EVENT: base_value_changed: new_value=%s, prev_base_value=%s, active=%s" \
	% [event.get_new_base_value(), event.get_prev_base_value(), event.get_active_effect()])


func _monitor_active_added(active: ActiveAttributeEffect) -> void:
	_print("MONITOR: active_added: active=%s" % [active])


func _event_active_added(event: AttributeEvent) -> void:
	if !event.is_add_event():
		return
	_print("EVENT: active_added: active=%s" % [event.get_active_effect()])


func _monitor_active_applied(active: ActiveAttributeEffect) -> void:
	_print("MONITOR: active_applied: active=%s" % [active])


func _event_active_applied(event: AttributeEvent) -> void:
	if !event.is_apply_event():
		return
	_print("EVENT: active_applied: active=%s" % [event.get_active_effect()])


func _monitor_active_removed(active: ActiveAttributeEffect) -> void:
	_print("MONITOR: active_removed: active=%s" % [active])


func _event_active_removed(event: AttributeEvent) -> void:
	if !event.is_remove_event():
		return
	_print("EVENT: active_removed: active=%s" % [event.get_active_effect()])


func _monitor_active_stack_count_changed(active: ActiveAttributeEffect, previous_stack_count: int) -> void:
	_print("MONITOR: active_stack_count_changed: active=%s, previous_stack_count=%s" \
	% [active, previous_stack_count])


func _event_active_stack_count_changed(event: AttributeEvent) -> void:
	if !event.active_stack_count_changed():
		return
	_print("EVENT: active_stack_count_changed: active=%s, previous_stack_count=%s" \
	% [event.get_active_effect(), event.get_prev_active_stack_count()])


func _monitor_active_add_blocked(blocked: ActiveAttributeEffect) -> void:
	_print("MONITOR: active_add_blocked: blocked=%s, blocked_by=%s, blocked_by_source=%s" \
	% [blocked, blocked.get_last_blocked_by().message, blocked.get_last_blocked_by_source().get_effect().id])


func _event_active_add_blocked(event: AttributeEvent) -> void:
	if !event.is_add_block_event():
		return
	var effect: ActiveAttributeEffect = event.get_active_effect()
	_print("EVENT: active_add_blocked: blocked=%s, blocked_by=%s, blocked_by_source=%s" \
	% [effect, effect.get_last_blocked_by().message, effect.get_last_blocked_by_source().get_effect().id])


func _monitor_active_apply_blocked(blocked: ActiveAttributeEffect) -> void:
	_print("MONITOR: active_apply_blocked: blocked=%s, blocked_by=%s, blocked_by_source=%s" \
	% [blocked, blocked.get_last_blocked_by().message, blocked.get_last_blocked_by_source().get_effect().id])


func _event_active_apply_blocked(event: AttributeEvent) -> void:
	if !event.is_apply_blocked_event():
		return
	var effect: ActiveAttributeEffect = event.get_active_effect()
	_print("EVENT: active_apply_blocked: blocked=%s, blocked_by=%s, blocked_by_source=%s" \
	% [effect, effect.get_last_blocked_by().message, effect.get_last_blocked_by_source().get_effect().id])
	

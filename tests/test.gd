extends Node

@onready var health_attribute: Attribute = $AttributeContainer/Attribute

var tick_started: int

func _ready():
	tick_started = Time.get_ticks_usec()
	# Connect value signals
	health_attribute.monitor_current_value_changed.connect(_on_current_value_changed)
	health_attribute.monitor_base_value_changed.connect(_on_base_value_changed)
	
	# Connect effect signals
	health_attribute.monitor_active_added.connect(_on_active_added)
	health_attribute.monitor_active_applied.connect(_on_active_applied)
	health_attribute.monitor_active_removed.connect(_on_active_removed)
	health_attribute.monitor_active_stack_count_changed.connect(_on_active_stack_count_changed)
	health_attribute.monitor_active_add_blocked.connect(_on_active_add_blocked)
	health_attribute.monitor_active_apply_blocked.connect(_on_active_apply_blocked)
	
	health_attribute.event_occurred.connect(_event)
	
	var drain_effect: AttributeEffect = load("res://tests/drain_effect.tres") as AttributeEffect
	health_attribute.add_active(drain_effect.create_active_effect())


func _print(message: String) -> void:
	print((Time.get_ticks_usec() - tick_started) / 1_000_000.0, "s: ", message)


func _event(attribute_event: AttributeEvent) -> void:
	print("ATTRIBUTE EVENT: ", inst_to_dict(attribute_event))


func _on_current_value_changed(prev_current_value: float) -> void:
	_print("current_value_changed: new_value=%s, prev_current_value=%s" \
	% [health_attribute.get_current_value(), prev_current_value])


func _on_base_value_changed(prev_base_value: float, active: ActiveAttributeEffect) -> void:
	_print("base_value_changed: new_value=%s, prev_base_value=%s, active=%s" \
	% [health_attribute.get_base_value(), prev_base_value, active])

func _on_active_added(active: ActiveAttributeEffect) -> void:
	_print("active_added: active=%s" % [active])

func _on_active_applied(active: ActiveAttributeEffect) -> void:
	_print("active_applied: active=%s" % [active])

func _on_active_removed(active: ActiveAttributeEffect) -> void:
	_print("active_removed: active=%s" % [active])

func _on_active_stack_count_changed(active: ActiveAttributeEffect, previous_stack_count: int) -> void:
	_print("active_stack_count_changed: active=%s, previous_stack_count=%s" % [active, previous_stack_count])

func _on_active_add_blocked(blocked: ActiveAttributeEffect, blocked_by: ActiveAttributeEffect) -> void:
	_print("active_add_blocked: blocked=%s, blocked_by=%s" % [blocked, blocked_by])

func _on_active_apply_blocked(blocked: ActiveAttributeEffect, blocked_by: ActiveAttributeEffect) -> void:
	_print("active_apply_blocked: blocked=%s, blocked_by=%s" % [blocked, blocked_by])

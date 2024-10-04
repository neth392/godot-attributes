extends Node

@onready var health_attribute: Attribute = $AttributeContainer/Attribute

var tick_started: int

func _ready():
	tick_started = Time.get_ticks_usec()
	# Connect value signals
	health_attribute.current_value_changed.connect(_on_current_value_changed)
	health_attribute.base_value_changed.connect(_on_base_value_changed)
	
	# Connect effect signals
	health_attribute.active_added.connect(_on_active_added)
	health_attribute.active_applied.connect(_on_active_applied)
	health_attribute.active_removed.connect(_on_active_removed)
	health_attribute.active_stack_count_changed.connect(_on_active_stack_count_changed)
	health_attribute.active_add_blocked.connect(_on_active_add_blocked)
	health_attribute.active_apply_blocked.connect(_on_active_apply_blocked)
	
	var drain_effect: AttributeEffect = load("res://tests/test_effect.tres") as AttributeEffect
	health_attribute.add_active(drain_effect.create_active_effect())


func _print(message: String) -> void:
	print((Time.get_ticks_usec() - tick_started) / 1_000_000.0, "s: ", message)


func _on_current_value_changed(prev_current_value: float) -> void:
	_print("current_value_changed: new_value=%s, prev_current_value=%s" \
	% [health_attribute.get_current_value(), prev_current_value])
	var boost_effect: AttributeEffect = load("res://tests/health_boost_effect.tres") as AttributeEffect
	if !health_attribute.has_effect(boost_effect):
		health_attribute.add_active(boost_effect.create_active_effect())

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

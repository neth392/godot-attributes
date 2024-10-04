## Represents a floating point value that can have [AttributeEffect]s
## applied to modify that value. Can also be extended with custom logic.
## [br]Note: When extending, if any of the following functions are overridden they
## MUST first call their super counterpart, unless you know what you're doing.
## [codeblock]
## super._enter_tree()
## super._ready()
## super._process(delta) # Only call when effects_process_function = PROCESS
## super._physics_process(delta) # Only call when effects_process_function = PHYSICS_PROCESS
## super._exit_tree()
## [/codeblock]
@tool
class_name Attribute extends Node

## Internal time unit used to appropriately set it to the [PauseTracker].
const INTERNAL_TIME_UNIT: AttributeUtil.TimeUnit = AttributeUtil.TimeUnit.MICROSECONDS

## Helper function currently for [method Time.get_ticks_usec], created so that
## it can be swapped to other time units if deemed necessary.
static func _get_ticks() -> int:
	return Time.get_ticks_usec()


static func _ticks_to_seconds(ticks: int) -> float:
	return ticks / 1_000_000.0


## Represents either [method get_base_value] or [method get_current_value], for use
## in tools that need to export a selectable value of an Attribute.
enum Value {
	## Represents [method get_base_value]
	BASE_VALUE = 0,
	## Represents [method get_current_value]
	CURRENT_VALUE = 1,
}

## Which _process function is used to execute effects.
enum ProcessFunction {
	## [method Node._process] is used.
	PROCESS = 0,
	## [method Node._physics_process] is used.
	PHYSICS_PROCESS = 1,
	## No processing is used.
	NONE = 99,
}

## The result of adding an [ActiveAttributeEffect] to an [Attribute].
enum AddEffectResult {
	## No attempt to add the effect to an [Attribute] was ever made.
	NEVER_ADDED = 0,
	## Successfully added.
	ADDED = 1,
	## Added to an existing [ActiveAttributeEffect] via stacking.
	STACKED = 2,
	## Blocked by an [AttributeEffectCondition], retrieve it via
	## [method get_last_blocked_by].
	BLOCKED_BY_CONDITION = 3,
	## Blocked by a condition of a BLOCKER [AttributeEffect].
	BLOCKED_BY_BLOCKER = 4,
	## Another active of the same effect is already present on the [Attribute] and 
	## stack_mode is set to DENY.
	STACK_DENIED = 5,
	## Effect is instant & can't be "added", but only applied. This does not indicate
	## if it was applied or not.
	INSTANT_CANT_ADD = 6,
}

## Determines how to sort [AttributeEffect]s who have the same priority.
enum SamePrioritySortingMethod {
	## Effects that are added are sorted [b]after[/b] effects of the same priority 
	## that previously existed.
	OLDER_FIRST,
	## Effects that are added are sorted [b]before[/b] effects of the same priority
	## that previously existed.
	NEWER_FIRST,
}

###################
## Value Signals ##
###################

## Emitted when the value returned by [method get_current_value] changes.
signal current_value_changed(prev_current_value: float)

## Emitted when [member _base_value] changes. [param active] is what caused the
## change, or null if [method set_base_value] was used directly.
signal base_value_changed(prev_base_value: float, active: ActiveAttributeEffect)

####################
## Effect Signals ##
####################

## Emitted after the [param active] was added to this [Attribute]. Not called for instant
## effects.
signal active_added(active: ActiveAttributeEffect)

## Emitted when the [param active] is applied. Only emitted for [enum AttributeEffect.Type.PERMANENT]
## effects, not for [enum AttributeEffect.Type.TEMPORARY].
signal active_applied(active: ActiveAttributeEffect)

## Emitted when the [param active] was removed. To determine if it was manual
## or due to expiration, see [method ActiveAttributeEffect.expired].
signal active_removed(active: ActiveAttributeEffect)

## Emitted when the [param active] had its stack count changed.
signal active_stack_count_changed(active: ActiveAttributeEffect, previous_stack_count: int)

## Emitted after [param blocked] was blocked from being added to
## this [Attribute] by an [AttributeEffectCondition], accessible via 
## [method ActiveAttributeEffect.get_last_blocked_by]. [param blocked_by] is the owner
## of that condition, and could (but not always in the case of BLOCKER effects) be the same
## as [param blocked].
signal active_add_blocked(blocked: ActiveAttributeEffect, blocked_by: ActiveAttributeEffect)

## Emitted after [param blocked] was blocked from being applied to
## this [Attribute] by an [AttributeEffectCondition], accessible via 
## [method ActiveAttributeEffect.get_last_blocked_by]. [param blocked_by] is the owner
## of that condition, and could (but not always in the case of BLOCKER effects) be the same
## as [param blocked].
signal active_apply_blocked(blocked: ActiveAttributeEffect, blocked_by: ActiveAttributeEffect)

## The ID of the attribute.
@export var id: StringName:
	set(_value):
		id = _value
		update_configuration_warnings()

## The base value of the attribute which permanent effects will apply to.
## [br]WARNING: Setting this directly (excluding in the editor inactivetor) can break the 
## current value, use [method set_base_value].
@export var _base_value: float:
	set(value):
		var prev_base_value: float = _base_value
		_base_value = value
		update_configuration_warnings()

@export_group("Value Validators")

## All [AttributeValueValidator]s to be executed on the base value.
@export var base_value_validators: Array[AttributeValueValidator]

## All [AttributeValueValidator]s to be executed on the current value.
@export var current_value_validators: Array[AttributeValueValidator]

@export_group("Effects")

## Whether or not [ActiveAttributeEffect]s should be allowed. If effects are not allowed,
## processing is automatically disabled.
@export var allow_effects: bool = true:
	set(value):
		allow_effects = value
		if !allow_effects:
			effects_process_function = ProcessFunction.NONE
			if !Engine.is_editor_hint():
				remove_all_effects()
		_update_processing()
		notify_property_list_changed()

## Which [ProcessFunction] is used when processing [AttributeEffect]s.
@export var effects_process_function: ProcessFunction = ProcessFunction.PROCESS:
	set(_value):
		effects_process_function = _value
		if !Engine.is_editor_hint():
			_update_processing()

## Determines how to sort effects who share the same priority.
@export var same_priority_sorting_method: SamePrioritySortingMethod:
	set(value):
		assert(Engine.is_editor_hint() || !is_node_ready(), "same_priority_sorting_method " + \
		"can not be changed at runtime.")
		same_priority_sorting_method = value

## If true, default effects are added via using [method Callable.call_deferred]
## on [method add_effects], which allows time to connect to this attribute's
## signals to be notified of the additions.
@export var defer_default_effects: bool = false

## Array of all [AttributeEffect]s applied to this [Attribute] by default. When
## applied they are NOT sorted by priority, but instead applied in their order in
## this array.
@export var _default_effects: Array[AttributeEffect] = []:
	set(value):
		_default_effects = value
		update_configuration_warnings()

## Cluster of all added [ActiveAttributeEffect]s.
@export_storage var _actives: ActiveAttributeEffectCluster

## Internally stores if 
@export_storage var _has_actives: bool = false:
	set(value):
		_has_actives = value
		_update_processing()

## Dictionary of in the format of [code]{[member AttributeEffect.id] : int}[/code] count of all 
## applied [ActiveAttributeEffect]s with that effect.
@export_storage var _effect_counts: Dictionary[StringName, int] = {}

## The [AttributeContainer] this attribute belongs to stored as a [WeakRef] for
## circular reference safety.
var _container_ref: WeakRef = weakref(null)

## The internal current value.
## [br]WARNING: Do not set this directly, it is automatically calculated.
var _current_value: float:
	set(value):
		var prev_current_value: float = _current_value
		_current_value = value
		update_configuration_warnings()

var _paused_at: int

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	assert(get_parent() is AttributeContainer, "parent not of type AttributeContainer")
	_container_ref = weakref(get_parent() as AttributeContainer)


func _ready() -> void:
	# TODO handle loading of attributes from saved data. currently applied effects
	# need their tick #s adjusted.
	if !can_process():
		_paused_at = _get_ticks()
	
	_update_processing()
	# Escape if editor
	if Engine.is_editor_hint():
		return
	
	_actives = ActiveAttributeEffectCluster.new(same_priority_sorting_method)
	_current_value = _validate_current_value(_base_value)
	
	## Find & set history
	#for child: Node in get_children():
		#if child is AttributeHistory:
			#_history = child
			#break
	
	# Handle default effects
	if allow_effects && !_default_effects.is_empty():
		if defer_default_effects:
			add_effects.call_deferred(_default_effects)
		else:
			add_effects(_default_effects, false)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	_container_ref = weakref(null)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_paused_at = _get_ticks()
	if what == NOTIFICATION_UNPAUSED:
		var unpaused_at: int = _get_ticks()
		var ticks_paused: float = _get_ticks() - _paused_at
		_actives.for_each(
			func(active: ActiveAttributeEffect) -> void:
				# If added during the pause, set process time to unpause time
				if active._tick_added_on >= _paused_at:
					active._tick_last_processed = unpaused_at
				else: # If added before pause, add time puased to process time
					active._tick_last_processed += ticks_paused
		, false)


func _process(delta: float) -> void:
	_actives.for_each(_process_active)


func _physics_process(delta: float) -> void:
	_actives.for_each(_process_active)


func _process_active(active: ActiveAttributeEffect) -> void:
	assert(active != null, "_actives has null element")
	# Skip if not added
	if !active.is_added():
		return
	
	# Store the current tick
	var current_tick: int = _get_ticks()
	
	# Get the amount of time since last process
	var seconds_since_last_process: float = _ticks_to_seconds(
	current_tick - active.get_tick_last_processed())
	
	# Add to active duration
	active._active_duration += seconds_since_last_process
	
	# Set tick last processed as this tick
	active._tick_last_processed = current_tick
	
	# Update period
	if active.get_effect().has_period():
		active.remaining_period -= seconds_since_last_process
	
	# Duration Calculations
	if active.get_effect().has_duration():
		active.remaining_duration -= seconds_since_last_process
		if active.remaining_duration <= 0.0: # Expired
			# Logic to determine if it should apply on expire
			if active.get_effect().is_apply_on_expire() \
			or (active.get_effect().is_apply_on_expire_if_period_is_zero() && active.remaining_period <= 0): 
				# Apply it
				_apply_permanent_active(active, current_tick)
			
			# Ignore apply limit here as it already expired
			
			# Remove it & go to next active
			active._expired = true
			if active.is_added():
				_remove_active(active)
			return
	
	# Remaining period < 0, apply it & reset period
	if active.get_effect().has_period() && active.remaining_period <= 0:
		# Apply it
		_apply_permanent_active(active, current_tick)
		
		# Mark it for removal if it hit apply limit
		if active.hit_apply_limit():
			# Remove from effect counts instantly so has_effect return false
			_remove_active(active)
		
		active.remaining_period += _get_modified_period(active)


func _validate_property(property: Dictionary) -> void:
	if property.name == "effects_process_function":
		if !allow_effects:
			property.usage = PROPERTY_USAGE_STORAGE
		return
	if property.name == "_default_effects":
		if !allow_effects:
			property.usage = PROPERTY_USAGE_NONE
		return


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if id.is_empty():
		warnings.append("no ID set")
	if !(get_parent() is AttributeContainer):
		warnings.append("parent not of type AttributeContainer")
	else:
		for child in get_parent().get_children():
			if child is Attribute:
				if child != self && child.id == id:
					warnings.append("Sibling Attribute (%s) has the same ID" % child.name)
	if _default_effects.has(null):
		warnings.append("_default_effects has a null element")
	
	var has_history: bool = false
	for child: Node in get_children():
		if child is AttributeHistory:
			if has_history:
				warnings.append("Multiple AttributeHistory children detected")
				break
			else:
				has_history = true
	
	return warnings


## Returns the [AttributeContainer] this [Attribute] belongs to, null if there
## is no container (which shouldn't happen with proper [Node] management).
func get_container() -> AttributeContainer:
	return _container_ref.get_ref() as AttributeContainer


## Returns the base value of this attribute.
func get_base_value() -> float:
	return _base_value


## Manually sets the base value, also updating the current value.
func set_base_value(new_base_value: float) -> void:
	var validated_new_base_value: float = _validate_base_value(new_base_value)
	if _base_value != validated_new_base_value:
		var prev_base_value: float = _base_value
		_base_value = validated_new_base_value
		base_value_changed.emit(prev_base_value, null)
		update_current_value()


## Returns the current value, which is the [member base_value] affected by
## all [AttributeEffect]s of type [enum AttributeEffect.Type.TEMPORARY]
func get_current_value() -> float:
	return _current_value


func _validate_base_value(value: float) -> float:
	var validated: float = value
	for validator: AttributeValueValidator in base_value_validators:
		validated = validator._validate(validated)
	return value


func _validate_current_value(value: float) -> float:
	var validated: float = value
	for validator: AttributeValueValidator in current_value_validators:
		validated = validator._validate(validated)
	return value


## Updates the value returned by [method get_current_value] by re-applying all
## [AttributeEffect]s of type [enum AttributeEffect.Type.TEMPORARY]. This is called
## automatically whenever base_value changes, a PERMANENT effect is applied, or
## a TEMPORARY effect is added/removed. Should be called manually if a TEMPORARY
## effect's conditions change.
func update_current_value() -> void:
	var new_current_value: AttributeUtil.Reference = AttributeUtil.Reference.new(_base_value)
	_actives.temporaries.for_each(
		func(active: ActiveAttributeEffect) -> void:
			# Skip if not added, is expired, or has no value
			if !active.is_added() || active.is_expired() || !active.get_effect().has_value:
				return
			
			# Set pending values
			active._pending_prior_attribute_value = new_current_value.ref
			active._pending_effect_value = _get_modified_value(active)
			active._pending_raw_attribute_value = active.get_effect().apply_calculator(_base_value, 
			new_current_value.ref, active._last_effect_value)
			active._pending_final_attribute_value = _validate_current_value(active._pending_raw_attribute_value)
			
			# Test apply conditions & ensure still added after testing them.
			if !_test_apply_conditions(active) || !active.is_added():
				active._clear_pending_values()
				return
			
			active._last_effect_value = active._pending_effect_value
			active._last_prior_attribute_value = _current_value
			active._last_raw_attribute_value = active._pending_raw_attribute_value
			active._last_final_attribute_value = active._pending_final_attribute_value
			active._clear_pending_values()
			new_current_value.ref = active._last_set_attribute_value
	) 
	
	if _current_value != new_current_value.ref:
		var prev_current_value: float = _current_value
		_current_value = new_current_value.ref
		current_value_changed.emit(prev_current_value)


## Returns a new [Array] (safe to mutate) of the current [ActiveAttributeEffect]s.
## The actives themselves are NOT duplicated.
## [br]If [param ignore_expired] is true, actives that are expired OR hit their apply limit
## are ignored, otherwise they are included (not recommended for most cases).
func get_actives(ignore_expired: bool = true) -> Array[ActiveAttributeEffect]:
	if ignore_expired:
		return _actives._data_array.filter(
			func (active: ActiveAttributeEffect) -> bool:
				return !ignore_expired || (!active.is_expired() && !active.hit_apply_limit())
		)
	return _actives.duplicate_array()


## Returns a new [Array] of every [member AttributeEffect.id] currently active on this
## attribute. Does not contain duplicates, even if multiple [ActiveAttributeEffect]s of the same
## [AttributeEffect] are added.
func get_effect_ids() -> Array[StringName]:
	return _effect_counts.keys()


### Returns a new [Dictionary] (safe to mutate) of all current [AttributeEffect]s as keys,
### and the integer count of the amount of [ActiveAttributeEffect]s of each effect as values.
### The effects themselves are NOT duplicated.
### [br]NOTE: If this is called mid process, expired effects & effects that have hit their
### apply limit are internally still present as they're removed at the end of the frame, 
### but they will not show up in any publicly facing functions including this one.
#func get_effects_with_counts() -> Dictionary:
	#return _effect_counts.duplicate(false)


## Returns true if the [param effect] is present and has one or more [ActiveAttributeEffect]s
## applied to this [Attribute], false if not. Does not account for any actives that are
## expired & not yet removed (during the processing).
func has_effect(effect: AttributeEffect) -> bool:
	assert(effect != null, "effect is null")
	return _effect_counts.has(effect.id)


## Returns the total amount of [ActiveAttributeEffect]s whose effect is [param effect].
## Highly efficient as it simply uses [method Dictionary.get] on an internally managed dictionary.
func get_effect_count(effect: AttributeEffect) -> int:
	assert(effect != null, "effect is null")
	return _effect_counts.get(effect.id, 0)


## Returns true if [param active] is currently applied to this [Attribute], false if not.
func has_active(active: ActiveAttributeEffect) -> bool:
	assert(active != null, "active is null")
	return active.is_added() && _actives.has(active)


## Searches through all active [ActiveAttributeEffect]s and returns a new [Array] of all actives
## whose [method AttributEffectactive.get_effect] equals [param effect].
## [br]If [param ignore_expired] is true, actives that are expired OR hit their apply limit
## are ignored, otherwise they are included (not recommended for most cases).
func find_actives_by_effect(effect: AttributeEffect, ignore_expired: bool = true) -> Array[ActiveAttributeEffect]:
	return _actives.find_all(
		func(active: ActiveAttributeEffect) -> bool:
			if ignore_expired && active.is_expired():
				return false
			return active._effect == effect
	)


## Searches through all active [ActiveAttributeEffect]s and returns the first active
## whose [method AttributEffectactive.get_effect] equals [param effect]. Returns null
## if there is no active of [param effect]. Useful when you know that the [param effect]'s
## stack mode is COMBINE, DENY, or DENY_ERROR as in those cases there can only 
## be one instance of the effect.
## [br]If [param ignore_expired] is true, actives that are expired OR hit their apply limit
## are ignored, otherwise they are included (not recommended for most cases).
func find_first_active_by_effect(effect: AttributeEffect, ignore_expired: bool = true) -> ActiveAttributeEffect:
	return _actives.find_first(
		func(active: ActiveAttributeEffect) -> bool:
			if ignore_expired && active.is_expired():
				return false
			return active._effect == effect
	)


## Creates an [ActiveAttributeEffect] from the [param effect] via [method AttriubteEffect.to_active]
## and then calls [method add_actives]
func add_effect(effect: AttributeEffect) -> void:
	assert(allow_effects, "allow_effects is false for %s" % self)
	add_effects([effect], false)


## Creates an [ActiveAttributeEffect] from each of the [param effects] via 
## [method AttriubteEffect.to_active] and then calls [method add_actives].
## [param sort_by_priority] determines what order the activeified effects should be applied in (if
## any are to be applied instantly). If true, they are sorted by their [member AttributeEffect.priority],
## if false they are applied in the order of the activeified [param effects] array.
func add_effects(effects: Array[AttributeEffect], sort_by_priority: bool = true) -> void:
	assert(allow_effects, "allow_effects is false for %s" % self)
	assert(!effects.has(null), "effects has null element")
	var actives: Array[ActiveAttributeEffect] = []
	for effect: AttributeEffect in effects:
		actives.append(effect.to_active())
	add_actives(actives, sort_by_priority)


## Adds [param active] to a new [Array], then calls [method add_actives]
func add_active(active: ActiveAttributeEffect) -> void:
	assert(allow_effects, "allow_effects is false for %s" % self)
	assert(active != null, "active is null")
	add_actives([active], false)


## Adds (& possibly applies) of each of the [param actives]. Can result in immediate
## changes to the base value & current value, depending on the provided [param actives]. 
## [param sort_by_priority] determines what order the activeified actives should be applied in (if
## any are to be applied instantly). If true, they are sorted by their [member AttributeEffect.priority],
## if false they are applied in the order of the activeified [param actives] array.
## [br][b]There are multiple considerations when calling this function:[/b]
## [br]  - If a active has stack_mode COMBINE, it is stacked to the existing active of the same 
## [AttributeEffect], and thus not added. The new stack count is the existing's + the new active's
## stack count.
## [br]  - If a active is PERMANENT, it is applied when it is added unless the active has an initial period.
## [br]  - If TEMPORARY, it is not applied, however the current_value is updated instantly.
## [br]  - If INSTANT, it is not added, only applied.
## [br]  - actives are initialized unless already initialized or are stacked instead of added.
func add_actives(actives: Array[ActiveAttributeEffect], sort_by_priority: bool = true) -> void:
	assert(allow_effects, "allow_effects is false for %s" % self)
	assert(!actives.has(null), "actives has null element")
	
	var current_tick: int = _get_ticks()
	
	# Define array to use
	var actives_to_add: Array[ActiveAttributeEffect]
	actives_to_add.assign(actives)
	
	# Duplicate & sort array if sort_by_priority is true
	if sort_by_priority:
		actives_to_add.sort_custom(_actives._sort_new_before_other)
	
	# Iterate actives to apply
	for active: ActiveAttributeEffect in actives_to_add:
		assert(!_actives.has(active), "%s already added to this attribute or another" % active)
		
		# Throw error if active's effect exists & has StackMode.DENY_ERROR
		assert(active.get_effect().stack_mode != AttributeEffect.StackMode.DENY_ERROR or \
		!has_effect(active.get_effect()), 
		"active (%s)'s effect stack_mode == DENY_ERROR but stacking was attempted on attribute %s" \
		% [active, self])
		
		# Effect is instant, ignore other logic & apply it
		if active.get_effect().is_instant():
			active._last_add_result = AddEffectResult.INSTANT_CANT_ADD
			_apply_permanent_active(active, current_tick)
			continue
		
		# Do not stack if DENY or DENY_ERROR & effect already exists
		if (active.get_effect().stack_mode == AttributeEffect.StackMode.DENY or \
		active.get_effect().stack_mode == AttributeEffect.StackMode.DENY_ERROR) and \
		has_effect(active.get_effect()):
			active._last_add_result = AddEffectResult.STACK_DENIED
			continue
		
		# Check add conditions & blockers
		if !_test_add_conditions(active):
			continue
		
		# Handle COMBINE stacking (only if a active of the same effect already exists)
		if active.get_effect().stack_mode == AttributeEffect.StackMode.COMBINE \
		and has_effect(active.get_effect()):
			var existing: ActiveAttributeEffect = find_first_active_by_effect(active.get_effect())
			assert(existing != null, ("existing is null, but has_effect returned true " + \
			"for active %s") % active)
			active._last_add_result = AddEffectResult.STACKED
			_add_to_stack(active, active.get_stack_count())
			# Update current value if a temporary active is added
			# TODO Determine if I should apply here
			if active.get_effect().is_temporary() && active.get_effect().has_value:
				update_current_value()
			continue
		
		# Initialize if not done so
		if !active.is_initialized():
			_initialize_active(active)
		
		# Ensure duration is valid
		assert(!active.get_effect().has_duration() || active.remaining_duration > 0.0,
		"active (%s) has a remaining_duration <= 0.0" % active)
		
		# Run pre_add callbacks
		_run_callbacks(active, AttributeEffectCallback._Function.PRE_ADD)
		
		# At this point it can be added
		active._last_add_result = AddEffectResult.ADDED
		active._tick_added_on = current_tick
		active._tick_last_processed = current_tick
		
		# Add to array
		_actives.add(active)
		
		# Add to _effect_counts
		var new_count: int = _effect_counts.get(active.get_effect().id, 0) + 1
		_effect_counts[active.get_effect().id] = new_count
		
		# Run callbacks & emit signal
		_run_callbacks(active, AttributeEffectCallback._Function.ADDED)
		if active.get_effect().should_emit_added_signal():
			active_added.emit(active)
		
		# Update current value if a temporary active is added & has value
		if active.get_effect().is_temporary() && active.get_effect().has_value:
			update_current_value()
			continue
		
		# Apply it if initial period <= 0.0
		if active.get_effect().has_period() && active.remaining_period <= 0.0:
			_apply_permanent_active(active, current_tick)
			
			# Remove if it hit apply limit
			if active.hit_apply_limit():
				_remove_active(active)
			# Update period
			else:
				active.remaining_period += _get_modified_period(active)


## Removes all [ActiveAttributeEffect]s whose effect equals [param effect].
## Returns the number of [ActiveAttributeEffect]s removed.
func remove_effect(effect: AttributeEffect) -> int:
	var removed: AttributeUtil.Reference = AttributeUtil.Reference.new(0)
	_actives.for_each(
		func(active: ActiveAttributeEffect) -> void:
			if active.get_effect() == effect:
				_remove_active(active)
				removed.ref += 1
	)
	return removed.ref


## Removes all [ActiveAttributeEffect]s whose effect is present in [param effects]. 
## Returns the number of [ActiveAttributeEffect]s removed.
func remove_effects(effects: Array[AttributeEffect]) -> int:
	var removed: AttributeUtil.Reference = AttributeUtil.Reference.new(0)
	_actives.for_each(
		func(active: ActiveAttributeEffect) -> void:
			if effects.has(active.get_effect()):
				_remove_active(active)
				removed.ref += 1
	)
	return removed.ref


## Removes all [param actives], returning the number of [ActiveAttributeEffect] 
## that were present & removed.
func remove_actives(actives: Array[ActiveAttributeEffect]) -> int:
	var removed: int = 0
	for active: ActiveAttributeEffect in actives:
		if remove_active(active):
			removed += 1
	return removed


## Removes the [param active], returning true if removed, false if not.
func remove_active(active: ActiveAttributeEffect) -> bool:
	if active == null || !has_active(active):
		return false
	_remove_active(active)
	return true


func _remove_active(active: ActiveAttributeEffect) -> void:
	assert(active != null, "active is null")
	assert(_actives.has(active), "(%s) not added to _actives" % active)
	_run_callbacks(active, AttributeEffectCallback._Function.PRE_REMOVE)
	_actives.erase(active)
	_has_actives = !_actives.is_empty()
	if _effect_counts.has(active.get_effect().id):
		var new_count: int = _effect_counts[active.get_effect().id] - 1
		if new_count <= 0:
			_effect_counts.erase(active.get_effect().id)
		else:
			_effect_counts[active.get_effect().id] = new_count
	_run_callbacks(active, AttributeEffectCallback._Function.REMOVED)
	if active.get_effect().should_emit_removed_signal():
		active_removed.emit(active)


## Removes all [ActiveAttributeEffect]s from this attribute.
func remove_all_effects() -> void:
	var to_remove: Array[ActiveAttributeEffect] = _actives.duplicate_array()
	for active: ActiveAttributeEffect in to_remove:
		_run_callbacks(active, AttributeEffectCallback._Function.PRE_REMOVE)
	_actives.clear()
	_effect_counts.clear()
	_has_actives = false
	update_current_value()
	for active: ActiveAttributeEffect in to_remove:
		_run_callbacks(active, AttributeEffectCallback._Function.REMOVED)
		if active.get_effect().should_emit_removed_signal():
			active_removed.emit(active)


## Tests the addition of [param active] by evaluating it's potential add [AttributeEffectCondition]s
## and that of all BLOCKER type effects. Returns true if all conditions were met, false if not.
## Emits signals which can result in mutations, considered unsafe.
func _test_add_conditions(active: ActiveAttributeEffect) -> bool:
	# Check active's own conditions
	if active.get_effect().has_add_conditions():
		var blocking_condition: AttributeEffectCondition = _test_condition_array(active, active.get_effect().add_conditions)
		if blocking_condition != null:
			active._last_add_result = AddEffectResult.BLOCKED_BY_CONDITION
			active._last_blocked_by = blocking_condition.ref
			if blocking_condition.emit_blocked_signal:
				active_add_blocked.emit(blocking_condition, active)
			return false
	
	# Iterate BLOCKER effects
	if !_actives.blockers.is_empty():
		var blocking_condition: AttributeUtil.Reference = AttributeUtil.Reference.new(null)
		var blocking_source: AttributeUtil.Reference = AttributeUtil.Reference.new(null)
		_actives.blockers.for_each(
			func(blocker: ActiveAttributeEffect) -> void:
				# Ignore expired - they may still appear in the array at this point in time
				if !blocker.is_added() || blocker.is_expired():
					return
				
				blocking_condition.ref = _test_condition_array(active, blocker.get_effect().add_blockers)
				
				if blocking_condition.ref != null:
					blocking_source.ref = blocker
					_actives.break_for_each()
		, false) # Unsafe iteration (array is not mutated)
		if blocking_condition.ref != null:
			active._last_add_result = AddEffectResult.BLOCKED_BY_CONDITION
			active._last_blocked_by = blocking_condition.ref
			if blocking_condition.ref.emit_blocked_signal:
				active_add_blocked.emit(blocking_condition, blocking_source.ref)
			return false
	
	return true



## Tests the applying of [param active] by evaluating it's potential apply [AttributeEffectCondition]s
## and that of all BLOCKER type effects. Returns true if all conditions were met, false if not.
## Emits signals which can result in mutations, considered unsafe.
# TODO block mutation of actives in signals emitted from this method, it is not safe.
func _test_apply_conditions(active: ActiveAttributeEffect) -> bool:
	# Check active's own conditions
	if active.get_effect().has_apply_conditions():
		var blocking_condition: AttributeEffectCondition = _test_condition_array(active, active.get_effect().apply_conditions)
		if blocking_condition != null:
			active._last_blocked_by = blocking_condition.ref
			if blocking_condition.emit_blocked_signal:
				active_apply_blocked.emit(blocking_condition, active)
			return false
	
	# Iterate BLOCKER effects
	if !_actives.blockers.is_empty():
		var blocking_condition: AttributeUtil.Reference = AttributeUtil.Reference.new(null)
		var blocking_source: AttributeUtil.Reference = AttributeUtil.Reference.new(null)
		_actives.blockers.for_each(
			func(blocker: ActiveAttributeEffect) -> void:
				# Ignore expired - they may still appear in the array at this point in time
				if !blocker.is_added() || blocker.is_expired():
					return
				
				blocking_condition.ref = _test_condition_array(active, blocker.get_effect().apply_blockers)
				
				if blocking_condition.ref != null:
					blocking_source.ref = blocker
					_actives.break_for_each()
		, false) # Unsafe iteration (array is not mutated)
		if blocking_condition.ref != null:
			active._last_blocked_by = blocking_condition.ref
			if blocking_condition.ref.emit_blocked_signal:
				active_apply_blocked.emit(blocking_condition, blocking_source.ref)
			return false
	
	return true


## Tests the [param conditions] on [param active_to_test]. Returns the [AttributeEffectCondition] that
## was not met, or null if all were met. 
func _test_condition_array(active_to_test: ActiveAttributeEffect, 
conditions: Array[AttributeEffectCondition]) -> AttributeEffectCondition:
	for condition: AttributeEffectCondition in conditions:
		if !condition.meets_condition(self, active_to_test):
			return condition
	return null


func _update_processing() -> void:
	var can_process: bool = !Engine.is_editor_hint() && _has_actives && allow_effects
	set_process(can_process && effects_process_function == ProcessFunction.PROCESS)
	set_physics_process(can_process && effects_process_function == ProcessFunction.PHYSICS_PROCESS)


func _get_modified_value(active: ActiveAttributeEffect) -> float:
	var modified_value: AttributeUtil.Reference = AttributeUtil.Reference.new(\
	active.get_effect().value.get_modified(self, active))
	
	_actives.modifiers.for_each(
		func(modifier: ActiveAttributeEffect) -> void:
			if modifier.is_added() && !modifier.is_expired():
				modified_value.ref = modifier.get_effect().value_modifiers.modify_value(modified_value.ref, self, active)
	, false) # Unsafe iteration as mutations won't be made during it.
	
	return modified_value.ref


func _get_modified_period(active: ActiveAttributeEffect) -> float:
	var modified_period: AttributeUtil.Reference = AttributeUtil.Reference.new(\
	active.get_effect().period_in_seconds.get_modified(self, active))
	
	_actives.modifiers.for_each(
		func(modifier: ActiveAttributeEffect) -> void:
			if modifier.is_added() && !modifier.is_expired():
				modified_period.ref = modifier.get_effect().period_modifiers.modify_period(modified_period.ref, self, active)
	, false) # Unsafe iteration as mutations won't be made during it.
	
	return modified_period.ref


func _get_modified_duration(active: ActiveAttributeEffect) -> float:
	var modified_duration: AttributeUtil.Reference = AttributeUtil.Reference.new(\
	active.get_effect().duration_in_seconds.get_modified(self, active))
	
	_actives.modifiers.for_each(
		func(modifier: ActiveAttributeEffect) -> void:
			if modifier.is_added() && !modifier.is_expired():
				modified_duration.ref = modifier.get_effect().duration_modifiers.modify_duration(modified_duration.ref, self, active)
	, false) # Unsafe iteration as mutations won't be made during it.
	
	return modified_duration.ref


func _initialize_active(active: ActiveAttributeEffect) -> void:
	assert(!active.is_initialized(), "active (%s) already initialized" % active)
	if active.get_effect().has_period() && active.get_effect().initial_period:
		active.remaining_period = _get_modified_period(active)
	if active.get_effect().has_duration():
		active.remaining_duration = _get_modified_duration(active)
	active._initialized = true


## Applies the [param active]. Returns true if it should be removed (hit apply limit),
## false if not. Does not update the current value, that must be done manually after.
## Emits signals that could result in array mutations, so considered unsafe.
func _apply_permanent_active(active: ActiveAttributeEffect, current_tick: int) -> void:
	# Set prior attribute value value
	active._pending_prior_attribute_value = _base_value
	
	# Get the modified value
	active._pending_effect_value = _get_modified_value(active)
	
	# Calculate the attribute's new value
	active._pending_raw_attribute_value = active.get_effect().apply_calculator(_base_value, 
	_current_value, active._pending_effect_value)
	
	# Validate the attribute's value
	active._pending_final_attribute_value = _validate_base_value(active._pending_raw_attribute_value)
	
	# Check apply conditions & ensure still added after testing them
	if !_test_apply_conditions(active) || !active.is_added():
		active._clear_pending_values()
		return
	
	# Set "last" values
	active._last_effect_value = active._pending_effect_value
	active._last_prior_attribute_value = _base_value
	active._last_raw_attribute_value = active._pending_raw_attribute_value
	active._last_final_attribute_value = active._pending_final_attribute_value
	
	# Clear pending value
	active._clear_pending_values()
	
	# Increase apply count
	active._apply_count += 1
	
	# Set tick last applied
	active._tick_last_applied = current_tick
	
	## Add to history - TODO reimplement
	#if has_history() && active.get_effect().should_log_history():
		#_history._add_to_history(active) 
	
	# Update base value
	_base_value = active._last_final_attribute_value
	if _base_value != active._last_prior_attribute_value:
		base_value_changed.emit(active._last_prior_attribute_value, active)
	
	# Update current value if base value changed
	if _base_value != active._last_prior_attribute_value:
		update_current_value()
	
	# Emit signals
	_run_callbacks(active, AttributeEffectCallback._Function.APPLIED)
	if active.get_effect().should_emit_applied_signal():
		active_applied.emit(active)


# Adds [param amount] to the effect stack. This effect must be stackable
# (see [method is_stackable]) and [param amount] must be > 0.
# [br]Automatically emits [signal effect_stack_count_changed].
func _add_to_stack(active: ActiveAttributeEffect, amount: int = 1) -> void:
	assert(active.get_effect().is_stackable(), "active (%s) not stackable" % active)
	assert(amount > 0, "amount(%s) <= 0" % amount)
	
	var previous_stack_count: int = active._stack_count
	active._stack_count += amount
	_run_stack_callbacks(active, previous_stack_count)
	active_stack_count_changed.emit(active, previous_stack_count)


# Removes [param amount] from the effect stack. This effect must be stackable
# (see [method is_stackable]), [param amount] must be > 0, and 
# [method get_stack_count] - [param amount] must be > 0.
# [br]Automatically emits [signal effect_stack_count_changed].
func _remove_from_stack(active: ActiveAttributeEffect, amount: int = 1) -> void:
	assert(active.get_effect().is_stackable(), "active (%s) not stackable" % active)
	assert(amount > 0, "amount(%s) <= 0" % amount)
	assert(active._stack_count - amount > 0, "amount(%s) - active._stack_count(%s) <= 0 fopr active (%s)"\
		% [amount, active._stack_count, active])
	
	var previous_stack_count: int = active._stack_count
	active._stack_count -= amount
	_run_stack_callbacks(active, previous_stack_count)
	active_stack_count_changed.emit(active, previous_stack_count)


# Runs the callback [param _function] on all [AttributeEffectCallback]s who have
# implemented that function.
func _run_callbacks(active: ActiveAttributeEffect, _function: AttributeEffectCallback._Function) -> void:
	if !AttributeEffectCallback._can_run(_function, active.get_effect()):
		return
	var function_name: String = AttributeEffectCallback._function_names[_function]
	for callback: AttributeEffectCallback in active.get_effect()._callbacks_by_function.get(_function):
		callback.call(function_name, self, active)


func _run_stack_callbacks(active: ActiveAttributeEffect, previous_stack_count: int) -> void:
	var function_name: String = AttributeEffectCallback._function_names\
	[AttributeEffectCallback._Function.STACK_CHANGED]
	
	for callback: AttributeEffectCallback in active.get_effect()._callbacks_by_function\
	.get(AttributeEffectCallback._Function.STACK_CHANGED):
		callback.call(function_name, self, active, previous_stack_count)


func _to_string() -> String:
	return "Attribute(id=%s)" % id

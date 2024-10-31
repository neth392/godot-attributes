## Represents a floating point value which can be modified by [AttributeEffect]s. Also
## acts as a controller of each applied [ActiveAttributeEffect] (the living version of an
## [AttributeEffect]), responsible for the logic behind processing each effect.
# NOTE: Yes this class is quite the spaghetti code mess, maybe I'll improve it one day
# but as long as it works & is efficient I'm fine with it for now.
@tool
@icon("res://addons/godot-attributes/assets/attribute_icon.svg")
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
	SUCCESS = 1,
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

#####################
## Attribute Event ##
#####################

## Emitted when any change to this [Attribute] is made, such as the base and/or current value
## changing, or an [ActiveAttributeEffect] was added, applied, and/or removed. The
## [param attribute_event] contains all of the information related to what changes took
## place since the last event was emitted. Unlike signals prefixed with [i]monitor_[/i], 
## connections to this signal can safely invoke their own changes on this [Attribute] 
## without breaking the internal logic or event ordering as this event is always 
## emitted when it is safe to do so. It is also more reliable than the monitor signals
## due to the preserved ordering.
signal event_occurred(attribute_event: AttributeEvent)

#####################
## Monitor Signals ##
#####################

## Emitted when the value returned by [method get_current_value] changes.[br]
## WARNING: Any changes made to this [Attribute] when handling this signal will
## result in an error thrown unless call_deferred is used. If you wish to modify 
## the [Attribute] while handling this, use [signal event_occurred].
signal monitor_current_value_changed(prev_current_value: float)

## Emitted when [member _base_value] changes. [param active] is what caused the
## change, or null if [method set_base_value] was used directly.[br]
## WARNING: Any changes made to this [Attribute] when handling this signal will
## result in an error thrown. If you wish to modify the [Attribute] during this signal,
## use [signal event_occurred] instead & check [method AttributeEvent.base_value_changed].
signal monitor_base_value_changed(prev_base_value: float, active: ActiveAttributeEffect)

## Emitted after the [param active] was added to this [Attribute]. Not called for instant
## effects.[br]
## WARNING: Any changes made to this [Attribute] when handling this signal will
## result in an error thrown. If you wish to modify the [Attribute] during this signal,
## use [signal event_occurred] instead & check [method AttributeEvent.active_added].
signal monitor_active_added(active: ActiveAttributeEffect)

## Emitted when the [param active] is applied. Only emitted for [enum AttributeEffect.Type.PERMANENT]
## effects, not for [enum AttributeEffect.Type.TEMPORARY].[br]
## WARNING: Any changes made to this [Attribute] when handling this signal will
## result in an error thrown. If you wish to modify the [Attribute] during this signal,
## use [signal event_occurred] instead & check [method AttributeEvent.active_applied].
signal monitor_active_applied(active: ActiveAttributeEffect)

## Emitted when the [param active] was removed. To determine if it was manual
## or due to expiration, see [method ActiveAttributeEffect.expired].[br]
## WARNING: Any changes made to this [Attribute] when handling this signal will
## result in an error thrown. If you wish to modify the [Attribute] during this signal,
## use [signal event_occurred] instead & check [method AttributeEvent.active_removed].
signal monitor_active_removed(active: ActiveAttributeEffect)

## Emitted when the [param active] had its stack count changed.[br]
## WARNING: Any changes made to this [Attribute] when handling this signal will
## result in an error thrown. If you wish to modify the [Attribute] during this signal,
## use [signal event_occurred] instead & check [method AttributeEvent.active_stack_count_changed].
signal monitor_active_stack_count_changed(active: ActiveAttributeEffect, previous_stack_count: int)

## Emitted after [param blocked] was blocked from being added to
## this [Attribute] by an [AttributeEffectCondition], accessible via 
## [method ActiveAttributeEffect.get_last_blocked_by]. [param blocked_by] is the owner
## of that condition, and could (but not always in the case of BLOCKER effects) be the same
## as [param blocked].[br]
## WARNING: Any changes made to this [Attribute] when handling this signal will
## result in an error thrown. If you wish to modify the [Attribute] during this signal,
## use [signal event_occurred] instead & check [method AttributeEvent.active_add_blocked].
signal monitor_active_add_blocked(blocked: ActiveAttributeEffect)

## Emitted after [param blocked] was blocked from being applied to
## this [Attribute] by an [AttributeEffectCondition], accessible via 
## [method ActiveAttributeEffect.get_last_blocked_by].
signal monitor_active_apply_blocked(blocked: ActiveAttributeEffect)

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
		if Engine.is_editor_hint():
			var validated: float = _validate_value(value, _base_value_validators)
			if value != validated:
				push_warning("Inputted _base_value was validated by _base_value_validators")
			_base_value = validated
		else:
			_base_value = value
		update_configuration_warnings()
		notify_property_list_changed()

## Displays [method get_current_value] in the Editor Inspector. No functionality.
@export var _current_value_display: float:
	set(value):
		assert(false, "this is a display only property for the Edity Inspector")
	get():
		# TODO possibly implement default effects?
		return _validate_value(_base_value, _current_value_validators)

@export_group("Value Validators")

## All [AttributeValueValidator]s to be executed on the base value.
@export var _base_value_validators: Array[AttributeValueValidator]:
	set(value):
		_base_value_validators = value
		assert(Engine.is_editor_hint() ||!_base_value_validators.has(null),
		"_base_value_validators has an null element")
		if Engine.is_editor_hint(): # Update base value in the editor
			_base_value = _base_value
		update_configuration_warnings()
		notify_property_list_changed()

## All [AttributeValueValidator]s to be executed on the current value.
@export var _current_value_validators: Array[AttributeValueValidator]:
	set(value):
		_current_value_validators = value
		assert(Engine.is_editor_hint() ||!_current_value_validators.has(null),
		"_current_value_validators has an null element")
		if Engine.is_editor_hint(): # Update base value in the editor
			_base_value = _base_value
		update_configuration_warnings()
		notify_property_list_changed()

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

## How many frames should be skipped in between each _process call. For attributes
## that may have many effects it is recommended to increase this from the default value of 0.
## The greater the frames skipped the more chance for effects to be present longer than
## their set duration, or longer time between applying of effects than their set periods, so only
## use where precision doesn't have to be exact.
@export_range(0, 100, 1, "or_greater", "hide_slider") var skip_process_frames: int = 0:
	set(_value):
		assert(_value >= 0, "skip_process_frames must be >= 0, but was set to %s" % _value)
		skip_process_frames = _value
		_frame_skipping_enabled = skip_process_frames > 0

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
## this array. Can be set/mutated via code but must be done before this node is added 
## to the tree.
@export var default_effects: Array[AttributeEffect] = []:
	set(value):
		default_effects = value
		update_configuration_warnings()

# Cluster of all added [ActiveAttributeEffect]s.
@export_storage var _actives: ActiveAttributeEffectCluster

# Internally stores if there are any [ActiveAttributeEffect]s currently applied.
# When set processing is updated, disabling it when no effects are applied to
# help performance.
@export_storage var _has_processable_actives: bool = false:
	set(value):
		_has_processable_actives = value
		_update_processing()

# Dictionary of in the format of [code]{[member AttributeEffect.id] : int}[/code] count of all 
# applied [ActiveAttributeEffect]s with that effect.
@export_storage var _effect_counts: Dictionary[StringName, int]

@export_storage var _derived_modifier_storage: Dictionary[String, Attribute]

# The [AttributeContainer] this attribute belongs to stored as a [WeakRef] for
# circular reference safety.
var _container_ref: WeakRef = weakref(null)

## The internal current value.
## [br]WARNING: Do not set this directly, it is automatically calculated.
var _current_value: float:
	set(value):
		var prev_current_value: float = _current_value
		_current_value = value
		update_configuration_warnings()

var _paused_at: int

# Internal flag to prevent mutations to this attribute while a signal prefixed with "monitor_"
# is currently being emitted. Used to prevent logic-breaking changes from code executed outside
# of this class.
var _in_monitor_signal_or_hook: bool = false

var _frame_skipping_enabled: bool = false
var _skipped_frames: int = 0

###################
## Tree Handling ##
###################

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	assert(get_parent() is AttributeContainer, "parent not of type AttributeContainer")
	_container_ref = weakref(get_parent() as AttributeContainer)


func _ready() -> void:
	# TODO handle loading of attributes from saved data. currently applied effects
	# need their tick #s adjusted. Also account for if paused at time of save.
	if !can_process():
		_paused_at = _get_ticks()
	
	_update_processing()
	# Escape if editor
	if Engine.is_editor_hint():
		return
	
	_actives = ActiveAttributeEffectCluster.new(same_priority_sorting_method)
	_current_value = _validate_value(_base_value, _current_value_validators)
	
	# Handle default effects
	if allow_effects && !default_effects.is_empty():
		if defer_default_effects:
			add_effects.call_deferred(default_effects)
		else:
			add_effects(default_effects, false)


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
		_actives.for_each_block_mutations(
			func(active: ActiveAttributeEffect) -> void:
				# If added during the pause, set process time to unpause time
				if active._tick_added_on >= _paused_at:
					active._tick_last_processed = unpaused_at
				else: # If added before pause, add time puased to process time
					active._tick_last_processed += ticks_paused
		)


##################
## Editor Tools ##
##################

func _validate_property(property: Dictionary) -> void:
	if property.name == "effects_process_function":
		if !allow_effects:
			property.usage = PROPERTY_USAGE_STORAGE
		return
	if property.name == "_default_effects":
		if !allow_effects:
			property.usage = PROPERTY_USAGE_NONE
		return
	if property.name == "_current_value_display":
		property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY
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
	if default_effects.has(null):
		warnings.append("_default_effects has a null element")
	
	if _base_value_validators.has(null):
		warnings.append("_base_value_validators has a null element")
	
	if _current_value_validators.has(null):
		warnings.append("_base_value_validators has a null element")
	
	return warnings


func _to_string() -> String:
	return "Attribute(id=%s)" % id


##############################
## Active Effect Processing ##
##############################


func _process(delta: float) -> void:
	if _frame_skipping_enabled:
		if _skipped_frames < skip_process_frames:
			_skipped_frames += 1
			return
		_skipped_frames = 0
	_actives.processing_required.for_each_allow_mutations(_process_active)


func _physics_process(delta: float) -> void:
	if _frame_skipping_enabled:
		if _skipped_frames < skip_process_frames:
			_skipped_frames += 1
			return
		_skipped_frames = 0
	_actives.processing_required.for_each_allow_mutations(_process_active)


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
	var period_expired: bool = false
	if active.get_effect().has_period():
		active._remaining_period -= seconds_since_last_process
		period_expired = active._remaining_period <= 0.0
	
	# Update duration
	var duration_expired: bool = false
	if active.get_effect().has_duration():
		active._remaining_duration -= seconds_since_last_process
		duration_expired = active._remaining_duration <= 0.0
	
	# Do not continue processing if period & duration have not expired
	# Using this to avoid constructing a new AttributeEvent unless it will be used
	if !duration_expired && !period_expired:
		return
	
	# At this point an event will be thrown as the period and/or duration has expired
	var event: AttributeEvent = AttributeEvent.new(self, active)
	event._active_effect = active
	
	# Handle duration expiring
	if duration_expired:
		# Apply it if apply on expire, or apply if apply on expire if period is zero
		if active.get_effect().apply_on_expire \
		or (period_expired && active.get_effect().apply_on_expire_if_period_is_zero): 
			# Apply it
			_apply_permanent_active(active, current_tick, event)
		
		# Remove it
		active._expired = true
		if active.is_added():
			_remove_active(active, event)
		
	# Handle period expiring if duration didn't expire
	elif period_expired:
		# Apply it
		_apply_permanent_active(active, current_tick, event)
		
		# Mark it for removal if it hit apply limit
		if active.hit_apply_limit():
			active._is_applying = false
			# Remove from effect counts instantly so has_effect return false
			_remove_active(active, event)
			
		# Otherwise reset the period
		else:
			# Update period
			active._remaining_period += AttributeModifiedValueGetter.period().get_modified(self, active)
	# This should never trigger, but just to be sure assert such
	else:
		assert(false, "duration_expired or period_expired are both false somehow")
	
	# Emit the event
	event_occurred.emit(event)

## Returns the [AttributeContainer] this [Attribute] belongs to, null if there
## is no container (which shouldn't happen with proper [Node] management).
func get_container() -> AttributeContainer:
	return _container_ref.get_ref() as AttributeContainer


##########################
## Base & Current Value ##
##########################


func _validate_value(value: float, validators: Array[AttributeValueValidator]) -> float:
	var validated: float = value
	for validator: AttributeValueValidator in validators:
		if validator != null:
			validated = validator._validate(validated)
	return validated


## Returns the base value of this attribute.
func get_base_value() -> float:
	return _base_value


## Manually sets the base value to [param new_base_value]. The new value is first
## validated by all of the [member base_value_validators]. If the resulting value
## is different than the current base value, the base value is updated along with
## the current value, and true is returned. If the new value is the same as the current
## value, nothing occurs and false is returned.
func set_base_value(new_base_value: float) -> bool:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	
	# Validate the new base value
	var validated_new_base_value: float = _validate_value(new_base_value, _base_value_validators)
	if _base_value == validated_new_base_value:
		return false
	
	# Create new event
	var event: AttributeEvent = AttributeEvent.new(self)
	_set_base_value_pre_validated(new_base_value, event)
	return true


func _set_base_value_pre_validated(validated_new_base_value: float, event: AttributeEvent) -> void:
	# Check if it differs, if not return false
	if _base_value == validated_new_base_value:
		return
	
	# Set new base value
	_base_value = validated_new_base_value
	event._new_base_value = _base_value
	
	# Emit monitor signal
	_in_monitor_signal_or_hook = true
	monitor_base_value_changed.emit(event._prev_base_value, null)
	_in_monitor_signal_or_hook = false
	
	# Update the current value
	_update_current_value(event)


## Returns the current value, which is the [member base_value] affected by
## all [AttributeEffect]s of type [enum AttributeEffect.Type.TEMPORARY]
func get_current_value() -> float:
	return _current_value


## Updates the value returned by [method get_current_value] by re-applying all
## [AttributeEffect]s of type [enum AttributeEffect.Type.TEMPORARY]. This is called
## automatically whenever base_value changes, a PERMANENT effect is applied, or
## a TEMPORARY effect is added/removed, but this can be called manually to update
## the value automatically.
func update_current_value() -> void:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	var event: AttributeEvent = AttributeEvent.new(self)
	event._new_base_value = _base_value # Base value won't change here
	_update_current_value(event)
	event_occurred.emit(event)


func _update_current_value(event: AttributeEvent) -> void:
	var new_current_value: AttributeUtil.Reference = AttributeUtil.Reference.new(_base_value)
	_actives.temporaries_w_value.for_each_allow_mutations(
		func(active: ActiveAttributeEffect) -> void:
			# Skip if not added or is expired
			if !active.is_added() || active.is_expired():
				return
			
			# Set pending values
			active._pending_prior_attribute_value = new_current_value.ref
			active._pending_effect_value = AttributeModifiedValueGetter.value().get_modified(self, active)
			active._pending_raw_attribute_value = active.get_effect().apply_calculator(_base_value, 
			new_current_value.ref, active._pending_effect_value)
			active._pending_final_attribute_value = _validate_value(active._pending_raw_attribute_value, 
			_current_value_validators)
			
			if !AttributeConditionTester.temporary_apply().test(self, active, event):
				event._apply_blocked_event = true
				event._blocked_temporary_actives[active] = null
				active._is_applying = false
				return
			
			active._is_applying = true
			active._last_effect_value = active._pending_effect_value
			active._last_prior_attribute_value = _current_value
			active._last_raw_attribute_value = active._pending_raw_attribute_value
			active._last_final_attribute_value = active._pending_final_attribute_value
			active._clear_pending_values()
			new_current_value.ref = active._last_final_attribute_value
	)
	
	if _current_value != new_current_value.ref:
		var prev_current_value: float = _current_value
		_current_value = new_current_value.ref
		
		_in_monitor_signal_or_hook = true
		monitor_current_value_changed.emit(prev_current_value)
		_in_monitor_signal_or_hook = false
	
	event._new_current_value = _current_value


###########################
## Active Effect Get/Has ##
###########################


## Returns a new [Array] (safe to mutate) of the current [ActiveAttributeEffect]s.
## The actives themselves are NOT duplicated.
func get_actives() -> Array[ActiveAttributeEffect]:
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
func find_actives_by_effect(effect: AttributeEffect) -> Array[ActiveAttributeEffect]:
	return _actives.find_all(
		func(active: ActiveAttributeEffect) -> bool:
			return active._effect == effect
	)


## Searches through all active [ActiveAttributeEffect]s and returns the first active
## whose [method AttributEffectactive.get_effect] equals [param effect]. Returns null
## if there is no active of [param effect]. Useful when you know that the [param effect]'s
## stack mode is COMBINE, DENY, or DENY_ERROR as in those cases there can only 
## be one instance of the effect.
func find_first_active_by_effect(effect: AttributeEffect) -> ActiveAttributeEffect:
	return _actives.find_first(
		func(active: ActiveAttributeEffect) -> bool:
			return active._effect == effect
	)


###########################
## Adding Active Effects ##
###########################


## TODO Fix docs
func add_effect(effect: AttributeEffect) -> void:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	assert(allow_effects, "allow_effects is false for %s" % self)
	add_active(effect.create_active_effect())


## TODO Fix docs
func add_effects(effects: Array[AttributeEffect], sort_by_priority: bool = true) -> void:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	assert(allow_effects, "allow_effects is false for %s" % self)
	assert(!effects.has(null), "effects has null element")
	var actives: Array[ActiveAttributeEffect] = []
	for effect: AttributeEffect in effects:
		add_active(effect.create_active_effect())


## TODO Fix docs
func add_actives(actives: Array[ActiveAttributeEffect], sort_by_priority: bool = true) -> void:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	assert(allow_effects, "allow_effects is false for %s" % self)
	assert(!actives.has(null), "actives has null element")
	
	# Define array to use
	var actives_to_add: Array[ActiveAttributeEffect]
	actives_to_add.assign(actives)
	
	# Duplicate & sort array if sort_by_priority is true
	if sort_by_priority:
		actives_to_add.sort_custom(_actives._sort_new_before_other)
	
	# Iterate actives to apply
	for active: ActiveAttributeEffect in actives_to_add:
		add_active(active)


## TODO fix docs
func add_active(active: ActiveAttributeEffect) -> void:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	assert(allow_effects, "allow_effects is false for %s" % self)
	assert(active != null, "active is null")
	assert(!_actives.has(active), "%s already added to this attribute or another" % active)
	
	# Throw error if active's effect exists & has StackMode.DENY_ERROR
	assert(active.get_effect().stack_mode != AttributeEffect.StackMode.DENY_ERROR or \
	!has_effect(active.get_effect()), 
	"active (%s)'s effect stack_mode == DENY_ERROR but stacking was attempted on attribute %s" \
	% [active, self])
	
	var current_tick: int = _get_ticks()
	var event: AttributeEvent = AttributeEvent.new(self, active)
	
	# Effect is instant, ignore other logic & apply it
	if active.get_effect().is_instant():
		active._last_add_result = AddEffectResult.INSTANT_CANT_ADD
		_apply_permanent_active(active, current_tick, event)
		event_occurred.emit(event)
		return
	
	# At this point it will be added (isn't instant)
	event._add_event = true
	
	# Do not stack if DENY or DENY_ERROR & effect already exists
	if (active.get_effect().stack_mode == AttributeEffect.StackMode.DENY or \
	active.get_effect().stack_mode == AttributeEffect.StackMode.DENY_ERROR) and \
	has_effect(active.get_effect()):
		active._last_add_result = AddEffectResult.STACK_DENIED
		event_occurred.emit(event)
		return
	
	# Check add conditions & blockers
	if !AttributeConditionTester.add().test(self, active, event):
		event_occurred.emit(event)
		return
	
	# Handle COMBINE stacking (only if a active of the same effect already exists)
	if active.get_effect().stack_mode == AttributeEffect.StackMode.COMBINE \
	and has_effect(active.get_effect()):
		# Find the existing of this effect
		var existing: ActiveAttributeEffect = find_first_active_by_effect(active.get_effect())
		assert(existing != null, ("existing is null, but has_effect returned true " + \
		"for active %s") % active)
		active._last_add_result = AddEffectResult.STACKED
		
		_set_active_stack_count(existing, existing._stack_count + active._stack_count, event)
		event_occurred.emit(event)
		return
	
	# Initialize if not done so
	if !active.is_initialized():
		if active.get_effect().has_period() && active.get_effect().initial_period:
			active._remaining_period = AttributeModifiedValueGetter.period().get_modified(self, active)
		if active.get_effect().has_duration():
			active._remaining_duration = AttributeModifiedValueGetter.duration().get_modified(self, active)
		active._initialized = true
	
	# Ensure duration is valid
	assert(!active.get_effect().has_duration() || active._remaining_duration > 0.0,
	"active (%s) has a remaining_duration <= 0.0" % active)
	
	# Run pre_add hooks
	_in_monitor_signal_or_hook = true
	_run_hooks(AttributeEffectHook._Function.BEFORE_ACTIVE_ADDED, active, event)
	_in_monitor_signal_or_hook = false
	
	# At this point it can be added
	active._last_add_result = AddEffectResult.SUCCESS
	active._tick_added_on = current_tick
	active._tick_last_processed = current_tick
	
	# Add to array
	_actives.add(active)
	# Update _has_actives (which thus updates processing)
	_has_processable_actives = !_actives.processing_required.is_empty()
	
	# Add to _effect_counts
	var new_count: int = _effect_counts.get(active.get_effect().id, 0) + 1
	_effect_counts[active.get_effect().id] = new_count
	
	# Run hooks & emit signal
	_in_monitor_signal_or_hook = true
	_run_hooks(AttributeEffectHook._Function.AFTER_ACTIVE_ADDED, active, event)
	if active.get_effect().emit_added_signal:
		monitor_active_added.emit(active)
	_in_monitor_signal_or_hook = false
	
	# Update current value if a temporary active is added & has value
	if active.get_effect().is_temporary() && active.get_effect().has_value:
		_update_current_value(event)
		
	# Apply it if permanent (must be to have a period) & initial period <= 0.0
	elif active.get_effect().has_period() && active._remaining_period <= 0.0:
		_apply_permanent_active(active, current_tick, event)
		# Remove if it hit apply limit
		if active.hit_apply_limit():
			_remove_active(active, event)
		# Update period
		else:
			active._remaining_period += AttributeModifiedValueGetter.period().get_modified(self, active)
	
	# Emit the event
	event_occurred.emit(event)


######################
## Active Mutations ##
######################


## Sets the stack count of [param active] to [param new_stack_count]. The active's
## [AttributeEffect] must have [member AttributeEffect.stack_mode] set to
## [enum AttributeEffect.StackMode.COMBINE] or an error will be thrown (in debug mode
## via an assertion).
func set_active_stack_count(active: ActiveAttributeEffect, new_stack_count: int) -> void:
	var event: AttributeEvent = AttributeEvent.new(self, active)
	_set_active_stack_count(active, new_stack_count, event)
	event_occurred.emit(event)


## Sets the stack count of [param active] to [param new_stack_count]. The active's
## [AttributeEffect] must have [member AttributeEffect.stack_mode] set to
## [enum AttributeEffect.StackMode.COMBINE] or an error will be thrown (in debug mode
## via an assertion).
func _set_active_stack_count(active: ActiveAttributeEffect, new_stack_count: int, event: AttributeEvent) -> void:
	assert(active != null, "active is null")
	assert(active.get_effect().stack_mode == AttributeEffect.StackMode.COMBINE,
	"%s's effect's stack_mode != StackMode.COMBINE, but is set to %s" \
	% [active.get_effect(), active.get_effect().stack_mode])
	
	var previous_stack_count: int = active._stack_count
	active._stack_count = new_stack_count
	event._new_active_stack_count = new_stack_count
	
	_in_monitor_signal_or_hook = true
	monitor_active_stack_count_changed.emit(active, previous_stack_count)
	_in_monitor_signal_or_hook = false
	
	# Update current value if existing is a temporary active w/ a value
	if active.get_effect().is_temporary() && active.get_effect().has_value:
		_update_current_value(event)
	
	_in_monitor_signal_or_hook = true
	_run_hooks(AttributeEffectHook._Function.AFTER_ACTIVE_STACK_CHANGED, active, event,
	[previous_stack_count])
	_in_monitor_signal_or_hook = false


func set_active_remaining_duration(active: ActiveAttributeEffect, new_remaining_duration: float) -> void:
	# TODO implement
	pass


func _set_active_remaining_duration(active: ActiveAttributeEffect, new_remaining_duration: float,
event: AttributeEvent) -> void:
	# TODO implement
	pass


func set_active_remaining_period(active: ActiveAttributeEffect, new_remaining_period: float) -> void:
	# TODO implement
	pass


func _set_active_remaining_period(active: ActiveAttributeEffect, new_remaining_period: float,
event: AttributeEvent) -> void:
	# TODO implement
	pass


#############################
## Removing Active Effects ##
#############################


## Removes all [ActiveAttributeEffect]s whose effect equals [param effect].
## Returns the number of [ActiveAttributeEffect]s removed.
func remove_effect(effect: AttributeEffect) -> int:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	var removed: AttributeUtil.Reference = AttributeUtil.Reference.new(0)
	_actives.for_each_allow_mutations(
		func(active: ActiveAttributeEffect) -> void:
			if active.get_effect() == effect:
				var event: AttributeEvent = AttributeEvent.new(self, active)
				_remove_active(active, event)
				removed.ref += 1
				event_occurred.emit(event)
	)
	return removed.ref


## Removes all [ActiveAttributeEffect]s whose effect is present in [param effects]. 
## Returns the number of [ActiveAttributeEffect]s removed.
func remove_effects(effects: Array[AttributeEffect]) -> int:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	var removed: AttributeUtil.Reference = AttributeUtil.Reference.new(0)
	_actives.for_each_allow_mutations(
		func(active: ActiveAttributeEffect) -> void:
			if effects.has(active.get_effect()):
				var event: AttributeEvent = AttributeEvent.new(self, active)
				_remove_active(active, event)
				removed.ref += 1
				event_occurred.emit(event)
	)
	return removed.ref


## Removes all [param actives] in the specified order, returning the number of [ActiveAttributeEffect] 
## that were present & removed. An [AttributeEvent] is emitted for each removed active, via
## [signal event_occurred].
func remove_actives(actives: Array[ActiveAttributeEffect]) -> int:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	var removed: int = 0
	for active: ActiveAttributeEffect in actives:
		if remove_active(active):
			removed += 1
	return removed


## Removes the [param active], returning true if removed, false if not.
func remove_active(active: ActiveAttributeEffect) -> bool:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	if active == null || !has_active(active):
		return false
	var event: AttributeEvent = AttributeEvent.new(self, active)
	_remove_active(active, event)
	event_occurred.emit(event)
	return true


func _remove_active(active: ActiveAttributeEffect, event: AttributeEvent) -> void:
	assert(active != null, "active is null")
	assert(_actives.has(active), "(%s) not added to _actives" % active)
	
	# Set removed in evenmt
	event._remove_event = true
	
	# Run PRE_REMOVE hooks
	_in_monitor_signal_or_hook = true
	_run_hooks(AttributeEffectHook._Function.BEFORE_ACTIVE_REMOVED, active, event)
	_in_monitor_signal_or_hook = false
	
	# Erase from array
	_actives.erase(active)
	
	# Set _has_actives (updates the processing accordingly)
	_has_processable_actives = !_actives.processing_required.is_empty()
	
	# Remove it from _effect_counts
	if _effect_counts.has(active.get_effect().id):
		var new_count: int = _effect_counts[active.get_effect().id] - 1
		if new_count <= 0:
			_effect_counts.erase(active.get_effect().id)
		else:
			_effect_counts[active.get_effect().id] = new_count
	
	# Run REMOVED hooks
	_in_monitor_signal_or_hook = true
	_run_hooks(AttributeEffectHook._Function.AFTER_ACTIVE_REMOVED, active, event)
	# Emit monitor signal
	if active.get_effect().emit_removed_signal:
		monitor_active_removed.emit(active)
	_in_monitor_signal_or_hook = false
	
	# Update current value if is TEMPORARY w/ value
	if active.get_effect().is_temporary() && active.get_effect().has_value:
		_update_current_value(event)


## Removes all [ActiveAttributeEffect]s from this attribute. Iterates the internal
## array of actives & removes them one by one.
func remove_all_effects() -> void:
	assert(!_in_monitor_signal_or_hook, "can not call mutating methods on an Attribute" + \
	"from a hook or while handling a signal prefixed with monitor_")
	var to_remove: Array[ActiveAttributeEffect] = _actives.duplicate_array()
	for active: ActiveAttributeEffect in to_remove:
		var event: AttributeEvent = AttributeEvent.new(self, active)
		_remove_active(active, event)
		event_occurred.emit(event)

######################
## Applying Actives ##
######################

## Applies the [param active]. Returns true if it should be removed (hit apply limit),
## false if not. Does not update the current value, that must be done manually after.
## Emits signals that could result in array mutations, so considered unsafe.
func _apply_permanent_active(active: ActiveAttributeEffect, current_tick: int, event: AttributeEvent) -> void:
	event._apply_event = true
	
	# Set prior attribute value value
	active._pending_prior_attribute_value = _base_value
	
	# Get the modified value
	active._pending_effect_value = AttributeModifiedValueGetter.value().get_modified(self, active)
	
	# Calculate the attribute's new value
	active._pending_raw_attribute_value = active.get_effect().apply_calculator(_base_value, 
	_current_value, active._pending_effect_value)
	
	# Validate the attribute's value
	active._pending_final_attribute_value = _validate_value(active._pending_raw_attribute_value, 
	_base_value_validators)
	
	# Check apply conditions
	if !AttributeConditionTester.permanent_apply().test(self, active, event):
		if active.get_effect().count_apply_if_blocked:
			active._apply_count += 1
		event._apply_blocked_event = true
		active._clear_pending_values()
		active._is_applying = false
		return
	
	active._is_applying = true
	
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
	
	_set_base_value_pre_validated(active._last_final_attribute_value, event)
	
	_in_monitor_signal_or_hook = true
	# Run hooks
	_run_hooks(AttributeEffectHook._Function.AFTER_ACTIVE_APPLIED, active, event)
	# Emit signal
	if active.get_effect().emit_applied_signal:
		monitor_active_applied.emit(active)
	_in_monitor_signal_or_hook = false


###################
## Miscellaneous ##
###################


func _update_processing() -> void:
	var _can_process: bool = !Engine.is_editor_hint() && _has_processable_actives && allow_effects
	set_process(_can_process && effects_process_function == ProcessFunction.PROCESS)
	set_physics_process(_can_process && effects_process_function == ProcessFunction.PHYSICS_PROCESS)


# Runs the hook [param _function] on all [AttributeEffectHook]s who have
# implemented that function.
func _run_hooks(_function: AttributeEffectHook._Function, active: ActiveAttributeEffect, 
event: AttributeEvent, additional_args: Array[Variant] = []) -> void:
	if !AttributeEffectHook._can_run(_function, active.get_effect()):
		return
	var function_name: String = AttributeEffectHook._function_names[_function]
	var args: Array[Variant] = [self, active, event]
	args.append_array(additional_args)
	for hook: AttributeEffectHook in active.get_effect()._hooks_by_function.get(_function):
		hook.callv(function_name, args)

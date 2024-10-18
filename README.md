# Godot Attributes

This addon is a WIP. There are still a few issues to work out, and a *lot* of unit tests need to be written due to the complexity of the system.

## Main Features
- `Attribute` Node that contains two floating point values, a base value and a current value.
- `AttributeContainer` Node to manage & contain each attribute instance in the parent node.
- A simple "tagging" system, similar to that in Unreal's GAS. Add & remove tags to/from attribute containers.
- Highly customizable `AttributeEffect`s which can be applied to an Attribute to modify its values, block other effects, or modify other effects.
	- Permanent effects for base value changes
	- Temporary effects for buffs/debuffs to the current value
	- Instant, duration based, & infinite effects.
	- Highly configurable conditions for if an effect can be added or applied.
	- `ModifiableValue`s provide
- Accurate timing system for the applying of effects with a period & expiration of duration based effects.
	- Using Godot's `Time` class instead of process's `delta` allows for near `1ms` accuracy.
- Responsive & informative event/signal system
	- The emission of a single signal when safe to do so allows for the ability to instantly add & remove effects to an attribute while handling events from that attribute, without breaking the core logic.
	- `AttributeEvent` payload to that signal contains all of the information relevant to what change took place in an `Attribute` since the last event was emitted
- Efficiency focused
	- `Attribute` nodes with no active effects have processing disabled & thus are extremely lightweight. 
	- The core loop for an `Attribute` with active effects has been optimized to the best of my ability & within GDScript's own limitations. The most expensive operations are adding & removing
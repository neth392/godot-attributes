## Modifier that rounds the [AttributeEffect]'s value to the nearest int.
@tool
class_name IntRounderModifier extends AttributeEffectModifier

## Defines how to round the float to an integer.
enum Rounding {
	## Rounds to the nearest integer.
	NEAREST = 0,
	## Rounds up to the nearest integer.
	UP = 1,
	## Rounds down to the nearest integer.
	DOWN = 2,
}

## How the effect value is rounded.
@export var rounding: Rounding

func _modify(value: float, attribute: Attribute, active: ActiveAttributeEffect) -> float:
	match rounding:
		Rounding.NEAREST:
			return roundi(value)
		Rounding.UP:
			return ceil(value)
		Rounding.DOWN:
			return floor(value)
		_:
			assert(false, "no implementation for rounding %s" % rounding)
			return value

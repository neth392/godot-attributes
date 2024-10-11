## Validator that ensures an [Attribute]'s base and/or current value is always
## an integer.
@tool
class_name IntValidator extends AttributeValueValidator

## Defines how to round the float to an integer.
enum Rounding {
	## Rounds to the nearest integer.
	NEAREST = 0,
	## Rounds up to the nearest integer.
	UP = 1,
	## Rounds down to the nearest integer.
	DOWN = 2,
}

## How attribute values are rounded.
@export var rounding: Rounding

func _validate(value: float) -> float:
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

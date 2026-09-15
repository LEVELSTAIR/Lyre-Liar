class_name TimeText
extends RefCounted

## Formats run times for the HUD and menus.


## "mm:ss" for a duration in seconds.
static func format(seconds: float) -> String:
	var whole := int(maxf(seconds, 0.0))
	return "%02d:%02d" % [whole / 60, whole % 60]

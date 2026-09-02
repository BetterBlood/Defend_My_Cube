extends Node

class_name StatusEffectId

static var next_id: int = 0

static func get_next_id() -> int:
	next_id += 1
	return next_id - 1

extends Node

func Roll(minimum, maximum):
	var result = randi() % maximum
	if result < minimum:
		result = minimum
	
	return result
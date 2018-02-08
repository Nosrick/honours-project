extends Node

func Roll(minimum, maximum):
	var result = randi() % maximum
	if result < minimum:
		result = minimum
	
	return result

#Normalise on any scale
func Normalise(number, left, right):
	var y = (number - left) / (right - left)
	return y

func NormaliseOneToTen(number):
	var y = (number - 1) / (10 - 1)
	return y
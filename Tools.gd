extends Node

func Roll(minimum, maximum):
	var result = randi() % maximum
	if result < minimum:
		result = minimum
	
	return result

#Normalise on any scale
func Normalise(number, left, right):
	var y = float(number - left) / float(right - left)
	return y

func NormaliseOneToTen(number):
	var y = float(number - 1) / float(10 - 1)
	return y

func RecombobulateOneToTen(number):
	var y = float(float(number) * (10 - 1))
	return y
extends Node

#A simple class for the odds and ends that don't fit anywhere else

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
	var y = float(float(number) * float(10 - 1))
	return y

func RecursiveDictionarySearch(dictionary, searchTerm):
	for item in dictionary:
		if item == typeof(dictionary):
			if item.has(searchTerm):
				return item.searchTerm
			elif item == searchTerm:
				return item
			elif item == typeof(dictionary):
				return RecursiveSearch(item, searchTerm)
			else:
				return false
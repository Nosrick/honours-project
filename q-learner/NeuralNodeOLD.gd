extends Node

var weights = []
var bounds = Rect2()
var vector = Vector2()

func _init(left, top, width, height, weightsCount):
	bounds = Rect2(left, top, width, height)
	weights = []
	
	for i in range(weightsCount):
		weights.append(randf())
	
	vector = Vector2(left + (width / 2), top + (height / 2))

func GetDistance(inputList):
	var distance = 0
	
	for i in range(weights.size()):
		distance += (inputList[i] - weights[i]) * (inputList[i] - weights[i])
	
	distance = sqrt(distance)
	
	return distance

func AdjustWeights(target, learningRate, influence):
	for i in range(target.size()):
		#OJA-STYLE LEARNING
		weights[i] += influence * (learningRate * ((target[i] * (weights[i] * target[i])) - ((weights[i] * target[i]) * (weights[i] * target[i]) * weights[i])))
		print("Current weight: " + str(weights[i]) + " at " + str(vector))

func _ready():
	pass

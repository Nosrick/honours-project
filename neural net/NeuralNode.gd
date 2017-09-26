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
		var weight = learningRate * influence * (target[i] - weights[i])
		print("Calculated weight: " + str(weight) + " at " + str(vector))
		weights[i] += weight
		
		if (weights[i] > 1.0):
			weights[i] = 1.0
		elif (weights[i] < 0.0):
			weights[i] = 0.0
		
		#REVIEW LATER
		#OJA-STYLE LEARNING
		#FLAWED, BUT ALMOST THERE
		#weights[i] += (target[i] * weights[i]) - ((weights[i] * weights[i]) * weights[i])
		print("Current weight: " + str(weights[i]) + " at " + str(vector))

func _ready():
	pass

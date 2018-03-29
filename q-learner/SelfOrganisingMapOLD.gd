extends Node

var node = preload("NeuralNodeOLD.gd")
var tools = preload("../Tools.gd").new()

var nodes = []
var lastWinner
var width
var height

var LEARNING_RATE = 0.8
var INPUT_SAMPLE_SIZE = 3
var CLUSTER_MOD = 10

func _init(widthRef, heightRef):
	randomize()
	nodes = []
	width = widthRef
	height = heightRef
	
	for x in range(width):
		for y in range(height):
			nodes.append(node.new(x, y, x + 1, y + 1, INPUT_SAMPLE_SIZE))

func Epoch(data):
	if(data[0].size() != INPUT_SAMPLE_SIZE):
		return false
	
	var result = tools.Roll(0, data.size())
	lastWinner = GetBestMatch(data[result])
	
	var neighbourhood = sqrt(width * height) / CLUSTER_MOD
	var widthSquared = neighbourhood * neighbourhood
	
	for i in range(nodes.size()):
		var distanceSquared = (lastWinner.vector.x - nodes[i].vector.x) * (lastWinner.vector.x - nodes[i].vector.x) + (lastWinner.vector.y - nodes[i].vector.y) * (lastWinner.vector.y - nodes[i].vector.y)
		
		if (distanceSquared < widthSquared):
			var influence = exp((-distanceSquared) / (2 * widthSquared))
			
			nodes[i].AdjustWeights(data[result], LEARNING_RATE, influence)
	
	return true

func Reinforce(data):
	if(data.size() != INPUT_SAMPLE_SIZE):
		return false
	
	lastWinner = GetBestMatch(data)
	
	lastWinner.AdjustWeights(data, LEARNING_RATE, 1.0)
	return true

func GetBestMatch(inputs):
	var lowestDistance = 9999999999
	var winner = null
	
	for i in range(nodes.size()):
		var distance = nodes[i].GetDistance(inputs)
		if (distance < lowestDistance):
			lowestDistance = distance
			winner = nodes[i]
	
	return winner

func _ready():
	pass

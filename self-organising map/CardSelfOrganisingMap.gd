extends Node

var node = preload("CardSOMNeuralNode.gd")
var tools = load("res://Tools.gd").new()

var filePath = "res://myBrainSOM.json"

var nodes = []
var width
var height

var learningRate = 0.3
var clusterMod = 0.1

func _init(widthRef, heightRef):
	randomize()
	nodes = []
	width = widthRef
	height = heightRef
	
	for x in range(width):
		for y in range(height):
			nodes.append(node.new(Vector2(x, y)))

func Epoch(newNode):
	"""
	var neighbourhood = sqrt(width * height) * clusterMod
	var hoodSquared = neighbourhood * neighbourhood
	
	for node in nodes:
		var distanceSquared = (newNode.vector.x - node.vector.x) * ( newNode.vector.x - node.vector.x) + (newNode.vector.y - node.vector.y) * (newNode.vector.y - node.vector.y)
		
		if distanceSquared < hoodSquared:
			var influence = exp((-distanceSquared) / (2 * hoodSquared))
			
			#Begin to cluster unassigned nodes
			if node.castingCardID == "None":
				node.castingCardID = newNode.castingCardID
				node.castingCardType = newNode.castingCardType
			
			if node.castingCardID != newNode.castingCardID:
				continue
			
			"""
	var node = GetBestMatch(newNode)
	var influence = 1.0
	node.AdjustMana(newNode.targetMana, learningRate, influence)
	node.AdjustQWeight(newNode.qWeight, learningRate, influence)

func GetBestMatch(input):
	var lowestDistance = 9999999
	var winner = null
	
	for node in nodes:
		if input.castingCardID == node.castingCardID:
			var distance = node.GetDistanceMana(input.targetMana)
			if distance < lowestDistance:
				lowestDistance = distance
				winner = node
			
	return winner

func GetBestQScore(input):
	var highestQScore = 0
	var winner = null
	
	for node in nodes:
		if input.castingCardID == node.castingCardID:
			if node.qWeight > highestQScore:
				highestQScore = node.qWeight
				winner = node
	
	return winner

func RandomUnassignedNode():
	var emptyNodes = []
	for node in nodes:
		if node.castingCardID == "None":
			emptyNodes.push_back(node)
	
	var result = tools.Roll(0, emptyNodes.size())
	return emptyNodes[result]

func Serialise():
	var brain = File.new()
	brain.open(filePath, File.WRITE)
	
	brain.store_line(str(width))
	brain.store_line(str(height))
	
	for node in nodes:
		var nodeData = node.Save()
		brain.store_line(nodeData.to_json())
	
	brain.close()
	
func Deserialise():
	var brain = File.new()
	if not brain.file_exists(filePath):
		return false
	
	brain.open(filePath, File.READ)
	
	nodes = []
	width = int(brain.get_line())
	height = int(brain.get_line())
	
	var currentLine = {}
	while(!brain.eof_reached()):
		currentLine.parse_json(brain.get_line())
		var newNode = node.new(ExtractVector(currentLine.vector))
		newNode.castingCardID = currentLine.castingCardID
		newNode.castingCardType = currentLine.castingCardType
		newNode.targetMana = currentLine.targetMana
		#newNode.weight = currentLine.weight
		newNode.qWeight = currentLine.qWeight
		
		nodes.append(newNode)
	
	brain.close()
	return true

func ExtractVector(string):
	var xIndex = string.find(",")
	var x = string.substr(1, xIndex - 1)
	var y = string.substr(xIndex + 1, string.length() - 1)
	return Vector2(float(x), float(y))
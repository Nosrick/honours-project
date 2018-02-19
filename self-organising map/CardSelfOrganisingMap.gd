extends Node

var node = preload("CardNeuralNode.gd")
var tools = load("res://Tools.gd").new()

var filePath = "res://myBrain.json"

var nodes = []
var width
var height

var learningRate = 0.8
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
	var winner = newNode
	#var winner = GetBestMatch(newNode)
	
	if winner != null:
		var neighbourhood = sqrt(width * height) * clusterMod
		var hoodSquared = neighbourhood * neighbourhood
		
		for node in nodes:
			var distanceSquared = (winner.vector.x - node.vector.x) * ( winner.vector.x - node.vector.x) + (winner.vector.y - node.vector.y) * (winner.vector.y - node.vector.y)
			
			if distanceSquared < hoodSquared:
				var influence = exp((-distanceSquared) / (2 * hoodSquared))
				
				#Begin to cluster unassigned nodes
				if node.castingCardID == "None":
					node.castingCardID = newNode.castingCardID
					node.castingCardType = newNode.castingCardType
				
				if node.castingCardID != newNode.castingCardID:
					continue
				
				node.AdjustMana(newNode.targetMana, learningRate, influence)
				node.AdjustQWeight(newNode.qWeight, learningRate, influence)
	else:
		var neighbourhood = sqrt(width * height) / clusterMod
		var hoodSquared = neighbourhood * neighbourhood
		
		var lastNode = null
		
		for node in nodes:
			if node.castingCardID == "None":
				node.SetParameters(newNode)
				lastNode = node
				break
		
		for node in nodes:
			if node.castingCardID != lastNode.castingCardID:
				continue
				
			var distanceSquared = (lastNode.vector.x - node.vector.x) * (lastNode.vector.x - node.vector.x) + (lastNode.vector.y - node.vector.y) * (lastNode.vector.y - node.vector.y)
			
			if distanceSquared < hoodSquared:
				var influence = exp((-distanceSquared) / (2 * hoodSquared))
				
				node.AdjustQWeight(lastNode.targetMana, learningRate, influence)

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
		return
	
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

func ExtractVector(string):
	var xIndex = string.find(",")
	var x = string.substr(1, xIndex - 1)
	var y = string.substr(xIndex + 1, string.length() - 1)
	return Vector2(float(x), float(y))
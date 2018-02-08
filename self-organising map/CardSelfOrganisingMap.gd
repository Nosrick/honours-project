extends Node

var node = preload("CardNeuralNode.gd")
var tools = load("res://Tools.gd").new()

var nodes = []
var width
var height

var learningRate
var clusterMod

func _init(widthRef, heightRef):
	randomize()
	nodes = []
	width = widthRef
	height = heightRef
	
	for x in range(width):
		for y in range(height):
			nodes.append(node.new(Vector2(x, y)))

func Epoch(newNode):
	var winner = GetBestMatch(newNode)
	
	if winner != null:
		var neighbourhood = sqrt(width * height) / clusterMod
		var hoodSquared = neighbourhood * neighbourhood
		
		for node in nodes:
			if node.castingCardID != newNode.castingCardID:
				continue
			
			var distanceSquared = (winner.vector.x - node.vector.x) * ( winner.vector.x - node.vector.x) + (winner.vector.y - node.vector.y) * (winner.vector.y - node.vector.y)
			
			if distanceSquared < hoodSquared:
				var influence = exp((-distanceSquared) / (2 * widthSquared))
				
				node.AdjustWeight(newNode.targetMana, learningRate, influence)
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
				var influence = exp((-distanceSquared) / (2 * widthSquared))
				
				node.AdjustWeight(lastNode.targetMana, learningRate, influence)

func GetBestMatch(input):
	var lowestDistance = 9999999
	var winner = null
	
	for node in nodes:
		if input.castingCardID == node.castingCardID:
			var distance = node.GetDistance(input.weight)
			if distance < lowestDistance:
				lowestDistance = distance
				winner = node
			
	return winner

func Serialise():
	var brain = File.new()
	brain.open("user://myBrain.json", File.WRITE)
	
	brain.store_line(width)
	brain.store_line(height)
	
	for node in nodes:
		var nodeData = node.save()
		brain.store_line(nodeData.to_json())
	
	brain.close()
	
func Deserialise():
	var brain = File.new()
	brain.open("user://myBrain.json", File.READ)
	
	width = brain.get_line()
	height = brain.get_line()
	
	var currentLine = {}
	while(!brain.eof_reached()):
		currentLine.parse_json(brain.get_line())
		var newNode = node.new(currentLine.vector)
		newNode.castingCardID = currentLine.castingCardID
		newNode.castingCardType = currentLine.castingCardType
		newNode.targetMana = currentLine.targetMana
		newNode.weight = currentLine.weight
		
		nodes.append(newNode)
	
	brain.close()
	
	
	

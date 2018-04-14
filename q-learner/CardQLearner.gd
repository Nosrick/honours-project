extends Node

var node = preload("CardQLearnerNeuralNode.gd")
var tools = load("res://Tools.gd").new()

var filePath = "res://myBrainQL.json"

var qMatrix = []
var rewards = []

var width
var height

const discountFactor = 0.8

func _init(cardsRef):
	randomize()
	qMatrix = []
	rewards = []
	width = cardsRef + 1
	height = cardsRef + 1
	
	for x in range(width):
		for y in range(height):
			qMatrix.append(0)
			rewards.append(node.new())

func GetQWeightByIndex(x, y):
	if x * height + y < width * height:
		return qMatrix[x * height + y]
	else:
		return null

func GetRewardByIndex(x, y):
	if x * height + y < width * height:
		return rewards[x * height + y]
	else:
		return null

func GetRewardByNames(leftName, rightName):
	for node in rewards:
		if node.castingCardID == leftName and node.nextCardID == rightName:
			return node
	
	return null

func GetRewardIndexByNames(leftName, rightName):
	var index = 0
	for node in rewards:
		if node.castingCardID == leftName and node.nextCardID == rightName:
			return index
		
		index += 1
	
	return -1

func GetQWeightByNames(leftName, rightName):
	var index = 0
	for node in rewards:
		if node.castingCardID == leftName and node.nextCardID == rightName:
			return qMatrix[index]
	
		index += 1
		
	return null

func GetQWeightIndexByNames(leftName, rightName):
	var index = 0
	for node in rewards:
		if node.castingCardID == leftName and node.nextCardID == rightName:
			return index
		
		index += 1
	
	return -1

func AdjustQWeight(leftName, rightName, hand):
	var index = GetQWeightIndexByNames(leftName, rightName)
	
	var handWeights = []
	for card in hand:
		var qWeight = GetRewardByNames(card.name, rightName)
		if qWeight != null:
			handWeights.push_back(qWeight.qWeight)
	
	var maximum = MultiMax(handWeights)
	var weight = rewards[index].qWeight + (discountFactor * maximum)
	qMatrix[index] = weight
	
	if qMatrix[index] > 100:
		qMatrix[index] = 100
	elif qMatrix[index] < -100:
		qMatrix[index] = -100
	
	print("NEW Q-WEIGHT: " + str(weight))

func AdjustReward(leftName, rightName, newReward):
	var index = GetRewardIndexByNames(leftName, rightName)
	
	rewards[index].qWeight += newReward
	
	#Bound the reward
	if rewards[index].qWeight < -100:
		rewards[index].qWeight = -100
	elif rewards[index].qWeight > 100:
		rewards[index].qWeight = 100

func AdjustTargetMana(leftName, rightName, newMana):
	var index = GetRewardIndexByNames(leftName, rightName)
	
	rewards[index].targetMana += newMana

func AdjustRelatedMana(leftName, newMana):
	#Get each related node
	#Adjust the current mana towards the new mana using the discount factor
	for node in rewards:
		if node.castingCardID == leftName:
			node.targetMana = float(discountFactor * sqrt((node.targetMana * node.targetMana) + (newMana * newMana)))

func MultiMax(list):
	var currentMax = 0
	var previousItem = -999
	for item in list:
		currentMax = max(item, previousItem)
	
	return currentMax

func Serialise():
	print("SERIALISING")
	var brain = File.new()
	brain.open(filePath, File.WRITE)
	
	brain.store_line("REWARDS")
	for node in rewards:
		var nodeData = node.Save()
		brain.store_line(nodeData.to_json())
	
	brain.store_line("QWEIGHTS")
	for node in qMatrix:
		brain.store_line(str(node))
	
	brain.close()
	print("DONE SERIALISING")
	
func Deserialise():
	var brain = File.new()
	if not brain.file_exists(filePath):
		return false
	
	brain.open(filePath, File.READ)
	
	rewards = []
	qMatrix = []
	
	var mode = "NONE"
	
	var currentLine = ""
	var dict = {}
	while(!brain.eof_reached()):
		currentLine = brain.get_line()
		if currentLine == "QWEIGHTS":
			mode = "QWEIGHTS"
			continue
		elif currentLine == "REWARDS":
			mode = "REWARDS"
			continue
		
		if mode == "QWEIGHTS":
			qMatrix.append(float(currentLine))
		
		elif mode == "REWARDS":
			dict.parse_json(currentLine)
			var newNode = node.new()
			newNode.castingCardID = dict.castingCardID
			newNode.castingCardType = dict.castingCardType
			
			newNode.nextCardID = dict.nextCardID
			newNode.nextCardType = dict.nextCardType
			
			newNode.targetMana = dict.targetMana
			newNode.qWeight = dict.qWeight
			
			rewards.append(newNode)
	
	brain.close()
	width = sqrt(rewards.size())
	height = width
	return true

func ExtractVector(string):
	var xIndex = string.find(",")
	var x = string.substr(1, xIndex - 1)
	var y = string.substr(xIndex + 1, string.length() - 1)
	return Vector2(float(x), float(y))
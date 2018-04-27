extends Node

const filePath = "res://myBrainMLP.json"

#Node templates
var inputNodeTemplate = load("res://multi-layer perceptron/InputMLPNeuralNode.gd")
var cardNodeTemplate = load("res://multi-layer perceptron/CardMLPNeuralNode.gd")
var outputNodeTemplate = load("res://multi-layer perceptron/OutputMLPNeuralNode.gd")

var tools = load("res://Tools.gd").new()

var epochs = 0

#6 cards, to represent the hand. Some can be null
var handInputs = []
const handNumber = 6

#Friendly lanes
var myLaneInputs = []
const myLaneNumber = 4

#Enemy lanes
var theirLaneInputs = []
const theirLaneNumber = 4

#1 mana input to represent the mana available to the player
var manaInput
const manaNumber = 1

#1 node per card
var cardHidden = []
var cardNumber

#1 output per card, for the action to take
var outputNodes = []
var outputNumber

#Weights for the connections between layers
var weights = []
var weightsNumber

var previousBoardState = Vector2()

const learningRate = 0.3

func _init():
	randomize()
	
	#Settings up the inputs
	handInputs = []
	for i in range(0, handNumber):
		handInputs.push_back(inputNodeTemplate.new())
	
	myLaneInputs = []
	for i in range(0, myLaneNumber):
		myLaneInputs.push_back(inputNodeTemplate.new())
	
	theirLaneInputs = []
	for i in range(0, theirLaneNumber):
		theirLaneInputs.push_back(inputNodeTemplate.new())
	
	cardHidden = []
	outputNodes = []
	
	weights = []

func Initialisation(cards):
	#Set up the hidden card layer
	for card in cards:
		var cardNode = cardNodeTemplate.new()
		cardNode.SetParametersCard(card)
		cardHidden.push_back(cardNode)
	
	cardNumber = cardHidden.size()
	
	#Set up the output layer
	for card in cards:
		var outputNode = outputNodeTemplate.new()
		outputNode.SetParametersCard(card)
		outputNode.targetMana = 1
		outputNodes.push_back(outputNode)
	
	outputNumber = outputNodes.size()
	
	#Set up the weights between layers
	#Hand -> Card hidden weights
	for i in range(0, handNumber * cardNumber):
		weights.push_back(Sigmoid(randf() / 2 - randf()))
	
	#My lane -> Card hidden weights
	for i in range(0, myLaneNumber * cardNumber):
		weights.push_back(Sigmoid(randf() / 2 - randf()))
	
	#Their lane -> Card hidden weights
	for i in range(0, theirLaneNumber * cardNumber):
		weights.push_back(Sigmoid(randf() / 2 - randf()))
	
	#Card Hidden weights -> Output
	for i in range(0, cardNumber * outputNumber):
		weights.push_back(Sigmoid(randf() / 2 - randf()))
	
	weightsNumber = weights.size()

func PopulateInput(inputList):
	#0-5 is the hand input, comes in card form
	for i in range(0, handNumber):
		if inputList[i] == null:
			handInputs[i].SetParametersToNone()
		else:
			handInputs[i].SetParametersCard(inputList[i])
	
	#6-9 is our lanes
	for i in range(0, myLaneNumber):
		var index = i + handNumber
		
		if inputList[index] == null:
			myLaneInputs[i].SetParametersToNone()
		else:
			myLaneInputs[i].SetParametersCard(inputList[index])
	
	#10-13 is their lanes
	for i in range(0, theirLaneNumber):
		var index = i + handNumber + myLaneNumber
		
		if inputList[index] == null:
			theirLaneInputs[i].SetParametersToNone()
		else:
			theirLaneInputs[i].SetParametersCard(inputList[index])
	
	#14 is the available mana
	var index = handNumber + myLaneNumber + theirLaneNumber
	manaInput = inputList[index]

func CalculateNetwork():
	#Hand -> Card
	for i in range(0, cardNumber):
		cardHidden[i].weight = 0
		
		for j in range(0, handNumber):
			var index = i + j
			var weight = handInputs[j].weight * weights[i * j]
			cardHidden[i].weight += weight
	
	#My lanes -> Card
	for i in range(0, cardNumber):
		for j in range(0, myLaneNumber):
			var index = (handNumber) * (i + j)
			var weight = myLaneInputs[j].weight * weights[index]
			cardHidden[i].weight += weight
	
	#Their lanes -> Card
	for i in range(0, cardNumber):
		for j in range(theirLaneNumber):
			var index = (handNumber + myLaneNumber) * (i + j)
			var weight = theirLaneInputs[j].weight * weights[index]
			cardHidden[i].weight += weight
		
		cardHidden[i].weight = Sigmoid(cardHidden[i].weight)
	
	#Card -> Output
	for i in range(0, outputNumber):
		outputNodes[i].weight = 0
		
		for j in range(cardNumber):
			var index = (handNumber + myLaneNumber + theirLaneNumber) + i + (outputNumber * j)
			var weight = cardHidden[j].weight * weights[index]
			outputNodes[i].weight += weight
		
		outputNodes[i].weight = Sigmoid(outputNodes[i].weight)

#The actual bit that does the reasoning
func Reason(inputList):
	#Fill the input list
	#Just to recap what the input list is:
	#0-5 is the AI hand
	#6-9 are friendly lanes
	#10-13 are enemy lanes
	#14 is the mana
	PopulateInput(inputList)
	
	#Calculate the network for this move
	CalculateNetwork()
	
	#Copy the output nodes into a list to be sorted
	var outputNodesCopy = []
	for output in outputNodes:
		outputNodesCopy.push_back(output)
	
	#Sort the list
	outputNodesCopy.sort_custom(self, "SortOutput")
	return outputNodesCopy
	
func SortOutput(left, right):
	if left.weight < right.weight:
		return true
	
	return false

#Get the TD error
func GetError(difference, newWeight, currentWeight):
	return difference + (learningRate * (newWeight)) - currentWeight

#Very simple linear prediction
func LinearPrediction(input, oldWeight, newWeight):
	var prediction = input * oldWeight * newWeight
	return prediction

func Epoch(predictedBoardState, teachingStep):
	#var difference = previousBoardState - predictedBoardState
	#var overallManaState = difference.x - difference.y
	var overallManaState = predictedBoardState.x - predictedBoardState.y
	
	#This is the TD error
	var normalisedManaState = tools.NormaliseOneToTen(overallManaState)
	
	var previousWeights = weights
	
	var tempWeights = weights
	
	#FUNCTION APPROXIMATION
	#Pt = Current prediction = previousBoardState
	#yt + 1 = Prediction target = predictedBoardState
	#Ot + 1 = TD error = function approximation
	#a = Learning rate/Step size?
	#vit = Weights of the linear prediction function of step t
	#xit' = Input weight at time step t'
	
	#vit + a (Ot + 1 * xit)
	
	CalculateNetwork()
	
	var handToCardDeltas = []
	var myLaneToCardDeltas = []
	var theirLaneToCardDeltas = []
	var cardToOutputDeltas = []
	
	#Going forward
	#Hand -> Card
	for i in range(0, handNumber):
		for j in range(0, cardNumber):
			var index = i + j
			var error = GetError(normalisedManaState, weights[index], previousWeights[index])
			var dotProduct = handInputs[i].weight * previousWeights[index]
			var handDelta = dotProduct + (learningRate * error * weights[index])
			handToCardDeltas.push_back(handDelta)
	
	#My lane -> Card
	for i in range(0, myLaneNumber):
		for j in range(0, cardNumber):
			var index = (handNumber + (i + j))
			var error = GetError(normalisedManaState, weights[index], previousWeights[index])
			var dotProduct = myLaneInputs[i].weight * previousWeights[index]
			var myLaneDelta = dotProduct + (learningRate * error * weights[index])
			myLaneToCardDeltas.push_back(myLaneDelta)
	
	#Their lane -> Card
	for i in range(0, theirLaneNumber):
		for j in range(0, cardNumber):
			var index = (handNumber * myLaneNumber) + (i + j)
			var error = GetError(normalisedManaState, weights[index], previousWeights[index])
			var dotProduct = theirLaneInputs[i].weight * previousWeights[index]
			var theirLaneDelta = dotProduct + (learningRate * error * weights[index])
			theirLaneToCardDeltas.push_back(theirLaneDelta)
	
	#Card -> Output
	for i in range(0, cardNumber):
		for j in range(0, outputNumber):
			var index = (handNumber * myLaneNumber * theirLaneNumber) + i + (outputNumber * j)
			var error = GetError(normalisedManaState, weights[index], previousWeights[index])
			var dotProduct = cardHidden[i].weight * previousWeights[index]
			var cardDelta = dotProduct + (learningRate * error * weights[index])
			cardToOutputDeltas.push_back(cardDelta)
	
	#Changing the weights
	#Hand -> Card
	for i in range(0, handNumber):
		for j in range(0, cardNumber):
			var index = (i + j)
			var error = GetError(normalisedManaState, weights[index], previousWeights[index])
			var dotProduct = handInputs[i].weight * previousWeights[index]
			var weight = dotProduct + (learningRate * error * handToCardDeltas[i])
			weights[index] = weight
			weights[index] = Sigmoid(weights[index])
	
	#My lanes -> Card
	for i in range(0, myLaneNumber):
		for j in range(0, cardNumber):
			var index = (handNumber) + (i + j)
			var error = GetError(normalisedManaState, weights[index], previousWeights[index])
			var dotProduct = myLaneInputs[i].weight * previousWeights[index]
			var weight = dotProduct + (learningRate * error * myLaneToCardDeltas[i])
			weights[index] = weight
			weights[index] = Sigmoid(weights[index])
	
	#Their lanes -> Card
	for i in range(0, theirLaneNumber):
		for j in range(0, cardNumber):
			var index = (handNumber * myLaneNumber) + (i + j)
			var error = GetError(normalisedManaState, weights[index], previousWeights[index])
			var dotProduct = theirLaneInputs[i].weight * previousWeights[index]
			var weight = dotProduct + (learningRate * error * theirLaneToCardDeltas[i])
			weights[index] = weight
			weights[index] = Sigmoid(weights[index])
	
	#Card -> Output
	for i in range(0, cardNumber):
		for j in range(0, outputNumber):
			var index = (handNumber * myLaneNumber * theirLaneNumber) + i + (outputNumber * j)
			var error = GetError(normalisedManaState, weights[index], previousWeights[index])
			var dotProduct = cardHidden[i].weight * previousWeights[index]
			var weight = dotProduct + (learningRate * error * cardToOutputDeltas[i])
			weights[index] = weight
			weights[index] = Sigmoid(weights[index])
	
	previousBoardState = predictedBoardState
	epochs += 1

func GetCardNode(card):
	for node in cardHidden:
		if node.castingCardID == card.name:
			return node
	
	return null

func Sigmoid(value):
	return float(1 / (1 + exp(-value)))

func Serialise():
	print("SERIALISING")
	var brain = File.new()
	brain.open(filePath, File.WRITE)
	
	brain.store_line("CARD")
	for card in cardHidden:
		var nodeData = card.Save()
		brain.store_line(nodeData.to_json())
	
	brain.store_line("WEIGHTS")
	for weight in weights:
		brain.store_line(str(weight))
	
	brain.store_line("OUTPUT")
	for output in outputNodes:
		var nodeData = output.Save()
		brain.store_line(nodeData.to_json())
	
	brain.close()
	print("DONE SERIALISING")

func Deserialise():
	var brain = File.new()
	
	if not brain.file_exists(filePath):
		return false
	
	brain.open(filePath, File.READ)
	
	var mode = "NONE"
	
	while(!brain.eof_reached()):
		var currentLine = brain.get_line()
		if currentLine == "":
			continue
		
		if currentLine == "CARD":
			mode = currentLine
			continue
		elif currentLine == "WEIGHTS":
			mode = currentLine
			continue
		elif currentLine == "OUTPUT":
			mode = currentLine
			continue
		
		if mode == "CARD":
			var node = {}
			node.parse_json(currentLine)
			var cardNode = cardNodeTemplate.new()
			cardNode.SetParameters(node)
			cardNode.weight = float(node.weight)
			cardHidden.push_back(cardNode)
		elif mode == "WEIGHTS":
			weights.push_back(float(currentLine))
		elif mode == "OUTPUT":
			var node = {}
			node.parse_json(currentLine)
			var outputNode = outputNodeTemplate.new()
			outputNode.castingCardID = node.castingCardID
			outputNode.castingCardType = node.castingCardType
			outputNode.weight = float(node.weight)
			outputNode.targetMana = int(node.targetMana)
			outputNode.cost = int(node.cost)
			outputNodes.push_back(outputNode)
			
	brain.close()
	
	cardNumber = cardHidden.size()
	outputNumber = outputNodes.size()
	weightsNumber = weights.size()
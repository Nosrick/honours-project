extends Node

const filePath = "res://myBrainMLP.json"

var cardNodeTemplate = load("res://multi-layer perceptron/CardMLPNeuralNode.gd")
var outputNodeTemplate = load("res://multi-layer perceptron/OutputMLPNeuralNode.gd")

var tools = load("res://Tools.gd").new()

#1 input node, to represent the chosen card
var inputNode
const inputNumber = 1
const inputLayer = 0

#1 node per card
var cardHidden = []
var cardNumber
const cardLayer = 1

#10 output, for the action to take
var outputNodes = []
const outputNumber = 10
const outputLayer = 2

#Weights for the connections between layers
var weights = []
var weightsNumber

var previousBoardState = Vector2()

const learningRate = 0.3

func _init():
	randomize()
	
	inputNode = load("res://multi-layer perceptron/CardMLPNeuralNode.gd").new()
	
	cardHidden = []
	outputNodes = []
	
	weights = []

func Training(cards):
	for i in range(1, 11):
		outputNodes.push_back(outputNodeTemplate.new(i))
	
	for card in cards:
		var cardNode = cardNodeTemplate.new()
		cardNode.SetParametersCard(card)
		cardHidden.push_back(cardNode)
	
	cardNumber = cardHidden.size()
	
	#Input -> Card hidden weights
	for i in range(0, inputNumber * cardNumber):
		weights.push_back(randf() / 2 - randf())
	
	#Card Hidden weights -> Output
	for i in range(0, cardNumber * outputNumber):
		weights.push_back(randf() / 2 - randf())
	
	weightsNumber = weights.size()

func CalculateNetwork():
	#Input -> Card
	for i in range(0, cardNumber):
		cardHidden[i].weight = 0
		
		for j in range(0, inputNumber):
			cardHidden[i].weight += inputNode.weight * weights[inputNumber * i + j]
		
		cardHidden[i].weight = Sigmoid(cardHidden[i].weight)
	
	#Card -> Output
	for i in range(0, outputNumber):
		outputNodes[i].weight = 0
		
		for j in range(cardNumber):
			outputNodes[i].weight += cardHidden[j].weight * weights[inputNumber * cardNumber * i + j]
		
		outputNodes[i].weight = Sigmoid(outputNodes[i].weight)

func Reason(input):
	inputNode.SetParametersCard(input)
	inputNode.weight = GetCardNode(input).weight
	
	CalculateNetwork()
	
	var highestWeight = 0
	var highestNode = null
	
	#Find the best fitting target
	for output in outputNodes:
		if output.weight > highestWeight:
			highestWeight = output.weight
			highestNode = output
			
	return highestNode

func Epoch(predictedBoardState, teachingStep, momentum):
	var difference = previousBoardState - predictedBoardState
	var overallManaState = difference.x - difference.y
	
	#This is the output delta
	var normalisedManaState = tools.NormaliseOneToTen(overallManaState)
	
	var previousWeights = weights
	
	var tempWeights = weights
	
	#Pt = Current prediction = previousBoardState
	#yt + 1 = Prediction target = predictedBoardState
	#Ot = TD error = normalisedManaState
	#a = Learning rate
	#vit = Weights of the linear prediction function of step t
		#My linear prediction function is normalisedManaState?
	#xit' = Input weight at time step t'
	
	#vit + a (Ot + 1 * xit)
	
	CalculateNetwork()
	
	var cardToOutputDeltas = []
	var inputToCardDeltas = []
	
	#Going forward
	#Input -> Card
	for i in range(0, inputNumber):
		for j in range(0, cardNumber):
			var index = (inputNumber * cardNumber) + j
			var inputDelta = normalisedManaState + learningRate * (normalisedManaState * inputNode.weight)
			inputToCardDeltas.push_back(inputDelta)
	
	#Card -> Output
	for i in range(0, cardNumber):
		for j in range(0, outputNumber):
			var index = (inputNumber * cardNumber) * (cardNumber * i)
			var cardDelta = normalisedManaState + learningRate * (normalisedManaState * cardHidden[i].weight)
			cardToOutputDeltas.push_back(cardDelta)
	
	#Changing the weights
	#Input -> Card
	for i in range(0, inputNumber):
		for j in range(0, cardNumber):
			var index = (inputNumber * j) + i
			var weight = normalisedManaState + learningRate * (inputNode.weight * inputToCardDeltas[j])
			weights[index] += weight
	
	#Card -> Output
	for i in range(0, cardNumber):
		for j in range(0, outputNumber):
			var index = (inputNumber * cardNumber) + (j * i)
			var weight = normalisedManaState + learningRate * (cardHidden[i].weight * cardToOutputDeltas[j])
			weights[index] += weight
	
	"""
	#Going backwards, backpropagation
	#Output -> Card
	for i in range(0, cardNumber):
		for j in range(0, outputNumber):
			var index = (inputNumber * cardNumber) + (cardNumber * i)
			var cardDelta = normalisedManaState * weights[index]
			cardDelta *= DerSigmoid(cardHidden[i].weight)
			outputToCardDeltas.push_back(cardDelta)
	
	#Card -> Input
	for i in range(0, inputNumber):
		for j in range(0, cardNumber):
			var index = (inputNumber * cardNumber) + j
			var inputDelta = cardHidden[i].weight * weights[index]
			inputDelta *= DerSigmoid(inputNode.weight)
			cardToInputDeltas.push_back(inputDelta)
	
	#Modify the weights
	#Card -> Input
	for i in range(0, inputNumber):
		for j in range(0, cardNumber):
			var index = (inputNumber * j) + i
			var weight = momentum * ((weights[index] - previousWeights[index]) + (teachingStep * (cardToInputDeltas[j] * inputNode.weight)))
			weights[index] += weight
			
			if weights[index] > 0.5:
				weights[index] = 0.5
			
			if weights[index] < -0.5:
				weights[index] = -0.5
	
	#Output -> Card
	for i in range(0, cardNumber):
		for j in range(0, outputNumber):
			var index = (inputNumber * cardNumber) + (j * i)
			var weight = momentum * ((weights[index] - previousWeights[index]) + (teachingStep * outputToCardDeltas[j] * cardHidden[i].weight))
			weights[index] += weight
			
			if weights[index] > 0.5:
				weights[index] = 0.5
			
			if weights[index] < -0.5:
				weights[index] = -0.5
	"""
	
	previousBoardState = predictedBoardState

func GetCardNode(card):
	for node in cardHidden:
		if node.castingCardID == card.name:
			return node
	
	return null

func Sigmoid(value):
	return float(1 / (1 + exp(-value)))

func DerSigmoid(value):
	return float(value * (1 - value))

func Serialise():
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
			#cardNode.tWeight = float(node.tWeight)
			cardHidden.push_back(cardNode)
		elif mode == "WEIGHTS":
			weights.push_back(float(currentLine))
		elif mode == "OUTPUT":
			var node = {}
			node.parse_json(currentLine)
			var outputNode = outputNodeTemplate.new(node.mana)
			outputNode.weight = float(node.weight)
			outputNodes.push_back(outputNode)
			
	brain.close()
	
	cardNumber = cardHidden.size()
	
	weightsNumber = weights.size()
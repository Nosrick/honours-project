extends Node

#8 input nodes, 1 for each lane
#0-3 are friendly lanes
#4-7 are enemy lanes
#0 for an empty lane, otherwise filled with the mana value
var laneInput = []
const laneNumber = 8
const laneLayer = 0

#Variable input nodes, depending upon hand size
var handInput = []
const handNumber = 6
const handLayer = 1

#1 node per card
var cardHidden = []
var cardNumber
const cardLayer = 2

#10 nodes, 1 for each level of mana
var manaHidden = []
const manaNumber = 10
const manaLayer = 3

#1 output, for the action to take
var output
const outputNumber = 1
const outputLayer = 4

#Weights for the connections between layers
var weights = []
var weightsNumber

var trainingCards

func _init():
	randomize()
	laneInput = []
	for i in range(0, 8):
		laneInput.push_back(0)
	
	handInput = []
	for i in range(0, 6):
		handInput.push_back(0)
	
	output = null
	cardHidden = []
	
	manaHidden = []
	var manaNodeTemplate = load("res://multi-layer perceptron/ManaMLPNeuralNode.gd")
	for i in range(1, 11):
		var manaNode = manaNodeTemplate.new(i)
		manaHidden.push_back(manaNode)
	
	weights = []

func Training(cards):
	var cardNodeTemplate = load("res://multi-layer perceptron/CardMLPNeuralNode.gd")
	for card in cards:
		var cardNode = cardNodeTemplate.new()
		cardNode.SetParametersCard(card)
		cardHidden.push_back(cardNode)
	
	cardNumber = cardHidden.size()
	
	#Lane input -> Card hidden weights
	for i in range(0, laneNumber * cardNumber):
		weights.push_back(randf() / 2 - randf())
	
	#Hand input -> Card hidden weights
	for i in range(0, handNumber * cardNumber):
		weights.push_back(randf() / 2 - randf())
	
	#Card hidden -> Mana hidden weights
	for i in range(0, cardNumber * manaNumber):
		weights.push_back(randf() / 2 - randf())
	
	#Mana hidden -> Output weights
	for i in range(0, manaNumber * outputNumber):
		weights.push_back(randf() / 2 - randf())
	
	weightsNumber = weights.size()

func CalculateNetwork():
	#Lane -> Card
	for i in range(0, cardHidden.size()):
		cardHidden[i].weight = 0
		
		for j in range(0, laneInput.size()):
			cardHidden[i].weight += laneInput[j] * weights[laneNumber * i + j]
		
		cardHidden[i].weight = Sigmoid(cardHidden[i])
	
	#Hand -> Card
	for i in range(0, cardHidden.size()):
		
		for j in range(0, handInput.size()):
			cardHidden[i].weight += handInput[j] * weights[handNumber * i + j]
		
		cardHidden[i].weight = Sigmoid(cardHidden[i])
	
	#Card -> Mana
	for i in range(0, manaHidden.size()):
		manaHidden[i] = 0
		
		for j in range(0, cardHidden.size()):
			manaHidden[i].weight += cardHidden[j] * weights[cardNumber * i + j]
		
		manaHidden[i].weight = Sigmoid(manaHidden[i])

func Epoch(currentBoardState, teachingStep, momentum):
	var difference = previousBoardState - currentBoardState
	var overallManaState = difference.x - difference.y
	
	var previousWeights = weights
	
	var tempWeights = weights
	
	CalculateNetwork()
	
	#Card -> Mana deltas
	var cardDeltas = []
	
	#Mana -> Output deltas
	var manaDeltas = []
	
	#This is the output delta
	var normalisedManaState = tools.NormaliseOneToTen(overallManaState)
	
	#Going backwards, backpropagation
	#Output -> Mana
	for i in range(0, manaNumber):
		var index = (laneNumber * cardNumber) + (handNumber * cardNumber) + (cardNumber * manaNumber) + (manaNumber * i)
		var manaDelta = normalisedManaState * weights[index]
		manaDelta *= DerSigmoid(manaHidden[i])
		manaDeltas.push_back(manaDelta)
	
	#Mana -> Card
	for i in range(0, cardNumber):
		for j in range(0, manaNumber):
			var index = (laneNumber * cardNumber) + (handNumber * cardNumber) + (i * j)
			var cardDelta = manaHidden[i].weight * weights[index]
			cardDelta *= DerSigmoid(cardHidden[j])
			cardDeltas.push_back(cardDelta)
	
	#Modify the weights
	#Card -> Lane
	for i in range(0, laneNumber):
		for j in range(0, cardNumber):
			var index = (laneNumber * j) + i
			var weight = momentum * ((weights[index] - previousWeights[index]) + (teachingStep * (cardDeltas[j] * laneInput[i])))
			weights[index] += weight
	
	#Card -> Hand
	for i in range(0, handNumber):
		for j in range(0, cardNumber):
			var index = (laneNumber * cardNumber) + (handNumber * j) + i
			var weight = momentum * ((weights[index] - previousWeights[index]) + (teachingStep * (cardDeltas[j] * handInput[i])))
			weights[index] += weight
	
	#Mana -> Card
	for i in range(0, cardNumber):
		for j in range(0, manaNumber):
			var index = (laneNumber * cardNumber) + (handNumber * cardNumber) + (cardNumber * j) + i
			var weight = momentum * ((weights[index] - previousWeights[index]) + (teachingStep * manaDeltas[j] * cardHidden[i].weight))
			weights[index] += weight
	
	#Output -> Mana
	for i in range(0, manaNumber):
		for j in range(0, outputNumber):
			var index = (laneNumber * cardNumber) + (handNumber * cardNumber) + (cardNumber * manaNumber) + j
			var weight = momentum * ((weights[index] - previousWeights[index]) + (teachingStep * normalisedManaState * manaHidden[i].weight))
			weights[index] += weight
	
func Sigmoid(value):
	return float(1 / (1 + exp(-value)))

func DerSigmoid(value):
	return float(value * (1 - value))
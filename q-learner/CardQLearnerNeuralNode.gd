extends Node

var castingCardID
var castingCardType

var nextCardID
var nextCardType

var targetMana
var qWeight

var tools = load("res://Tools.gd").new()

func _init():
	castingCardID = "None"
	castingCardType = 0
	
	nextCardID = "None"
	nextCardType = 0
	
	qWeight = randi() % 100
	targetMana = 1

func SetParameters(castingNode, nextNode):
	castingCardID = castingNode.castingCardID
	castingCardType = castingNode.castingCardType
	
	nextCardID = nextNode.castingCardID
	nextCardType = nextNode.castingCardType
	
	targetMana = castingNode.targetMana

func SetParametersByCards(castingCard, nextCard):
	castingCardID = castingCard.name
	castingCardType = castingCard.type
	
	nextCardID = nextCard.name
	nextCardType = nextCard.type
	
	if castingCard.cost + nextCard.cost > 6:
		qWeight = 0

func SetParametersByCard(castingCard):
	castingCardID = castingCard.name
	castingCardType = castingCard.type

func GetDistanceMana(targetManaRef):
	var distance = (targetManaRef - targetMana) * (targetManaRef - targetMana)
	
	distance = sqrt(distance)
	return distance

func AdjustManaOLD(targetManaRef, learningRate, influence):
	#OJA-STYLE LEARNING
	var normalisedMana = tools.NormaliseOneToTen(targetMana)
	var normalisedTarget = tools.NormaliseOneToTen(targetManaRef)
	
	var mana = float(normalisedTarget * (normalisedMana * normalisedTarget)) - ((normalisedMana * normalisedTarget) * (normalisedMana * normalisedTarget) * normalisedMana)
	if mana == 0:
		mana = normalisedTarget
	
	var recombobulated = float(tools.RecombobulateOneToTen(mana))
	
	targetMana += float(float(influence) * float(learningRate) * recombobulated)
	
	#targetMana = float(influence) * float(learningRate) * (float(targetManaRef - targetMana) * float(targetManaRef - targetMana))

func AdjustQWeightOLD(qWeightRef, learningRate, influence):
	#OJA-STYLE LEARNING
	var newWeight = float(influence * float(learningRate * float((qWeightRef * (qWeight * qWeightRef)) - ((qWeight * qWeightRef) * (qWeight * qWeightRef) * qWeight))))
	
	qWeight += newWeight

func ToString():
	return "[" + castingCardID + " : " + nextCardID + " : " + str(targetMana) + " : " + str(qWeight) + "]"

func Save():
	var data = {}
	data.castingCardID = castingCardID
	data.castingCardType = castingCardType
	
	data.nextCardID = nextCardID
	data.nextCardType = nextCardType
	
	data.targetMana = targetMana
	data.qWeight = qWeight
	
	return data
extends Node

#First identifying card stuff
var castingCardID
var castingCardType

#Second identifying card stuff
var nextCardID
var nextCardType

#Target mana value
var targetMana

#Q-weight, used in decision making
var qWeight

var tools = load("res://Tools.gd").new()

#Initialising the node
func _init():
	castingCardID = "None"
	castingCardType = 0
	
	nextCardID = "None"
	nextCardType = 0
	
	qWeight = randi() % 100
	targetMana = 1

#Setting the parameters of the node
func SetParameters(castingNode, nextNode):
	castingCardID = castingNode.castingCardID
	castingCardType = castingNode.castingCardType
	
	nextCardID = nextNode.castingCardID
	nextCardType = nextNode.castingCardType
	
	targetMana = castingNode.targetMana

#The same as above, but using cards rather than nodes
func SetParametersByCards(castingCard, nextCard):
	castingCardID = castingCard.name
	castingCardType = castingCard.type
	
	nextCardID = nextCard.name
	nextCardType = nextCard.type
	
	if castingCard.cost + nextCard.cost > 6:
		qWeight = -100

func SetParametersByCard(castingCard):
	castingCardID = castingCard.name
	castingCardType = castingCard.type

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
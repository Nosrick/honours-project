extends Node

var castingCardID
var castingCardType
var cost
var weight

var tools = load("res://Tools.gd").new()

func _init():
	weight = (randf() / 2) - randf()
	castingCardID = "None"
	castingCardType = 0

func SetParameters(node):
	castingCardID = node.castingCardID
	castingCardType = node.castingCardType
	cost = node.cost
	weight = 1.0

func SetParametersCard(card):
	castingCardID = card.name
	castingCardType = card.type
	cost = card.cost
	weight = 1.0

func SetParametersToNone():
	castingCardID = "None"
	castingCardType = 0
	weight = 0.0
	cost = 0

func ToString():
	return "[" + castingCardID + " : " + castingCardType + " : " + weight + "]"

func Save():
	var data = {}
	data.castingCardID = castingCardID
	data.castingCardType = castingCardType
	data.cost = cost
	data.weight = weight
	return data
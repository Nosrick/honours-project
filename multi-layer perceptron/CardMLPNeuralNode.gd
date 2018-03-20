extends Node

var castingCardID
var castingCardType
var weight
var tWeight

var tools = load("res://Tools.gd").new()

func _init():
	weight = (randf() / 2) - randf()
	tWeight = randf()
	castingCardID = "None"
	castingCardType = 0

func SetParameters(node):
	castingCardID = node.castingCardID
	castingCardType = node.castingCardType

func SetParametersCard(card):
	castingCardID = card.name
	castingCardType = card.type

func ToString():
	return "[" + castingCardID + " : " + castingCardType + " : " + weight + "]"

func Save():
	var data = {}
	data.castingCardID = castingCardID
	data.castingCardType = castingCardType
	
	data.weight = weight
	return data
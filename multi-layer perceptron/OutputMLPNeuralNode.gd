extends Node

var castingCardID
var castingCardType
var cost
var targetMana
var weight

var tools = load("res://Tools.gd").new()

func _init():
	weight = (randf() / 2) - randf()

func SetParameters(node):
	castingCardID = node.castingCardID
	castingCardType = node.castingCardType
	cost = node.cost

func SetParametersCard(card):
	castingCardID = card.name
	castingCardType = card.type
	cost = card.cost

func ToString():
	return "[ " + castingCardID + " : " + castingCardType + " : " + str(targetMana) + " : " + str(weight) + " ]"

func Save():
	var data = {}
	data.castingCardID = castingCardID
	data.castingCardType = castingCardType
	data.targetMana = targetMana
	data.weight = weight
	data.cost = cost
	
	return data
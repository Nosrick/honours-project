extends Node

var castingCardID
var castingCardType
var targetMana
var weight
var vector = Vector2()

var tools = load("res://Tools.gd").new()

func _init(positionRef):
	vector = positionRef
	
	weight = randf()
	castingCardID = "None"

func SetParameters(node):
	castingCardID = node.castingCardID
	castingCardType = node.castingCardType
	targetMana = node.targetMana

func GetDistance(weightRef):
	var distance = (weightRef - weight) * (weightRef - weight)
	
	distance = sqrt(distance)
	return distance

func AdjustWeight(targetManaRef, learningRate, influence):
	#OJA-STYLE LEARNING
	normalisedMana = Tools.NormaliseOneToTen(targetMana)
	normalisedTarget = Tools.NormaliseOneToTen(targetManaRef)
	
	targetMana = targetManaRef
	weight += influence * (learningRate * ((normalisedTarget * (normalisedMana * normalisedTarget)) - ((normalisedMana * normalisedTarget) * (normalisedMana * normalisedTarget) * normalisedMana)))
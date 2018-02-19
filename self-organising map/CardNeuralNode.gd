extends Node

var castingCardID
var castingCardType
var targetMana
var weight
var qWeight
var vector = Vector2()

var tools = load("res://Tools.gd").new()

func _init(positionRef):
	vector = positionRef
	
	weight = randf()
	castingCardID = "None"
	qWeight = randf()
	targetMana = 1

func SetParameters(node):
	castingCardID = node.castingCardID
	castingCardType = node.castingCardType
	targetMana = node.targetMana

func GetDistanceWeight(weightRef):
	var distance = (weightRef - weight) * (weightRef - weight)
	
	distance = sqrt(distance)
	return distance

func GetDistanceMana(targetManaRef):
	var distance = (targetManaRef - targetMana) * (targetManaRef - targetMana)
	
	distance = sqrt(distance)
	return distance

func AdjustWeight(targetManaRef, learningRate, influence):
	#OJA-STYLE LEARNING
	var normalisedMana = tools.NormaliseOneToTen(targetMana)
	var normalisedTarget = tools.NormaliseOneToTen(targetManaRef)
	
	targetMana = targetManaRef
	weight += influence * (learningRate * ((normalisedTarget * (normalisedMana * normalisedTarget)) - ((normalisedMana * normalisedTarget) * (normalisedMana * normalisedTarget) * normalisedMana)))

func AdjustMana(targetManaRef, learningRate, influence):
	#OJA-STYLE LEARNING
	var normalisedMana = tools.NormaliseOneToTen(targetMana)
	var normalisedTarget = tools.NormaliseOneToTen(targetManaRef)
	
	var mana = (normalisedTarget * (normalisedMana * normalisedTarget)) - ((normalisedMana * normalisedTarget) * (normalisedMana * normalisedTarget) * normalisedMana)
	if mana == 0:
		mana = normalisedMana
	
	targetMana += float(float(influence) * float(learningRate) * float(tools.RecombobulateOneToTen(mana)))
	
	#targetMana = float(influence) * float(learningRate) * (float(targetManaRef - targetMana) * float(targetManaRef - targetMana))

func AdjustQWeight(qWeightRef, learningRate, influence):
	#OJA-STYLE LEARNING
	qWeight += float(influence * float(learningRate * float((qWeightRef * (qWeight * qWeightRef)) - ((qWeight * qWeightRef) * (qWeight * qWeightRef) * qWeight))))

func ToString():
	return "[" + castingCardID + " : " + str(castingCardType) + " : " + str(targetMana) + " : " + str(qWeight) + "]"

func Save():
	var data = {}
	data.castingCardID = castingCardID
	data.castingCardType = castingCardType
	data.targetMana = targetMana
	data.qWeight = qWeight
	data.vector = vector
	
	return data
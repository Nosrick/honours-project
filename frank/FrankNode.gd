extends Node
 
#Identifying card information
var castingCardID
var castingCardType

#The mana value to target
var targetMana

#The weight of the card
var qWeight
 
var tools = load("res://Tools.gd").new()

#Initialise the node
func _init():
	castingCardID = "None"
	qWeight = randf()
	targetMana = 1
 
#Set the parameters from another node
func SetParameters(node):
	castingCardID = node.castingCardID
	castingCardType = node.castingCardType
	targetMana = node.targetMana
 
#Get the distance (in mana) from another node
func GetDistanceMana(targetManaRef):
	var distance = (targetManaRef - targetMana) * (targetManaRef - targetMana)  

	distance = sqrt(distance)
	return distance
 
#Adjust the mana of this node
#Uses Oja-style learning
#Tends towards 10 when winning
#NEEDS TO BE REWRITTEN
func AdjustMana(targetManaRef, learningRate, influence):
	#OJA-STYLE LEARNING
	var normalisedMana = tools.NormaliseOneToTen(targetMana)
	var normalisedTarget = tools.NormaliseOneToTen(targetManaRef)
	var mana = float(normalisedTarget * (normalisedMana * normalisedTarget)) - ((normalisedMana * normalisedTarget) * (normalisedMana * normalisedTarget) * normalisedMana)
	if mana == 0:
		mana = normalisedTarget
  
	var recombobulated = float(tools.RecombobulateOneToTen(mana))
  
	targetMana += float(float(influence) * float(learningRate) * recombobulated)

#Adjust the weight of this node
#Uses Oja-style learning
#Low granularity due to using whole numbers
func AdjustQWeight(qWeightRef, learningRate, influence):
	#OJA-STYLE LEARNING
	var newWeight = float(influence * float(learningRate * float((qWeightRef * (qWeight * qWeightRef)) - ((qWeight * qWeightRef) * (qWeight * qWeightRef) * qWeight))))
  
	qWeight += newWeight
 
func ToString():
	return "[" + castingCardID + " : " + str(castingCardType) + " : " + str(targetMana) + " : " + str(qWeight) + "]"
 
func Save():
	var data = {}
	data.castingCardID = castingCardID
	data.castingCardType = castingCardType
	data.targetMana = targetMana
	data.qWeight = qWeight
	  
	return data
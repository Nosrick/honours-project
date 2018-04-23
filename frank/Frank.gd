extends Node
 
var node = preload("FrankNode.gd")
var tools = load("res://Tools.gd").new()
 
var filePath = "res://myBrainFrank.json"
 
var nodes = []
var width
 
var learningRate = 0.3
 
func _init(widthRef):
  randomize()
  nodes = []
  width = widthRef
  
  for x in range(width):
    nodes.append(node.new())
 
func Epoch(newNode):
  var node = GetBestMatch(newNode)
  var influence = 0.5
  node.AdjustMana(newNode.targetMana, learningRate, influence)
  node.AdjustQWeight(newNode.qWeight, learningRate, influence)
 
func RandomUnassignedNode():
	var unassigned = []
	for node in nodes:
		if node.castingCardID == "None":
			unassigned.push_back(node)
	
	var result = randi() % unassigned.size()
	return unassigned[result]

func GetBestMatch(input):
  var lowestDistance = 9999999
  var winner = null
  
  for node in nodes:
    if input.castingCardID == node.castingCardID:
      var distance = node.GetDistanceMana(input.targetMana)
      if distance < lowestDistance:
        lowestDistance = distance
        winner = node
      
  return winner
 
func GetBestQScore(input):
	var highestQScore = -999
	var winner = null
  
	for node in nodes:
		if input.castingCardID == node.castingCardID:
			if node.qWeight > highestQScore:
				highestQScore = node.qWeight
				winner = node
	
	return winner

func Serialise():
	print("START SERIALISING")
	var brain = File.new()
	brain.open(filePath, File.WRITE)

	for node in nodes:
		var nodeData = node.Save()
		brain.store_line(nodeData.to_json())
  
	brain.close()
	print("DONE SERIALISING")
  
func Deserialise():
  var brain = File.new()
  if not brain.file_exists(filePath):
    return false
  
  brain.open(filePath, File.READ)
  
  nodes = []
  
  var currentLine = {}
  while(!brain.eof_reached()):
    currentLine.parse_json(brain.get_line())
    var newNode = node.new()
    newNode.castingCardID = currentLine.castingCardID
    newNode.castingCardType = currentLine.castingCardType
    newNode.targetMana = currentLine.targetMana
    #newNode.weight = currentLine.weight
    newNode.qWeight = currentLine.qWeight
    
    nodes.append(newNode)
  
  brain.close()
  width = nodes.size()
  return true
 
func ExtractVector(string):
  var xIndex = string.find(",")
  var x = string.substr(1, xIndex - 1)
  var y = string.substr(xIndex + 1, string.length() - 1)
  return Vector2(float(x), float(y))
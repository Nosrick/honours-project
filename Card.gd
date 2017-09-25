 extends Node

var name = "Debug Cat"
var image
var cost = 1
var power = 0
var toughness = 1
var keywords = []

func SetParameters(nameRef, costRef, powerRef, toughnessRef, keywordsRef, imageRef):
	name = nameRef
	image = imageRef
	cost = costRef
	power = powerRef
	toughness = toughnessRef
	keywords = keywordsRef

func SetDisplay():
	self.get_node("Container/Image").set_texture(image)
	self.get_node("Container/PowerToughness").set_text(str(power) + "/" + str(toughness))
	self.get_node("Container/Name").set_text(name)
	self.get_node("Container/Cost").set_text(str(cost))
	var displayWords = ""
	for i in range(keywords.size()):
		displayWords += keywords[i] + ", "
	
	displayWords = displayWords.substr(0, displayWords.length() - 2)
	self.get_node("Container/Keywords").set_text(displayWords)

func _ready():
	pass
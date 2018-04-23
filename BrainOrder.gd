extends Button

var tools = load("res://Tools.gd").new()

func Pressed():
	var brains = [0, 1, 2, 3]
	var randomOrder = []
	for i in range(4):
		var result = tools.Roll(0, brains.size())
		randomOrder.push_back(brains[result])
		brains.remove(result)
	
	randomOrder.push_back(4)
	GlobalVariables.brainOrder = randomOrder
	get_tree().change_scene("res://scenes/Root.tscn")
	
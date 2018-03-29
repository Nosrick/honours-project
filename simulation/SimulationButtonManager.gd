extends Node

var players = []
var simulating = false

func _ready():
	set_process(true)

func _process(delta):
	if players.size() == 1:
		get_tree().get_root().get_node("Root/Label").set_text("Choose Player 2")
	
	if players.size() == 2 and simulating == false:
		var learningManager = get_tree().get_root().get_node("Root")
		learningManager.brain1 = players[0]
		learningManager.brain2 = players[1]
		learningManager.AttachBrains()
		get_tree().get_root().get_node("Root/Label").set_text("Simulating")
		simulating = true
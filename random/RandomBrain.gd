extends Node

var player
var manager

var tools = load("tools.gd").new()

func _ready():
	manager = self.get_tree().get_root().get_node("Root/GameManager")
	set_process(true)

func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	if manager.phase == manager.DRAW_PHASE:
		player.Draw()
	
	var handChoice = tools.Roll(0, player.hand.size())
	var laneChoice = tools.Roll(0, 4)
	
	if player.hand[handChoice].cost > player.mana:
		return
	
	player.Summon(player.hand[handChoice], laneChoice)
	manager.EndTurn()
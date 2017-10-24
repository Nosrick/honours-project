extends Node

var player
var manager

var attempts = 0
const MAX_ATTEMPTS = 20

var tools = load("tools.gd").new()

func _ready():
	manager = self.get_tree().get_root().get_node("Root/GameManager")
	set_process(true)

func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	if attempts >= MAX_ATTEMPTS:
		manager.EndTurn()
	
	if manager.phase == manager.DRAW_PHASE:
		player.Draw()
		attempts = 0
	
	var handChoice = tools.Roll(0, player.hand.size())
	var laneChoice = tools.Roll(0, 4)
	
	attempts += 1
	
	if player.hand[handChoice].cost > player.mana:
		return
	
	player.Summon(player.hand[handChoice], laneChoice)
	manager.EndTurn()
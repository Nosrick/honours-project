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
	
	attempts += 1
	
	if player.hand[handChoice].cost > player.mana:
		return
	
	var actionChoice = tools.Roll(0, 2)
	
	if actionChoice == 0:
		var validLanes = []
		for lane in player.lanes:
			if lane.myCard == null:
				validLanes.push_back(lane.laneNumber)
		
		if validLanes.size() == 0:
			return
		
		var choice = tools.Roll(0, validLanes.size())
		var laneChoice = validLanes[choice]
		
		player.Summon(player.hand[handChoice], laneChoice)
	elif actionChoice == 1:
		var validLanes = []
		for lane in player.lanes:
			if lane.myCard != null:
				validLanes.push_back(lane.laneNumber)
		
		if validLanes.size() == 0:
			return
		
		var choice = tools.Roll(0, validLanes.size())
		var laneChoice = validLanes[choice]
		
		player.Enhance(player.hand[handChoice], player.lanes[laneChoice].myCard)
	
	manager.EndTurn()
extends Node

var player
var otherPlayer
var manager

var attempts = 0
const MAX_ATTEMPTS = 50

var tools = load("Tools.gd").new()

var hasActed = false

func StartTurn():
	hasActed = false
	attempts = 0

func _ready():
	manager = self.get_tree().get_root().get_node("Root/GameManager")
	set_process(true)

func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	if hasActed == true:
		return
	
	if attempts >= MAX_ATTEMPTS:
		hasActed = true
		manager.EndTurn()
	
	var handChoice = tools.Roll(0, player.hand.size())
	
	attempts += 1
	
	if player.hand[handChoice].cost > player.mana:
		return
	
	var card = player.hand[handChoice]
	if card.type == card.CREATURE:
		var validLanes = []
		for lane in player.lanes:
			if lane.myCard == null:
				validLanes.push_back(lane.laneNumber)
		
		if validLanes.size() == 0:
			return
		
		var choice = tools.Roll(0, validLanes.size())
		var laneChoice = validLanes[choice]
		
		player.Summon(card, laneChoice)
	elif card.type == card.SPELL:
		var validLanes = []
		if card.keywords.has("Enhancement"):
			for lane in player.lanes:
				if lane.myCard != null:
					validLanes.push_back(lane.laneNumber)
			
			if validLanes.size() == 0:
				return
			
			var choice = tools.Roll(0, validLanes.size())
			var laneChoice = validLanes[choice]
			
			player.Enhance(card, player.lanes[laneChoice].myCard)
		elif card.keywords.has("Hinderance"):
			for lane in otherPlayer.lanes:
				if lane.myCard != null:
					validLanes.push_back(lane.laneNumber)
			
			if validLanes.size() == 0:
				return
			
			var choice = tools.Roll(0, validLanes.size())
			var laneChoice = validLanes[choice]
			
			player.Hinder(card, otherPlayer.lanes[laneChoice].myCard)

func EndGame():
	pass
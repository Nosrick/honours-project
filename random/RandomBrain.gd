extends Node

#Player, opponent and game manager
var player
var otherPlayer
var manager

#Attempts and maximum number of attempts before end of turn
var attempts = 0
const MAX_ATTEMPTS = 50

var tools = load("Tools.gd").new()

#To make sure we don't interrupt the game manager trying to end our turn constantly
var hasActed = false

#Telemetry
var turnTime = 0

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
	
	#Measuring turn time
	turnTime += delta
	
	#If we've reached the maximum number of attempts, end our turn
	if attempts >= MAX_ATTEMPTS:
		hasActed = true
		manager.EndTurn()
		return
	
	#Or if we're our of cards
	if player.hand.size() == 0:
		manager.EndTurn()
		hasActed = true
		return
	
	#Pick a card in hand at random
	var handChoice = tools.Roll(0, player.hand.size())
	
	attempts += 1
	
	#If it's too expensive, return
	if player.hand[handChoice].cost > player.mana:
		return
	
	#If it's a creature
	var card = player.hand[handChoice]
	if card.type == card.CREATURE:
		#Find the valid lanes
		var validLanes = []
		for lane in player.lanes:
			if lane.myCard == null:
				validLanes.push_back(lane.laneNumber)
		
		#If there are no valid lanes, return
		if validLanes.size() == 0:
			return
		
		#Pick a valid lane
		var choice = tools.Roll(0, validLanes.size())
		var laneChoice = validLanes[choice]
		
		#Summon the card to the valid lane
		player.Summon(card, laneChoice)
	
	#If it's a spell
	elif card.type == card.SPELL or card.type == card.INSTANT:
		var validLanes = []
		#Specifically, an enhancement
		if card.keywords.has("Enhancement"):
			
			#Look for lanes that have friendly creatures in them
			for lane in player.lanes:
				if lane.myCard != null:
					validLanes.push_back(lane.laneNumber)
			
			#If there aren't any, return
			if validLanes.size() == 0:
				return
			
			#Otherwise, pick a lane
			var choice = tools.Roll(0, validLanes.size())
			var laneChoice = validLanes[choice]
			
			#And enhance the creature
			player.Enhance(card, player.lanes[laneChoice].myCard)
		
		#If it's a hindrance
		elif card.keywords.has("Hinderance"):
			#Do the same as above
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
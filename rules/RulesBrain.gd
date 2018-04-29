extends Node

#Player, opposing player, and game manager
var player
var otherPlayer
var manager

var tools = load("Tools.gd").new()

#Just here to prevent errors
var trainingCards

#Stops this from acting out against the game manager and ending the turn constantly
var hasActed = false

const name = "RulesBrain"

#For telemetry
var turnTime = 0

func Begin():
	set_process(true)

func _ready():
	manager = self.get_tree().get_root().get_node("Root/GameManager")
	Begin()

func StartTurn():
	hasActed = false

func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	if hasActed == true:
		return
	
	turnTime += delta
	
	#For each card in hand, try to do something
	for card in player.hand:
		#If it's a creature,
		if card.type == card.CREATURE:
			#Prioritise protecting ourselves
			for i in range(0, player.lanes.size()):
				if otherPlayer.lanes[i].myCard != null and player.lanes[i].myCard == null:
					player.Summon(card, i)
			
			#Then take advantage of open lanes
			for i in range(0, player.lanes.size()):
				if player.lanes[i].myCard == null:
					player.Summon(card, i)
		
		if card.type == card.SPELL or card.type == card.INSTANT:
			#If it's an enhancement
			if card.keywords.has("Enhancement"):
				var lowestMana = 999
				var lowestLane = null
				for lane in player.lanes:
					if lane.myCard != null:
						var mana = CalculateMana(lane.myCard)
						if mana < lowestMana:
							lowestMana = mana
							lowestLane = lane
				
				if lowestLane != null: 
					#Play it on our lowest mana card to make it better
					player.Enhance(card, lowestLane.myCard)
			
			#If it's a hindrance
			elif card.keywords.has("Hinderance"):
				var highestMana = 0
				var highestLane = null
				for lane in otherPlayer.lanes:
					if lane.myCard != null:
						var mana = CalculateMana(lane.myCard)
						if mana > highestMana:
							highestMana = mana
							highestLane = lane
				
				if highestLane != null:
					#Play it on the highest mana opponent's card to make it worse
					player.Hinder(card, highestLane.myCard)
	
	manager.EndTurn()
	hasActed = true

func CalculateMana(card):
	var manaValue = 0
	manaValue += card.cost
	for enhancement in card.enhancements:
		manaValue += enhancement.cost
	
	for hinderance in card.hinderances:
		manaValue -= hinderance.cost
	
	return manaValue

func EndGame():
	set_process(false)
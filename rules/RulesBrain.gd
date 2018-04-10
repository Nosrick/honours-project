extends Node

var player
var otherPlayer
var manager

var tools = load("Tools.gd").new()

var trainingCards

var brain

const name = "RulesBrain"

func Begin():
	set_process(true)

func _process(delta):
	if not manager.IsMyTurn(player):
		return
		
	if manager.phase == manager.DRAW_PHASE:
		player.Draw()
		
	var lanesEmpty = []
	for i in range(player.lanes.size()):
		if player.lanes[i].myCard == null:
			lanesEmpty.push_back(i)
			break
	
	#Lanes are full, or no actions possible, so do some other actions
	for card in player.hand:
		if card.type == card.CREATURE:
			for i in range(0, player.lanes.size()):
				if otherPlayer.lanes[i].myCard != null and player.lanes[i].myCard == null:
					player.Summon(card, i)
			
			for i in range(0, player.lanes.size()):
				if player.lanes[i].myCard == null:
					player.Summon(card, i)
		
		if card.type == card.SPELL or card.type == card.INSTANT:
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
					player.Enhance(card, lowestLane.myCard)
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
					player.Hinder(card, highestLane.myCard)
	
	manager.EndTurn()

func CalculateMana(card):
	var manaValue = 0
	manaValue += card.cost
	for enhancement in card.enhancements:
		manaValue += enhancement.cost
	
	for hinderance in card.hinderances:
		manaValue -= hinderance.cost
	
	return manaValue

func _ready():
	manager = self.get_tree().get_root().get_node("Root/GameManager")

func EndGame():
	set_process(false)
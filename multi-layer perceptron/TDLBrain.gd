extends Node

var score
var brain

var player
var otherPlayer
var manager

var tools = load("res://Tools.gd").new()

var manaNodeTemplate = load("res://multi-layer perceptron/ManaMLPNeuralNode.gd")
var cardNodeTemplate = load("res://multi-layer perceptron/CardMLPNeuralNode.gd")

var trainingCards

var lastActions = []
var actionsSinceLastTry = 0

var stuck = false

var simulation
var simMe
var simThem

func _ready():
	brain = load("res://multi-layer perceptron/MultiLayerPerceptron.gd").new()
	
	if brain.Deserialise() == false:
		brain.Training(trainingCards)
	
	manager = self.get_tree().get_root().get_node("Root/GameManager")
	set_process(true)

func SortByWeight(left, right):
	if left.node.weight < right.node.weight:
		return true
		
	return false

func IsWithinOne(number, target):
	if number - 1.0 < target and number + 1.0 > target:
		return true
	
	return false

func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	if manager.phase == manager.DRAW_PHASE:
		player.Draw()
		stuck = false
	
	actionsSinceLastTry = lastActions.size()
	
	var actions = []
	
	for card in player.hand:
		if card.cost > player.mana:
			continue
		
		var node = brain.GetCardNode(card)
		
		var action = {}
		action.card = card
		action.node = node
		action.tried = false
		actions.push_back(action)
	
	actions.sort_custom(self, "SortByWeight")
	
	var attempts = 0
	if actions.size() != 0:
		while actions.size() > 0 and attempts < 10:
			SetUpSimulation()
			
			#pop the front of the queue
			var action = actions[0]
			actions.pop_front()
			var card = action.card
			var node = action.node
			var tried = action.tried
			
			if card != null:
				#Is it a creature?
				if card.type == card.CREATURE:
					var playedCreature = false
					
					#look at enemy lanes
					for i in range(otherPlayer.lanes.size()):
						#if theirs are full, and ours are empty, play the creature
						if otherPlayer.lanes[i].myCard != null and player.lanes[i].myCard == null:
							var simSummon = simMe.Summon(card, i)
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x
							print("Predicted: " + str(predictedBoardState) + " : Current: " + str(currentBoardState))
							
							if difference > 0:
								playedCreature = player.Summon(card, i)
							
						if playedCreature == true:
							lastActions.push_back(node)
							break
					
					for i in range(player.lanes.size()):
						#If ours are empty, play the creature
						if player.lanes[i].myCard == null:
							playedCreature = player.Summon(card, i)
							break
				
				if card.type == card.SPELL or card.type == card.INSTANT:
					var playedSpell = false
					if card.keywords.has("Enhancement"):
						for i in range(player.lanes.size()):
							if player.lanes[i].myCard == null:
								continue
							
							var simEnhance = simMe.Enhance(card, simMe.lanes[i].myCard)
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x - differenceVector.y
							print("Predicted: " + str(predictedBoardState) + " : Current: " + str(currentBoardState))
							
							if difference > 0:
								playedSpell = player.Enhance(card, player.lanes[i].myCard)
							
							if playedSpell == false:
								var newAction = {}
								
								if tried == true:
									attempts += 1
								else:
									newAction.card = card
									newAction.node = node
									newAction.tried = true
									actions.push_back(newAction)
									attempts += 1
								
							else:
								lastActions.push_back(node)
								break
							
					elif card.keywords.has("Hinderance"):
						for i in range(otherPlayer.lanes.size()):
							if otherPlayer.lanes[i].myCard == null:
								continue
							
							var simHinder = simMe.Hinder(card, simThem.lanes[i].myCard)
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x - differenceVector.y
							print("Predicted: " + str(predictedBoardState) + " : Current: " + str(currentBoardState))
							
							if difference > 0:
								playedSpell = player.Hinder(card, otherPlayer.lanes[i].myCard)
							"""
							else:
								brain.AdjustManaWeight(node, node.GetBestMana())
								playedSpell = player.Hinder(card, otherPlayer.lanes[i].myCard)
							"""
							if playedSpell == true:
								lastActions.push_back(node)
								break

	var actionsThisTry = lastActions.size()
	
	if actionsThisTry == actionsSinceLastTry:
		if stuck == false:
			stuck = true
			var lowestWeight = 999
			var lowestCard = null
			
			for card in player.hand:
				var node = brain.GetCardNode(card)
				if node.weight < lowestWeight:
					lowestWeight = node.weight
					lowestCard = card
				
			player.Replace(lowestCard)
			return
			
		var boardState = CalculateBoardState(player, otherPlayer)
		brain.Epoch(boardState, 0.3, 0.3)
		
		manager.EndTurn()

func SetUpSimulation():
	simMe = load("res://multi-layer perceptron/SimulationPlayer.gd").new(player.hand, player.deck, player.mana, player.currentHP)
	simMe.FillLanes(player.lanes)
	
	simThem = load("res://multi-layer perceptron/SimulationPlayer.gd").new(otherPlayer.hand, otherPlayer.deck, otherPlayer.mana, otherPlayer.currentHP)
	simThem.FillLanes(otherPlayer.lanes)
	
	simMe.otherPlayer = simThem
	simThem.otherPlayer = simMe
	
	simulation = load("res://multi-layer perceptron/SimulationManager.gd").new()
	simulation.phase = simulation.PLAY_PHASE
	simulation.player1 = simThem
	simulation.player2 = simMe
	simulation.turnPlayer = simMe
	simulation.cards = manager.cards
	
	simMe.manager = simulation
	simThem.manager = simulation

func CalculateBoardState(player1, player2):
	#Do our side first
	var ourSide = 0
	for lane in player1.lanes:
		if lane.myCard != null:
			ourSide += CalculateMana(lane.myCard)
	
	var theirSide = 0
	for lane in player2.lanes:
		if lane.myCard != null:
			theirSide += CalculateMana(lane.myCard)
	
	return Vector2(ourSide, theirSide)

func CalculateMana(card):
	var manaValue = 0
	manaValue += card.cost
	for enhancement in card.enhancements:
		manaValue += enhancement.cost
	
	for hinderance in card.hinderances:
		manaValue -= hinderance.cost
	
	return manaValue

func EndGame():
	brain.Serialise()
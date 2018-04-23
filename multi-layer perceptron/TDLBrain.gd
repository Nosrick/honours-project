extends Node

const name = "TDLBrain"

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

var gameActions = []

var hasActed = false

var turnTime = 0

func _ready():
	Begin()

func Begin():
	brain = load("res://multi-layer perceptron/MultiLayerPerceptron.gd").new()
	
	if brain.Deserialise() == false:
		brain.Initialisation(trainingCards)
	
	if self.get_tree() != null:
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

func StartTurn():
	hasActed = false
	stuck = false

func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	if hasActed == true:
		return
	
	turnTime += delta
	
	actionsSinceLastTry = lastActions.size()
	
	var actions = []
	
	var inputList = []
	
	print("BEGIN HAND")
	for card in player.hand:
		print(card.ToString())
		inputList.push_back(card)
	print("END HAND")
	
	if inputList.size() != 6:
		for i in range(0, 6 - inputList.size()):
			inputList.push_back(null)
	
	for lane in player.lanes:
		inputList.push_back(lane.myCard)
	
	for lane in otherPlayer.lanes:
		inputList.push_back(lane.myCard)
	
	inputList.push_back(player.mana)
	
	var nodes = brain.Reason(inputList)
	
	for node in nodes:
		var action = {}
		action.node = node
		action.tried = false
		actions.push_back(action)
	
	var attempts = 0
	if actions.size() != 0:
		while actions.size() > 0 and attempts < 20:
			#pop the front of the queue
			var action = actions[0]
			actions.pop_front()
			var node = action.node
			var card = null
			for cardInHand in player.hand:
				if cardInHand.name == node.castingCardID:
					card = cardInHand
					break
			
			var tried = action.tried
			
			if card != null:
				#Is it a creature?
				if card.type == card.CREATURE:
					var playedCreature = false
					
					#look at enemy lanes
					for i in range(otherPlayer.lanes.size()):
						#if theirs are full, and ours are empty, play the creature
						if otherPlayer.lanes[i].myCard != null and player.lanes[i].myCard == null:
							SetUpSimulation()
							var simSummon = simMe.Summon(card, i)
							if simSummon == false:
								DestroySimulation()
								continue
							
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							DestroySimulation()
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x
							print("Predicted: " + str(predictedBoardState) + " : Current: " + str(currentBoardState))
							
							if difference > 0:
								#HACK TO ENSURE SIMULATION DOES NOT STOP US FROM PLAYING CREATURES
								card.inPlay = false
								playedCreature = player.Summon(card, i)
								gameActions.push_back(predictedBoardState)
								#brain.Epoch(predictedBoardState, 0.3)
							
						if playedCreature == true:
							lastActions.push_back(node)
							break
					
					for i in range(player.lanes.size()):
						#If ours are empty, play the creature
						if player.lanes[i].myCard == null:
							playedCreature = player.Summon(card, i)
							if playedCreature == true:
								break
				
				elif card.type == card.SPELL or card.type == card.INSTANT:
					var playedSpell = false
					if card.keywords.has("Enhancement"):
						var laneIndex = -1
						var highestScore = -1
						
						for i in range(player.lanes.size()):
							if player.lanes[i].myCard == null:
								continue
							
							SetUpSimulation()
							var simEnhance = simMe.Enhance(card, simMe.lanes[i].myCard)
							if simEnhance == false:
								DestroySimulation()
								continue
							
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							DestroySimulation()
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x - differenceVector.y
							print("Predicted: " + str(predictedBoardState) + " : Current: " + str(currentBoardState))
							
							if difference > 0:
								#playedSpell = player.Enhance(card, player.lanes[i].myCard)
								if highestScore < difference:
									highestScore = difference
									laneIndex = i
									gameActions.push_back(predictedBoardState)
									#brain.Epoch(predictedBoardState, 0.3)
						
						if laneIndex != -1:
							#HACK TO ENSURE SIMULATION DOES NOT STOP US FROM PLAYING SPELLS
							card.inPlay = false
							playedSpell = player.Enhance(card, player.lanes[laneIndex].myCard)
						
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
							var laneIndex = -1
							var highestScore = -1
						
							if otherPlayer.lanes[i].myCard == null:
								continue
							
							SetUpSimulation()
							if ValidateSimulation() == false:
								print("INVALID SIMULATION")
								print(card.ToString())
								var previousCard = simThem.lanes[i].myCard
							
							var simHinder = simMe.Hinder(card, simThem.lanes[i].myCard)
							if simHinder == false:
								DestroySimulation()
								continue
							
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							DestroySimulation()
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x - differenceVector.y
							print("Predicted: " + str(predictedBoardState) + " : Current: " + str(currentBoardState))
							
							if difference > 0:
								if difference > highestScore:
									highestScore = difference
									laneIndex = i
									gameActions.push_back(predictedBoardState)
									#brain.Epoch(predictedBoardState, 0.3)
							
							if laneIndex != -1:
								#HACK TO ENSURE SIMULATION DOES NOT STOP US FROM PLAYING CREATURES
								card.inPlay = false
								playedSpell = player.Hinder(card, otherPlayer.lanes[laneIndex].myCard)
							
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
	
	if stuck == true:
		manager.EndTurn()
		hasActed = true

func SetUpSimulation():
	simMe = load("res://simulation/SimulationPlayer.gd").new(player.hand, player.deck, player.mana, player.currentHP, player.discardPile)
	simMe.FillLanes(player.lanes)
	
	simThem = load("res://simulation/SimulationPlayer.gd").new(otherPlayer.hand, otherPlayer.deck, otherPlayer.mana, otherPlayer.currentHP, player.discardPile)
	simThem.FillLanes(otherPlayer.lanes)
	
	simMe.otherPlayer = simThem
	simThem.otherPlayer = simMe
	
	simulation = load("res://simulation/SimulationManager.gd").new()
	simulation.phase = simulation.PLAY_PHASE
	simulation.player1 = simThem
	simulation.player2 = simMe
	simulation.turnPlayer = simMe
	simulation.cards = manager.cards
	
	simMe.manager = simulation
	simThem.manager = simulation

func DestroySimulation():
	#simMe.End()
	simMe.free()
	
	#simThem.End()
	simThem.free()
	
	simulation.free()

func ValidateSimulation():
	for i in range(0, player.lanes.size()):
		if player.lanes[i].myCard != null and simMe.lanes[i].myCard == null:
			return false
		
		if otherPlayer.lanes[i].myCard != null and simThem.lanes[i].myCard == null:
			return false
		
	if simMe.hand.size() != player.hand.size():
		return false
	
	if simThem.hand.size() != otherPlayer.hand.size():
		return false
		
		return true

func InvalidateSimulation():
	get_tree().get_root().get_node("Root").GameOver()
	get_tree().get_root().get_node("Root/Label").set_text("INVALID SIMULATION")

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
	var currentValue = 0
	currentValue += card.cost + card.currentHP
	for enhancement in card.enhancements:
		currentValue += enhancement.cost
	
	for hinderance in card.hinderances:
		currentValue -= hinderance.cost
	
	return currentValue

func EndGame():
	for gameAction in gameActions:
		brain.Epoch(gameAction, 0.3)
	
	gameActions.clear()
	
	set_process(false)
	brain.Serialise()
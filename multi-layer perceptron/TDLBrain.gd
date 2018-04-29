extends Node

const name = "TDLBrain"

#Should ideally be called 'interface'
var brain

#Player, opposing player and game manager
var player
var otherPlayer
var manager

var tools = load("res://Tools.gd").new()

#Mana and card node templates, for instantiating
var manaNodeTemplate = load("res://multi-layer perceptron/ManaMLPNeuralNode.gd")
var cardNodeTemplate = load("res://multi-layer perceptron/CardMLPNeuralNode.gd")

#Cards used for initial training of the brain
var trainingCards

#The action queue
var lastActions = []
var actionsSinceLastTry = 0

#For checking if we're stuck without any actions
#So we can end our turn
var stuck = false

#Simulation stuff
var simulation
var simMe
var simThem

#Used for learning
var gameActions = []

#Used for ending the turn and not acting any further
var hasActed = false

#Telemetry stuff
var turnTime = 0

func _ready():
	Begin()

#Initialise the interface
func Begin():
	#Create a new interface
	brain = load("res://multi-layer perceptron/MultiLayerPerceptron.gd").new()
	
	#Try to deserialise the interface
	if brain.Deserialise() == false:
		#If we can't, just train a new one
		brain.Initialisation(trainingCards)
	
	#Get the game manager
	if self.get_tree() != null:
		manager = self.get_tree().get_root().get_node("Root/GameManager")
	set_process(true)

#Sort the output nodes by weight
func SortByWeight(left, right):
	if left.node.weight < right.node.weight:
		return true
		
	return false

#A simple check to see if the mana value is within one of the target
func IsWithinOne(number, target):
	if number - 1.0 < target and number + 1.0 > target:
		return true
	
	return false

#Reset the action flags
func StartTurn():
	hasActed = false
	stuck = false

#The real meat of the class
func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	#If we've acted this turn, return
	if hasActed == true:
		return
	
	#Measuring turn time
	turnTime += delta
	
	#For seeing if we're stuck
	actionsSinceLastTry = lastActions.size()
	
	#The action list
	var actions = []
	
	#The input list for reasoning
	var inputList = []
	
	#Print the hand and add it to the input list
	print("BEGIN HAND")
	for card in player.hand:
		print(card.ToString())
		inputList.push_back(card)
	print("END HAND")
	
	#Fill any gaps in the hand
	if inputList.size() != 6:
		for i in range(0, 6 - inputList.size()):
			inputList.push_back(null)
	
	#Fill the input list with our lanes
	for lane in player.lanes:
		inputList.push_back(lane.myCard)
	
	#Fill the input list with their lanes
	for lane in otherPlayer.lanes:
		inputList.push_back(lane.myCard)
	
	#And finally with how much mana we have
	inputList.push_back(player.mana)
	
	#Reason for this hand
	var nodes = brain.Reason(inputList)
	
	#Push the nodes into the action queue
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
			
			#Find the card for this node
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
							
							#Try to summon our creature to the simulation
							var simSummon = simMe.Summon(card, i)
							
							#If it fails, just destroy the simulation
							if simSummon == false:
								DestroySimulation()
								continue
							
							#If it succeeds, calculate the simulated board state
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							
							#Clean up the simulation, we no longer need it
							DestroySimulation()
							
							#Work out the current board state
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							
							#And begin to work out the difference
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x
							print("Predicted: " + str(predictedBoardState) + " : Current: " + str(currentBoardState))
							
							#If the difference is positive:
							if difference > 0:
								#HACK TO ENSURE SIMULATION DOES NOT STOP US FROM PLAYING CREATURES
								card.inPlay = false
								#Play the card
								playedCreature = player.Summon(card, i)
								
								#Add the predicted board state to our list of actions for this game
								#Used later for processing into rewards
								gameActions.push_back(predictedBoardState)
								#brain.Epoch(predictedBoardState, 0.3)
						
						#If a creature was played...
						if playedCreature == true:
							#...push this node onto the successful action queue
							lastActions.push_back(node)
							break
					
					for i in range(player.lanes.size()):
						#If ours are empty, play the creature
						if player.lanes[i].myCard == null:
							playedCreature = player.Summon(card, i)
							if playedCreature == true:
								break
				
				#This is basically the same rigamarole but for spells and instant enhancements
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
							
					#And the same thing for hindrances
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
	
	#Check if we're stuck, by comparing the number of actions we did this time around
	#To the number of actions we did last time
	if actionsThisTry == actionsSinceLastTry:
		if stuck == false:
			#If we're stuck
			stuck = true
			var lowestWeight = 999
			var lowestCard = null
			
			#Replace our least useful card
			for card in player.hand:
				var node = brain.GetCardNode(card)
				if node.weight < lowestWeight:
					lowestWeight = node.weight
					lowestCard = card
				
			player.Replace(lowestCard)
			return
			
		var boardState = CalculateBoardState(player, otherPlayer)
	
	#If we're well and truly stuck, end our turn
	if stuck == true:
		manager.EndTurn()
		hasActed = true

#Setting up the simulation. It's an arduous process.
func SetUpSimulation():
	#Setting up our simulation selves
	simMe = load("res://simulation/SimulationPlayer.gd").new(player.hand, player.deck, player.mana, player.currentHP, player.discardPile)
	simMe.FillLanes(player.lanes)
	
	#Setting up our simulation opponent
	simThem = load("res://simulation/SimulationPlayer.gd").new(otherPlayer.hand, otherPlayer.deck, otherPlayer.mana, otherPlayer.currentHP, player.discardPile)
	simThem.FillLanes(otherPlayer.lanes)
	
	#Setting up the opposing players
	simMe.otherPlayer = simThem
	simThem.otherPlayer = simMe
	
	#Setting up the simulation manager
	simulation = load("res://simulation/SimulationManager.gd").new()
	simulation.phase = simulation.PLAY_PHASE
	simulation.player1 = simThem
	simulation.player2 = simMe
	simulation.turnPlayer = simMe
	simulation.cards = manager.cards
	
	#Setting the simulation manager for the players
	simMe.manager = simulation
	simThem.manager = simulation

#Freeing up the simulation stuff
func DestroySimulation():
	#simMe.End()
	simMe.free()
	
	#simThem.End()
	simThem.free()
	
	simulation.free()

#Validates the simulation to make sure nothing has gone wrong in the creation process
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

#Displays an error message
func InvalidateSimulation():
	get_tree().get_root().get_node("Root").GameOver()
	get_tree().get_root().get_node("Root/Label").set_text("INVALID SIMULATION")

#Calculates the board state of the game
func CalculateBoardState(player1, player2):
	#Do our side first
	var ourSide = 0
	for lane in player1.lanes:
		if lane.myCard != null:
			ourSide += CalculateMana(lane.myCard)
	
	#Then the opponent's side
	var theirSide = 0
	for lane in player2.lanes:
		if lane.myCard != null:
			theirSide += CalculateMana(lane.myCard)
	
	return Vector2(ourSide, theirSide)

#Takes into account mana cost and current HP
func CalculateMana(card):
	var currentValue = 0
	currentValue += card.cost + card.currentHP
	for enhancement in card.enhancements:
		currentValue += enhancement.cost
	
	for hinderance in card.hinderances:
		currentValue -= hinderance.cost
	
	return currentValue

func EndGame():
	hasActed = true
	set_process(false)
	#Learning time!
	for gameAction in gameActions:
		brain.Epoch(gameAction, 0.3)
	
	gameActions.clear()
	
	brain.Serialise()
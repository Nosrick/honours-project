extends Node

const name = "FrankBrain"

#Should probably be called "interface"
var brain

#The player, opposing player and game manager
var player
var otherPlayer
var manager

#Board states
var boardState = Vector2()
var lastBoardState = Vector2()

#The actions taken this turn
var lastActions = []

#The actions we're about to take
var actionsToProcess = []

var tools = load("res://Tools.gd").new()
var cardNode = load("res://q-learner/CardQLearnerNeuralNode.gd")

#Cards to train ourselves with
var trainingCards = []

#End of turn stuff
var stuck = false
var actionTaken = false

const INFLUENCE = 0.5

#Simulation stuff
var simMe
var simThem
var simulation

#Telemetry stuff
var turnTime = 0

#Board states, used for reward calculation
var previousBoardState = Vector2()
var currentBoardState = Vector2()

#Gets the simulation ready for simulating
func SetUpSimulation():
	#Set up the 'us' analogue
	#Hand, deck, mana, current hit points, discard pile, in that order
	simMe = load("res://simulation/SimulationPlayer.gd").new(player.hand, player.deck, player.mana, player.currentHP, player.discardPile)
	#Fill the lanes with what we have already
	simMe.FillLanes(player.lanes)
	
	#Do the same for 'them'
	simThem = load("res://simulation/SimulationPlayer.gd").new(otherPlayer.hand, otherPlayer.deck, otherPlayer.mana, otherPlayer.currentHP, player.discardPile)
	simThem.FillLanes(otherPlayer.lanes)
	
	#Set the other players to them and us (sorry, it's a little confusing, I know)
	simMe.otherPlayer = simThem
	simThem.otherPlayer = simMe
	
	#Get the simulation manager ready
	simulation = load("res://simulation/SimulationManager.gd").new()
	
	#Set up the initial state
	simulation.phase = simulation.PLAY_PHASE
	
	#Set up the players
	simulation.player1 = simThem
	simulation.player2 = simMe
	simulation.turnPlayer = simMe
	
	#Set up the available cards
	simulation.cards = manager.cards
	
	#Give the players their manager
	simMe.manager = simulation
	simThem.manager = simulation

#Free the memory from the simulation
func DestroySimulation():
	#simMe.End()
	simMe.free()
	
	#simThem.End()
	simThem.free()
	
	simulation.free()

#Make sure nothing wacky has happened to the simulation
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

func StartTurn():
	stuck = false
	actionTaken = false

#Train the network
func InitialTraining(deck):
	var nodes = []
	
	#For each card in the deck...
	for card in deck:
		#...Get a random unassigned node
		var node = brain.RandomUnassignedNode()
		
		#Set up the parameters
		node.castingCardID = card.name
		node.castingCardType = card.type
		node.targetMana = card.cost
		
		#and push it onto the nodes list
		nodes.push_back(node)
	
	#Then do an epoch on each node
	for node in nodes:
		brain.Epoch(node)

#Simply create a node for a new card
func ManufactureNode(card):
	var node = brain.RandomUnassignedNode()
	
	node.castingCardID = card.name
	node.castingCardType = card.type
	node.targetMana = card.cost
	
	brain.Epoch(node)

#Used to sort the AI's hand by qWeight
func SortHand(left, right):
	if left.activeNode.qWeight < right.activeNode.qWeight:
		return true
	
	return false

func _ready():
	Begin()

#Called at the start of a game
func Begin():
	brain = load("res://frank/Frank.gd").new(trainingCards.size() * 2)
	
	#Try to deserialise
	if brain.Deserialise() == false:
		#If we can't, just train a new brain
		InitialTraining(trainingCards)
	
	#Get the manager
	if self.get_tree() != null:
		manager = self.get_tree().get_root().get_node("Root/GameManager")
	
	#Set our processes to begin
	set_process(true)

func _process(delta):
	#If it's not our turn, return
	if not manager.IsMyTurn(player):
		return
	
	#If we've acted this turn, return
	if actionTaken == true:
		return
	
	#Measure our turn time
	turnTime += delta
	
	var actionsSinceLastTry = lastActions.size()
	
	#Find approximate Q-score for each card
	var highestQScore = -999
	var highestCard = null
	var activeNode = null
	
	var cardsInHand = []
	#Go through the hand, one card at a time
	for card in player.hand:
		#Get the node matching the card
		var node = cardNode.new()
		node.castingCardID = card.name
		var qScoreNode = brain.GetBestQScore(node)
		
		#If there's no matching node, make one!
		if qScoreNode == null:
			ManufactureNode(card)
			qScoreNode = brain.GetBestQScore(node)
		
		#If it's above our current playable mana, skip it
		if card.cost > player.mana:
			continue
		
		#If it's possible to play it, add it to the queue
		var pair = {}
		pair.highestCard = card
		pair.activeNode = qScoreNode
		pair.tried = false
		cardsInHand.push_back(pair)
	
	#Then, we sort them based on their q-weight
	cardsInHand.sort_custom(self, "SortHand")
	
	for card in cardsInHand:
		actionsToProcess.push_back(card)
	
	var attempts = 0
	if actionsToProcess.size() != 0:
		while actionsToProcess.size() > 0 and attempts < 10:
			#pop the front of the queue
			var pair = actionsToProcess[0]
			actionsToProcess.pop_front()
			var highestCard = pair.highestCard
			var activeNode = pair.activeNode
			var tried = pair.tried
			
			if highestCard != null:
				#Is it a creature?
				if highestCard.type == highestCard.CREATURE:
					var playedCreature = false
					
					var greatestChangeIndex = -1
					var greatestChange = -999
					#look at enemy lanes
					for i in range(otherPlayer.lanes.size()):
						SetUpSimulation()
						
						#if theirs are full, and ours are empty, play the creature
						if otherPlayer.lanes[i].myCard != null and player.lanes[i].myCard == null:
							var simSummon = simMe.Summon(highestCard, i)
							if simSummon == false:
								continue
							
							#Figure out the new board state after summoning the creature in the simulation
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							
							#Destroy the simulation; we don't need it now
							DestroySimulation()
							
							#Calculate our current board state
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							
							#And find the difference between the predicted board state and our actual board state
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x - differenceVector.y
							
							#If the difference is greatest in this lane, mark it so
							if difference > greatestChange:
								greatestChange = difference
								greatestChangeIndex = i
							
							#playedCreature = player.Summon(highestCard, i)
					
					#If we've got a lane
					if greatestChangeIndex != -1:
						#Do the simulation inPlay hack, because shallow copies suck
						highestCard.inPlay = false
						
						#Summon the creature to this lane
						playedCreature = player.Summon(highestCard, greatestChangeIndex)
					
					#If we played a creature...
					if playedCreature == true:
						#...push that action onto the action list
						lastActions.push_back(activeNode)
					
					#If our lanes are empty, play the creature
					for i in range(player.lanes.size()):
						if player.lanes[i].myCard == null:
							playedCreature = player.Summon(highestCard, i)
					
				#Or is it a spell/instant?
				if highestCard.type == highestCard.SPELL or highestCard.type == highestCard.INSTANT:
					#Is it an enhancement or a hinderance?
					if highestCard.keywords.has("Enhancement"):
						var playedSpell = false
						
						#Look to see if we have something that matches the target mana cost
						for i in range(player.lanes.size()):
							if player.lanes[i].myCard == null:
								continue
							
							#If it's within one mana of the target value, let's use it
							if IsWithinOne(player.lanes[i].myCard.cost, activeNode.targetMana):
								playedSpell = player.Enhance(highestCard, player.lanes[i].myCard)
							#If it's not, adjust the mana towards the new value
							else:
								activeNode.AdjustMana(player.lanes[i].myCard.cost, brain.learningRate, INFLUENCE)
								playedSpell = player.Enhance(highestCard, player.lanes[i].myCard)
								
							if playedSpell == false:
								#If the actions fails, push it back onto the stack to try again later in the turn
								var pair = {}
								
								#If this action has been attempted before, remove it
								if tried == true:
									attempts += 1
								#Otherwise, push it to the back
								else:
									pair.highestCard = highestCard
									pair.activeNode = activeNode
									pair.tried = true
									actionsToProcess.push_back(pair)
									attempts += 1
							else:
								lastActions.push_back(activeNode)
								
						
					elif highestCard.keywords.has("Hinderance"):
						var playedSpell = false
						
						var greatestChange = -999
						var greatestChangeIndex = -1
						#Look to see if we have something that matches the target mana cost
						for i in range(otherPlayer.lanes.size()):
							if otherPlayer.lanes[i].myCard == null:
								continue
								
							SetUpSimulation()
							
							var simHinder = simMe.Hinder(highestCard, simThem.lanes[i].myCard)
							if simHinder == false:
								continue
							
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							DestroySimulation()
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x - differenceVector.y
							
							if difference > greatestChange:
								greatestChange = difference
								greatestChangeIndex = i
								
						if greatestChangeIndex != -1:
							highestCard.inPlay = false
							playedSpell = player.Hinder(highestCard, otherPlayer.lanes[greatestChangeIndex].myCard)
						
						if playedSpell == true:
							lastActions.push_back(activeNode)
	
	var actionsThisTry = lastActions.size()
	
	#If we haven't been able to take any actions
	if actionsSinceLastTry == actionsThisTry:
		if stuck == false:
			stuck = true
			var lowestQScore = 999
			var lowestCard = null
			for card in player.hand:
				var node = cardNode.new()
				node.castingCardID = card.name
				var qScoreNode = brain.GetBestQScore(node)
				
				if qScoreNode.qWeight < lowestQScore:
					lowestQScore = qScoreNode.qWeight
					lowestCard = card
			
			player.Replace(lowestCard)
			
			return
		
		#That's the end of our turn
		
		#Once per turn, tweak this turn's q-scores
		for action in lastActions:
			print(str(action.ToString()))
			print("Assigning reward.")
			
			#Calculate the board state
			currentBoardState = CalculateBoardState(player, otherPlayer)
			var differenceVector = previousBoardState - currentBoardState
			var difference = differenceVector.x - differenceVector.y
			
			#Normalise the difference into a qWeight
			var normalisedDifference = tools.NormaliseOneToTen(difference)
			action.qWeight = normalisedDifference
			
			previousBoardState = currentBoardState
			
			#Perform an Epoch on the action
			brain.Epoch(action)
			print(str(action.ToString()))
		#Clear the action lists
		lastActions.clear()
		actionsToProcess.clear()
	
	#If we're stuck, end our turn
	if stuck == true:
		manager.EndTurn()
		actionTaken = true

func IsWithinOne(number, target):
	if number - 1.0 < target and number + 1.0 > target:
		return true
	
	return false

#A quick check to see how the board is looking
func CalculateBoardState(left, right):
	#Do our side first
	var ourSide = 0
	for lane in left.lanes:
		if lane.myCard != null:
			ourSide += CalculateMana(lane.myCard)
	
	#Then their side
	var theirSide = 0
	for lane in right.lanes:
		if lane.myCard != null:
			theirSide += CalculateMana(lane.myCard)
	
	return Vector2(ourSide, theirSide)

#Takes into account the cost and current HP of a card
func CalculateMana(card):
	var manaValue = 0
	manaValue += card.cost + card.currentHP
	for enhancement in card.enhancements:
		manaValue += enhancement.cost
	
	for hinderance in card.hinderances:
		manaValue -= hinderance.cost
	
	return manaValue

func CalculateManaDifference(then, now):
	var difference = Vector2((now.x - then.x), (now.y - then.y))
	return difference

func EndGame():
	set_process(false)
	brain.Serialise()
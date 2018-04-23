extends Node

const name = "FrankBrain"

var score
var brain

var player
var otherPlayer
var manager

var boardState = Vector2()
var lastBoardState = Vector2()

var lastActions = []

var actionsToProcess = []

var tools = load("res://Tools.gd").new()
var cardNode = load("res://q-learner/CardQLearnerNeuralNode.gd")

var trainingCards = []

var stuck = false
var actionTaken = false

const INFLUENCE = 0.5

var simMe
var simThem
var simulation

var turnTime = 0

var previousBoardState = Vector2()
var currentBoardState = Vector2()

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

func StartTurn():
	stuck = false
	actionTaken = false

func InitialTraining(deck):
	var nodes = []
	for card in deck:
		var node = brain.RandomUnassignedNode()
		node.castingCardID = card.name
		node.castingCardType = card.type
		node.targetMana = card.cost
		nodes.push_back(node)
	
	for node in nodes:
		brain.Epoch(node)

func ManufactureNode(card):
	var node = brain.RandomUnassignedNode()
	
	node.castingCardID = card.name
	node.castingCardType = card.type
	node.targetMana = card.cost
	
	brain.Epoch(node)

func SortHand(left, right):
	if left.activeNode.qWeight < right.activeNode.qWeight:
		return true
	
	return false

func _ready():
	Begin()

func Begin():
	brain = load("res://frank/Frank.gd").new(trainingCards.size() * 2)
	
	if brain.Deserialise() == false:
		InitialTraining(trainingCards)
	
	if self.get_tree() != null:
		manager = self.get_tree().get_root().get_node("Root/GameManager")
	
	set_process(true)

func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	if actionTaken == true:
		return
	
	turnTime += delta
	
	var actionsSinceLastTry = lastActions.size()
	
	#Find approximate Q-score for each card
	var highestQScore = -999
	var highestCard = null
	var activeNode = null
	
	var cardsInHand = []
	for card in player.hand:
		var node = cardNode.new()
		node.castingCardID = card.name
		var qScoreNode = brain.GetBestQScore(node)
		
		if qScoreNode == null:
			ManufactureNode(card)
			qScoreNode = brain.GetBestQScore(node)
		
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
							
							var predictedBoardState = CalculateBoardState(simMe, simThem)
							DestroySimulation()
							var currentBoardState = CalculateBoardState(player, otherPlayer)
							var differenceVector = predictedBoardState - currentBoardState
							var difference = differenceVector.x - differenceVector.y
							
							if difference > greatestChange:
								greatestChange = difference
								greatestChangeIndex = i
							
							highestCard.inPlay = false
							#playedCreature = player.Summon(highestCard, i)
					
					if greatestChangeIndex != -1:
						playedCreature = player.Summon(highestCard, greatestChangeIndex)
						
					if playedCreature == true:
						lastActions.push_back(activeNode)
					
					for i in range(player.lanes.size()):
						#If ours are empty, play the creature
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
							
							"""
							#If it's within one mana of the target value, let's use it
							if IsWithinOne(otherPlayer.lanes[i].myCard.cost, activeNode.targetMana):
								playedSpell = player.Hinder(highestCard, otherPlayer.lanes[i].myCard)
							#If it's not, adjust the mana towards the new value
							else:
								activeNode.AdjustMana(otherPlayer.lanes[i].myCard.cost, brain.learningRate, INFLUENCE)
								playedSpell = player.Hinder(highestCard, otherPlayer.lanes[i].myCard)
							"""
						if greatestChangeIndex != -1:
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
			
			currentBoardState = CalculateBoardState(player, otherPlayer)
			var differenceVector = previousBoardState - currentBoardState
			var difference = differenceVector.x - differenceVector.y
			var normalisedDifference = tools.NormaliseOneToTen(difference)
			action.qWeight = normalisedDifference
			
			previousBoardState = currentBoardState
			
			brain.Epoch(action)
			print(str(action.ToString()))
		#Clear the action list
		lastActions.clear()
		actionsToProcess.clear()
	
	if stuck == true:
		manager.EndTurn()
		actionTaken = true

func IsWithinOne(number, target):
	if number - 1.0 < target and number + 1.0 > target:
		return true
	
	return false

func CalculateBoardState(left, right):
	#Do our side first
	var ourSide = 0
	for lane in left.lanes:
		if lane.myCard != null:
			ourSide += CalculateMana(lane.myCard)
	
	var theirSide = 0
	for lane in right.lanes:
		if lane.myCard != null:
			theirSide += CalculateMana(lane.myCard)
	
	return Vector2(ourSide, theirSide)

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
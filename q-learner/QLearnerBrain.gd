extends Node

const name = "QLearnerBrain"

var score
var brain

var player
var otherPlayer
var manager

var boardState = Vector2()
var lastBoardState = Vector2()

var lastActions = []
var nextCard = null

var actionsToProcess = []

var tools = load("res://Tools.gd").new()
var cardNode = load("res://q-learner/CardQLearnerNeuralNode.gd")

var trainingCards = []

var stuck = false
var attempts = 0
const MAX_ATTEMPTS = 50

var hasActed = false

var turnTime = 0

#FIX THIS
func InitialTraining(deck):
	for i in range(0, deck.size()):
		for j in range(0, deck.size()):
			var card = deck[i]
			var nextCard = deck[j]
			
			var rewardNode = brain.GetRewardByIndex(i, j)
			rewardNode.SetParametersByCards(card, nextCard)
	
	for i in range(0, deck.size()):
		var card = deck[i]
		
		var rewardNode = brain.GetRewardByIndex(i, brain.width - 1)
		rewardNode.SetParametersByCard(card)

func SortHand(left, right):
	if left.node.qWeight < right.node.qWeight:
		return true
	
	return false

func _ready():
	Begin()

func Begin():
	var arraySize = trainingCards.size()
	brain = load("res://q-learner/CardQLearner.gd").new(arraySize)
	
	if brain.Deserialise() == false:
		InitialTraining(trainingCards)
	
	if self.get_tree() != null:
		manager = self.get_tree().get_root().get_node("Root/GameManager")
	
	set_process(true)

func StartTurn():
	hasActed = false
	attempts = 0
	stuck = false

func _process(delta):
	actionsToProcess.clear()
	if not manager.IsMyTurn(player):
		return
	
	if hasActed == true:
		return
	
	if attempts >= MAX_ATTEMPTS:
		print("STUCK, ENDING TURN")
		EndTurn()
		return
	
	turnTime += delta
	
	var actionsSinceLastTry = lastActions.size()
	
	#Find approximate Q-score for each card
	var highestQScore = -999
	var activeNode = null
	
	
	attempts = 0
	while attempts < MAX_ATTEMPTS:
		var nodesInHand = []
		if player.hand.size() == 1:
			var card = player.hand[0]
			var rewardNode = brain.GetRewardByNames(card.name, "None")
			nodesInHand.push_back(rewardNode)
		elif player.hand.size() >= 2:
			#For each card in the player's hand:
			#Get it and the next card's qWeight
			#Put that node into a list
			#Sort that list by qWeight
			#Attempt the actions one by one
			
			#FIX THIS
			if nextCard == null:
				print("BEGIN HAND")
				for i in range(0, player.hand.size()):
					var card = player.hand[i]
					print(card.ToString())
					var rewardNode = brain.GetRewardByNames(card.name, "None")
					nodesInHand.push_back(rewardNode)
					
					for j in range(0, player.hand.size()):
						if player.hand[i] == player.hand[j]:
							continue
						
						var card = player.hand[i]
						var next = player.hand[j]
						
						var rewardNode = brain.GetRewardByNames(card.name, next.name)
						nodesInHand.push_back(rewardNode)
				print("END HAND")
			else:
				if nextCard.cost > player.mana:
					nextCard = null
					print("INVALID SELECTION: TOO MUCH MANA, RESETTING")
					attempts += 1
					return
				
				var card = nextCard
				print("USING LAST CARD")
				print(card.ToString())
				var rewardNode = brain.GetRewardByNames(card.name, "None")
				nodesInHand.push_back(rewardNode)
					
				for j in range(0, player.hand.size()):
					var next = player.hand[j]
					
					var rewardNode = brain.GetRewardByNames(card.name, next.name)
					nodesInHand.push_back(rewardNode)
		else:
			print("NO CARDS IN HAND, ENDING TURN")
			EndTurn()
			return
		
		for i in range(0, nodesInHand.size()):
			var node = nodesInHand[i]
			if node == null:
				continue
			
			var action = {}
			action.node = node
			for card in player.hand:
				if card.cost > player.mana:
					continue
				
				if node.castingCardID == card.name:
					action.card = card
					action.tried = false
					break
			
			if action.has("card"):
				actionsToProcess.push_back(action)
				print(str("ADDING NODE: " + action.node.ToString()))
		
		actionsToProcess.sort_custom(self, "SortHand")
		
		if actionsToProcess.size() == 0:
			print("NOTHING TO PROCESS, ENDING TURN")
			EndTurn()
			return
		
			#pop the front of the queue
		var action = actionsToProcess[0]
		actionsToProcess.pop_front()
		var card = action.card
		var node = action.node
		var tried = action.tried
		
		print("ACTION SELECTED: " + node.ToString())
		
		if card != null:
			#Is it a creature?
			if card.type == card.CREATURE:
				var playedCreature = false
				
				#look at enemy lanes
				for i in range(otherPlayer.lanes.size()):
					#if theirs are full, and ours are empty, play the creature
					if otherPlayer.lanes[i].myCard != null and player.lanes[i].myCard == null:
						playedCreature = player.Summon(card, i)
						
					if playedCreature == true:
						lastActions.push_back(node)
						brain.AdjustQWeight(node.castingCardID, node.nextCardID, player.hand)
				
				for i in range(player.lanes.size()):
					#If ours are empty, play the creature
					if player.lanes[i].myCard == null:
						playedCreature = player.Summon(card, i)
						brain.AdjustQWeight(node.castingCardID, node.nextCardID, player.hand)
				
			#Or is it a spell/instant?
			if card.type == card.SPELL or card.type == card.INSTANT:
				#Is it an enhancement or a hinderance?
				if card.keywords.has("Enhancement"):
					var playedSpell = false
					
					#Look to see if we have something that matches the target mana cost
					for i in range(player.lanes.size()):
						if player.lanes[i].myCard == null:
							continue
						
						#If it's within one mana of the target value, let's use it
						if IsWithinOne(player.lanes[i].myCard.cost, node.targetMana):
							playedSpell = player.Enhance(card, player.lanes[i].myCard)
						#If it's not, adjust the mana towards the new value
						else:
							#FIX THIS
							#activeNode.AdjustMana(player.lanes[i].myCard.cost, brain.learningRate, INFLUENCE)
							brain.AdjustRelatedMana(card.name, player.lanes[i].myCard.cost)
							#playedSpell = player.Enhance(card, player.lanes[i].myCard)
							
						if playedSpell == false:
							#If the actions fails, push it back onto the stack to try again later in the turn
							var action = {}
							
							#If this action has been attempted before, remove it
							if tried == true:
								attempts += 1
							#Otherwise, push it to the back
							else:
								action.card = card
								action.node = node
								action.tried = true
								actionsToProcess.push_back(action)
								attempts += 1
						else:
							lastActions.push_back(node)
							brain.AdjustQWeight(node.castingCardID, node.nextCardID, player.hand)
							
					
				elif card.keywords.has("Hinderance"):
					var playedSpell = false
					
					#Look to see if we have something that matches the target mana cost
					for i in range(otherPlayer.lanes.size()):
						if otherPlayer.lanes[i].myCard == null:
							continue
							
						#If it's within one mana of the target value, let's use it
						if IsWithinOne(otherPlayer.lanes[i].myCard.cost, node.targetMana):
							playedSpell = player.Hinder(card, otherPlayer.lanes[i].myCard)
						#If it's not, adjust the mana towards the new value
						else:
							#FIX THIS
							#activeNode.AdjustMana(otherPlayer.lanes[i].myCard.cost, brain.learningRate, INFLUENCE)
							brain.AdjustRelatedMana(card.name, otherPlayer.lanes[i].myCard.cost)
							#playedSpell = player.Hinder(card, otherPlayer.lanes[i].myCard)
						
						if playedSpell == true:
							lastActions.push_back(node)
							brain.AdjustQWeight(node.castingCardID, node.nextCardID, player.hand)
		
		var isNextCard = false
		for card in player.hand:
			if card.name == node.nextCardID:
				nextCard = card
				isNextCard = true
				print("FOUND NEXT CARD")
		
		if isNextCard == false:
			nextCard = null
			print("NEXT CARD IS NULL")
			
		var actionsThisTry = lastActions.size()
		
		
		if stuck == true:
			print("STUCK, ENDING TURN")
			EndTurn()
			return
		
		#If we haven't been able to take any actions
		if actionsSinceLastTry == actionsThisTry:
			if stuck == false:
				stuck = true
				var lowestQScore = 999
				var lowestCard = null
				for card in player.hand:
					var qScoreNode = brain.GetRewardByNames(card.name, "None")
					
					if qScoreNode.qWeight < lowestQScore:
						lowestQScore = qScoreNode.qWeight
						lowestCard = card
				
				player.Replace(lowestCard)

func EndTurn():
		#Once per turn, tweak this turn's rewards
		for action in lastActions:
			print("Assigning reward.")
			boardState = CalculateBoardState()
			var difference = boardState.x - boardState.y
			
			brain.AdjustReward(action.castingCardID, action.nextCardID, difference)
			print(str(action.ToString()))
		#Clear the action list
		lastActions.clear()
		actionsToProcess.clear()
		manager.EndTurn()
		hasActed = true

func IsWithinOne(number, target):
	if number - 1.0 < target and number + 1.0 > target:
		return true
	
	return false

func CalculateBoardState():
	#Do our side first
	var ourSide = 0
	for lane in player.lanes:
		if lane.myCard != null:
			ourSide += CalculateMana(lane.myCard)
	
	var theirSide = 0
	for lane in otherPlayer.lanes:
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

func CalculateManaDifference(then, now):
	var difference = Vector2((now.x - then.x), (now.y - then.y))
	return difference

func EndGame():
	set_process(false)
	brain.Serialise()
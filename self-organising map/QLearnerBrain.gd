extends Node

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
var cardNode = load("res://self-organising map/CardNeuralNode.gd")

var trainingCards

var stuck = false

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
	brain = load("res://self-organising map/CardSelfOrganisingMap.gd").new(100, 100)
	
	if brain.Deserialise() == false:
		InitialTraining(trainingCards)
	
	manager = self.get_tree().get_root().get_node("Root/GameManager")
	set_process(true)

func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	if manager.phase == manager.DRAW_PHASE:
		player.Draw()
	
	var actionsSinceLastTry = lastActions.size()
	
	#Find approximate Q-score for each card
	var highestQScore = 0
	var highestCard = null
	var activeNode = null
	
	var cardsInHand = []
	for card in player.hand:
		var node = cardNode.new(Vector2(0 , 0))
		node.castingCardID = card.name
		var qScoreNode = brain.GetBestQScore(node)
		
		if qScoreNode == null:
			ManufactureNode(card)
			qScoreNode = brain.GetBestQScore(node)
		
		if qScoreNode.targetMana > player.mana:
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
	
		"""
		if qScoreNode.qWeight > highestQScore:
			print("Found qNode!")
			print(str(qScoreNode.ToString()))
			highestQScore = qScoreNode.qWeight
			highestCard = card
			activeNode = qScoreNode
		"""
		
	
	var attempts = 0
	if actionsToProcess.size() != 0:
		while actionsToProcess.size() > 0 && attempts < 10:
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
					
					#look at enemy lanes
					for i in range(otherPlayer.lanes.size()):
						#if theirs are full, and ours are empty, play the creature
						if otherPlayer.lanes[i].myCard != null and player.lanes[i].myCard == null:
							playedCreature = player.Summon(highestCard, i)
							
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
								activeNode.AdjustMana(player.lanes[i].myCard.cost, brain.learningRate, 1.0)
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
						
						#Look to see if we have something that matches the target mana cost
						for i in range(otherPlayer.lanes.size()):
							if otherPlayer.lanes[i].myCard == null:
								continue
								
							#If it's within one mana of the target value, let's use it
							if IsWithinOne(otherPlayer.lanes[i].myCard.cost, activeNode.targetMana):
								playedSpell = player.Hinder(highestCard, otherPlayer.lanes[i].myCard)
							#If it's not, adjust the mana towards the new value
							else:
								activeNode.AdjustMana(otherPlayer.lanes[i].myCard.cost, brain.learningRate, 1.0)
								playedSpell = player.Hinder(highestCard, otherPlayer.lanes[i].myCard)
							
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
				var node = cardNode.new(Vector2(0 , 0))
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
			print("Assigning reward.")
			brain.Epoch(action)
			print(str(action.ToString()))
		#Clear the action list
		lastActions.clear()
		actionsToProcess.clear()
		
		#Reduce clusterMod by 5%
		brain.clusterMod *= 0.95
		
		manager.EndTurn()

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
	brain.Serialise()
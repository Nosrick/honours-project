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
	
	for card in player.hand:
		var node = cardNode.new(Vector2(0 , 0))
		node.castingCardID = card.name
		var qScoreNode = brain.GetBestQScore(node)
		
		if qScoreNode == null:
			continue
		
		if qScoreNode.targetMana > player.mana:
			continue
		
		if qScoreNode.qWeight > highestQScore:
			print("Found qNode!")
			print(str(qScoreNode.ToString()))
			highestQScore = qScoreNode.qWeight
			highestCard = card
			var pair = {}
			pair.highestCard = card
			pair.activeNode = qScoreNode
			pair.tried = false
			actionsToProcess.push_back(pair)
	
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
						elif player.lanes[i].myCard == null:
							playedCreature = player.Summon(highestCard, i)
							
						if playedCreature == true:
							lastActions.push_back(activeNode)
					
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
							
							if playedSpell == true:
								#If it's an instant, give instant reward
								if highestCard.type == highestCard.INSTANT:
									#Get current board state
									var rightNow = CalculateBoardState()
									
									#Calculate difference between before this play and now
									var difference = CalculateManaDifference(boardState, rightNow)
									
									#Activate rewards
									#activeNode.qWeight += difference.x - difference.y
									
								lastActions.push_back(activeNode)
							else:
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
						
					elif highestCard.keywords.has("Hinderance"):
						var playedSpell = false
						
						#Look to see if we have something that matches the target mana cost
						for i in range(otherPlayer.lanes.size()):
							if otherPlayer.lanes[i].myCard == null:
								continue
								
							#If it's within one mana of the target value, let's use it
							if IsWithinOne(otherPlayer.lanes[i].myCard.cost, activeNode.targetMana):
								playedSpell = player.Hinder(highestCard, otherPlayer.lanes[i].myCard)
							
							if playedSpell == true:
								#If it's an instant, give instant reward
								if highestCard.type == highestCard.INSTANT:
									#Get current board state
									var rightNow = CalculateBoardState()
									
									#Calculate difference between before this play and now
									var difference = CalculateManaDifference(boardState, rightNow)
									
									#Activate rewards
									#activeNode.qWeight += difference.x - difference.y
									
								lastActions.push_back(activeNode)
	
	var actionsThisTry = lastActions.size()
	"""
	#If our search found nothing or we couldn't play a card, fall back on some basic rules
	if actionsToProcess.size() == 0 or lastActions.size() == 0:
		print("Resorting to Rules-Based.")
		var lanesEmpty = []
		for i in range(player.lanes.size()):
			if player.lanes[i].myCard == null:
				lanesEmpty.push_back(i)
				break
		
		#Try to fill the lanes
		if not lanesEmpty.empty():
			for lane in lanesEmpty:
				for card in player.hand:
					if card.type == card.CREATURE:
						if player.Summon(card, lane):
							var node = brain.RandomUnassignedNode()
							node.castingCardID = card.name
							node.castingCardType = card.type
							node.targetMana = card.cost
							lastActions.push_back(node)
		
		#Lanes are full, or no actions possible, so do some other actions
		for card in player.hand:
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
						if player.Enhance(card, lowestLane.myCard):
							#Create a semi-complete node for the best match algorithm
							var targetMana = lowestLane.myCard.cost
							var castingCardID = card.name
							var castingCardType = card.type
							
							#There is no closest match, so get a random unassigned node
							var node = brain.RandomUnassignedNode()
							node.targetMana = targetMana
							node.castingCardID = castingCardID
							node.castingCardType = castingCardType
							
							#Calculate board state
							var rightNow = CalculateBoardState()
							
							#Get the difference
							var difference = CalculateManaDifference(boardState, rightNow)
							
							#if card.type == card.INSTANT:
								#Assign reward
								#node.qWeight += difference.x - difference.y
							lastActions.push_back(node)
						
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
						if player.Hinder(card, highestLane.myCard):
							#Create a semi-complete node for the best match algorithm
							var targetMana = highestLane.myCard.cost
							var castingCardID = card.name
							var castingCardType = card.type
							
							#There is no closest match, so get a random unassigned node
							var node = brain.RandomUnassignedNode()
							node.targetMana = targetMana
							node.castingCardID = castingCardID
							node.castingCardType = castingCardType
							
							#Calculate board state
							var rightNow = CalculateBoardState()
							
							#Get the difference
							var difference = CalculateManaDifference(boardState, rightNow)
							
							#Assign reward
							#if card.type == card.INSTANT:
							#	node.qWeight += difference.x - difference.y
							lastActions.push_back(node)
	"""
	#If we haven't been able to take any actions
	if actionsSinceLastTry == actionsThisTry:
		#That's the end of our turn
		lastBoardState = boardState
		
		#Once per turn, tweak this turn's q-scores
		boardState = CalculateBoardState()
		#Calculate difference between last turn's board state and now
		var difference = CalculateManaDifference(lastBoardState, boardState)
		for action in lastActions:
			print("Assigning reward.")
			#action.qWeight += difference.x - difference.y
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
extends Node

var score
var brain

var player
var otherPlayer
var manager

var boardState = Vector2()
var lastBoardState = Vector2()

var lastActions = []

var tools = load("res://Tools.gd").new()
var cardNode = load("CardNeuralNode.gd")

func _ready():
	brain = load("CardSelfOrganisingMap.gd").new(widthRef, heightRef)
	brain.Deserialise()
	
	manager = self.get_tree().get_root().get_node("/Root/GameManager")
	set_process(true)

func _process(delta):
	if not manager.IsMyTurn(player):
		return
	
	if manager.phase == manager.DRAW_PHASE:
		player.Draw()
		
		#Once per turn, tweak last turn's q-scores
		CalculateBoardState()
		
		#Calculate difference between last turn's board state and now
		var difference = CalculateManaDifference(lastBoardState, boardState)
		for action in lastActions:
			action.qScore += difference.x - difference.y
	
	#Find approximate Q-score for each card
	var highestQScore = 0
	var highestCard = null
	var activeNode = null
	
	for card in player.hand:
		var node = cardNode.new(Vector2(0 , 0))
		node.castingCardID = card.name
		var qScoreNode = brain.GetHighestQScore(node)
		if qScoreNode.qScore > highestQScore:
			highestQScore = qScore
			highestCard = card
			activeNode = qScoreNode
	
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
					playerCreature = player.Summon(highestCard, i)
					
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
							activeNode.qScore += difference.x - difference.y
							
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
					
					if playedSpell == true:
						#If it's an instant, give instant reward
						if highestCard.type == highestCard.INSTANT:
							#Get current board state
							var rightNow = CalculateBoardState()
							
							#Calculate difference between before this play and now
							var difference = CalculateManaDifference(boardState, rightNow)
							
							#Activate rewards
							activeNode.qScore += difference.x - difference.y
							
						lastActions.push_back(activeNode)
	
	lastBoardState = boardState

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
	
	boardState = Vector2(ourSide, theirSide)

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
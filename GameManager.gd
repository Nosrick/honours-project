extends Node

var cards = []
var CardNode = load("res://scenes/Card.tscn")

var battleMarkers = []

var player1
var player2

var AIBrain

var turnPlayer
var haveDrawn
var haveAttacked

const DRAW_PHASE = 0
const PLAY_PHASE = 1
const ATTACK_PHASE = 2

var phase

const MAX_MANA = 6
var turn = 1

var gameState = STATE_SETUP

const STATE_SETUP = "SETUP"
const STATE_PLAY = "PLAY"
const STATE_ATTACK = "ATTACK"
const STATE_END = "END"
var attackLane = 0

var gameOver = false

var timer = 0
const TIME_BETWEEN_ACTIONS = 0.15

const fileName = "res://PlayStats.json"
var brainType = -1
var matchID = -1

func _ready():
	randomize()
	
	matchID = GetMatchID()
	
	set_process(true)
	for i in range(4):
		battleMarkers.push_back(get_tree().get_root().get_node("Root/BattleMarker" + str(i + 1) + "/BattleSprite"))
	
	var cardLoader = load("CardLoader.gd").new()
	cards = cardLoader.LoadCards()
	
	var deckCards1 = []
	for i in range(4):
		for card in cards:
			deckCards1.append(card)
	
	var deckCards2 = []
	for i in range(4):
		for card in cards:
			deckCards2.append(card)
	
	player1 = get_tree().get_root().get_node("Root/Player1")
	player2 = get_tree().get_root().get_node("Root/Player2")
	
	var deck1 = load("Deck.gd").new(deckCards1)
	for i in range(0, 10):
		deck1.Shuffle()
	player1.set_script(load("Player.gd"))
	#Deck, life, mana
	player1.Begin(deck1, 20, 1, player2)
	
	player2.set_script(load("AIPlayer.gd"))
	var deck2 = load("Deck.gd").new(deckCards2)
	for i in range(0, 10):
		deck2.Shuffle()
	player2.Begin(deck2, 20, 1, player1)
	
	AIBrain = get_tree().get_root().get_node("Root/AIBrain")
	
	brainType = GlobalVariables.brainOrder[0]
	GlobalVariables.brainOrder.pop_front()
	if brainType == 0:
		AIBrain.set_script(load("res://random/RandomBrain.gd"))
	elif brainType == 1:
		AIBrain.set_script(load("res://rules/RulesBrain.gd"))
	elif brainType == 2:
		AIBrain.set_script(load("res://q-learner/QLearnerBrain.gd"))
		AIBrain.trainingCards = cards
	elif brainType == 3:
		AIBrain.set_script(load("res://multi-layer perceptron/TDLBrain.gd"))
		AIBrain.trainingCards = cards
	elif brainType == 4:
		AIBrain.set_script(load("res://frank/FrankBrain.gd"))
		AIBrain.trainingCards = cards
	
	matchID = str(brainType) + str(matchID)
	get_tree().get_root().get_node("Root/MatchLabel").set_text(matchID)
	
	AIBrain.player = player2
	AIBrain.otherPlayer = player1
	
	turnPlayer = player1
	
	for i in range(4):
		player1.FreeDraw()
		player2.FreeDraw()
	
	StartTurn()

func IsMyTurn(player):
	return turnPlayer == player

func StartTurn():
	player1.SetDisplay()
	player2.SetDisplay()
	AIBrain.StartTurn()
	phase = DRAW_PHASE
	get_tree().get_root().get_node("Root/TurnLabel").set_text(turnPlayer.get_name() + "'s turn")
	turnPlayer.mana = min(MAX_MANA, turn)
	turnPlayer.replacementsDone = 0
	turnPlayer.Draw()
	
	for lane in turnPlayer.lanes:
		if lane.myCard != null:
			lane.myCard.exhausted = false

func EndTurn():
	gameState = STATE_ATTACK

func _process(delta):
	timer += delta
	if timer < TIME_BETWEEN_ACTIONS:
		return
	else:
		timer = 0
	
	if gameState == STATE_SETUP:
		gameState = STATE_PLAY
	elif gameState == STATE_PLAY:
		if gameOver == true:
			if player1.currentHP <= 0 and player2.currentHP <= 0:
				GlobalVariables.message = "YOU DREW!"
			elif player1.currentHP <= 0:
				GlobalVariables.message = "YOU LOSE!"
			elif player2.currentHP <= 0:
				GlobalVariables.message = "YOU WIN!"
			
			get_tree().change_scene("res://scenes/EndGame.tscn")
		
		var phaseString = ""
		
		if phase == DRAW_PHASE:
			phaseString = "DRAW"
		elif phase == PLAY_PHASE:
			phaseString = "PLAY"
		elif phase == ATTACK_PHASE:
			phaseString = "ATTACK"
		
		get_tree().get_root().get_node("Root/TurnLabel").set_text(turnPlayer.get_name() + "'s turn: " + phaseString)
		get_tree().get_root().get_node("Root/ManaLabel").set_text(str(turnPlayer.mana) + " Mana")
		
		#End game state
		if player1.currentHP <= 0 and gameOver == false:
			AIBrain.EndGame()
			gameOver = true
			player1.End()
			player2.End()
			Serialise(2, float(AIBrain.turnTime / turn))
			return
		elif player2.currentHP <= 0 and gameOver == false:
			AIBrain.EndGame()
			gameOver = true
			player1.End()
			player2.End()
			Serialise(1, float(AIBrain.turnTime / turn))
			return
		elif player1.currentHP <= 0 and player2.currentHP <= 0 and gameOver == false:
			AIBrain.EndGame()
			gameOver = true
			player1.End()
			player2.End()
			return
	elif gameState == STATE_ATTACK:
		RunAttacks(attackLane)
		attackLane += 1
		
		if attackLane == 4:
			gameState = STATE_END
			attackLane = 0
	elif gameState == STATE_END:
		if turnPlayer == player1:
			turnPlayer = player2
		else:
			turnPlayer = player1
			turn += 1
		
		gameState = STATE_PLAY
		StartTurn()

func RunAttacks(index):
	var player1Card = player1.lanes[index].myCard
	var player2Card = player2.lanes[index].myCard
	
	if player1Card != null and player2Card != null:
		if turnPlayer == player1 and player1Card.exhausted == false:
			battleMarkers[index].Begin()
			player1Card.DoCombat(player2Card)
			player1.ClearLanes()
			player2.ClearLanes()
		elif turnPlayer == player2 and player2Card.exhausted == false:
			battleMarkers[index].Begin()
			player2Card.DoCombat(player1Card)
			player1.ClearLanes()
			player2.ClearLanes()
	else:
		if turnPlayer == player1 and player1Card != null and player1Card.exhausted == false:
			battleMarkers[index].Begin()
			player1Card.DoCombat(player2)
		elif turnPlayer == player2 and player2Card != null and player2Card.exhausted == false:
			battleMarkers[index].Begin()
			player2Card.DoCombat(player1)

func GetCard(name):
	for card in cards:
		if card.name == name:
			var newCard = CardNode.instance()
			newCard.SetParametersFromCard(card)
			newCard.SetDisplay()
			return newCard
	
	return null

func Serialise(whichPlayerWon, averageTurnTime):
	var file = File.new()
	
	GlobalVariables.lastMatchID = matchID
	
	if file.file_exists(fileName):
		file.open(fileName, File.READ_WRITE)
		var string = file.get_as_text()
		var previousData = {}
		previousData.parse_json(string)
		var data = {}
		data[matchID] = {}
		data[matchID]["brainType"] = brainType
		data[matchID]["whichPlayerWon"] = whichPlayerWon
		data[matchID]["averageTurnTime"] = averageTurnTime
		
		JoinDictionaries(data, previousData)
		string = data.to_json()
		
		file.store_line(string)
	else:
		file.open(fileName, File.WRITE)
		var data = {}
		data[matchID] = {}
		data[matchID]["brainType"] = brainType
		data[matchID]["whichPlayerWon"] = whichPlayerWon
		data[matchID]["averageTurnTime"] = averageTurnTime
		var string = data.to_json()
		file.store_line(string)
	
	file.close()

func GetMatchID():
	var file = File.new()
	
	if file.file_exists(fileName):
		file.open(fileName, File.READ)
	else:
		return 0
	
	var string = file.get_as_text()
	var data = {}
	data.parse_json(string)
	
	file.close()
	
	var highestID = 0
	for item in data.keys():
		var subStr = item.substr(1, item.length())
		var matchID = int(subStr)
		if matchID > highestID:
			highestID = matchID
	
	highestID += 1
	return highestID

func GetStats(brainType):
	var file = File.new()
	
	file.open(fileName, File.READ)
	
	var string = file.get_as_text()
	var data = {}
	data.parse_json(string)
	
	file.close()
	
	var stats = {}
	stats.random = {}
	stats.random.AIWins = 0
	stats.random.totalGames = 0
	
	stats.rulesBased = {}
	stats.rulesBased.AIWins = 0
	stats.rulesBased.totalGames = 0
	
	stats.qLearner = {}
	stats.qLearner.AIWins = 0
	stats.qLearner.totalGames = 0
	
	stats.TDL = {}
	stats.TDL.AIWins = 0
	stats.TDL.totalGames = 0
	
	stats.frank = {}
	stats.frank.AIWins = 0
	stats.frank.totalGames = 0
	
	for item in data:
		if item.brainType == 0:
			if item.whichPlayerWon == 2:
				stats.random.AIWins += 1
			stats.random.totalGames += 1
		
		elif item.brainType == 1:
			if item.whichPlayerWon == 2:
				stats.rulesBased.AIWins += 1
			stats.rulesBased.totalGames += 1
		
		elif item.brainType == 2:
			if item.whichPlayerWon == 2:
				stats.qLearner.AIWins += 1
			stats.qLearner.totalGames += 1
		
		elif item.brainType == 3:
			if item.whichPlayerWon == 2:
				stats.TDL.AIWins += 1
			stats.TDL.totalGames += 1
		
		elif item.brainType == 4:
			if item.whichPlayerWon == 2:
				stats.frank.AIWins += 1
			stats.frank.totalGames += 1
	
	return stats
	
func JoinDictionaries(left, right):
		for key in right:
			left[key] = right[key]
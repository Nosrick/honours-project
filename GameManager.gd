extends Node

#Cards used in the game, and the node template for instantiating new cards
var cards = []
var CardNode = load("res://scenes/Card.tscn")

#For accessing the fading battle markers
var battleMarkers = []
#Used for the battle markers
var attackLane = 0

#The players!
var player1
var player2

#The AI brain, used for the AI player
var AIBrain

#Whose turn it is
var turnPlayer

#Whether the current player has drawn or not
var haveDrawn

#Whether the current player has attacked or not
var haveAttacked

#Ints for the various phases of the game
const DRAW_PHASE = 0
const PLAY_PHASE = 1
const ATTACK_PHASE = 2

#The phase of the game
var phase

#The maximum mana a player can have
const MAX_MANA = 6

#The current turn number
var turn = 1

#The state of the game
var gameState = STATE_SETUP

#The game state strings, could have been integers
const STATE_SETUP = "SETUP"
const STATE_PLAY = "PLAY"
const STATE_ATTACK = "ATTACK"
const STATE_END = "END"

#If the game is over
var gameOver = false

#File name for the play statistics
const fileName = "res://PlayStats.json"

#Used for recording the brain type in the stats
var brainType = -1

#Match ID, used for recording purposes
var matchID = -1

func _ready():
	#Randomize the seed
	randomize()
	
	matchID = GetMatchID()
	
	set_process(true)
	#Get the battle markers
	for i in range(4):
		#By finding them in the scene graph
		battleMarkers.push_back(get_tree().get_root().get_node("Root/BattleMarker" + str(i + 1) + "/BattleSprite"))
	
	#Load in the cards
	var cardLoader = load("CardLoader.gd").new()
	cards = cardLoader.LoadCards()
	
	#Prepare the first player's deck of cards
	var deckCards1 = []
	for i in range(4):
		for card in cards:
			deckCards1.append(card)
	
	#Prepare the second player's deck of cards
	var deckCards2 = []
	for i in range(4):
		for card in cards:
			deckCards2.append(card)
	
	#Get the nodes for players one and two
	player1 = get_tree().get_root().get_node("Root/Player1")
	player2 = get_tree().get_root().get_node("Root/Player2")
	
	#This is the actual deck
	var deck1 = load("Deck.gd").new(deckCards1)
	for i in range(0, 10):
		deck1.Shuffle()
	
	#Player 1 setup
	player1.set_script(load("Player.gd"))
	#Deck, life, mana
	player1.Begin(deck1, 20, 1, player2)
	
	var deck2 = load("Deck.gd").new(deckCards2)
	for i in range(0, 10):
		deck2.Shuffle()
	
	player2.set_script(load("AIPlayer.gd"))
	player2.Begin(deck2, 20, 1, player1)
	
	AIBrain = get_tree().get_root().get_node("Root/AIBrain")
	
	#Get the first brain type from the brainOrder array, set up elsewhere
	brainType = GlobalVariables.brainOrder[0]
	
	#Remove the first brain type
	GlobalVariables.brainOrder.pop_front()
	
	#Load the relevant brain type
	if brainType == 0:
		AIBrain.set_script(load("res://random/RandomBrain.gd"))
	elif brainType == 1:
		AIBrain.set_script(load("res://rules/RulesBrain.gd"))
	elif brainType == 2:
		AIBrain.set_script(load("res://q-learner/QLearnerBrain.gd"))
		#Set up the training cards
		AIBrain.trainingCards = cards
	elif brainType == 3:
		AIBrain.set_script(load("res://multi-layer perceptron/TDLBrain.gd"))
		AIBrain.trainingCards = cards
	elif brainType == 4:
		AIBrain.set_script(load("res://frank/FrankBrain.gd"))
		AIBrain.trainingCards = cards
	
	#Set up the match ID
	matchID = str(brainType) + str(matchID)
	get_tree().get_root().get_node("Root/MatchLabel").set_text(matchID)
	
	#Setting up the AI brain
	AIBrain.player = player2
	AIBrain.otherPlayer = player1
	
	#Set up the turn player
	turnPlayer = player1
	
	#Draw the first four cards of the opening hand
	for i in range(4):
		player1.FreeDraw()
		player2.FreeDraw()
	
	#Start the turn!
	StartTurn()

func IsMyTurn(player):
	return turnPlayer == player

#Start the new turn
func StartTurn():
	#Set the players to display their cards correctly
	#Make sure their parameters are displaying correctly, basically
	player1.SetDisplay()
	player2.SetDisplay()
	
	#Run the start turn function of the AI brain
	AIBrain.StartTurn()
	phase = DRAW_PHASE
	
	#Set the turn label to the current player's name
	get_tree().get_root().get_node("Root/TurnLabel").set_text(turnPlayer.get_name() + "'s turn")
	
	#Set the player's mana
	turnPlayer.mana = min(MAX_MANA, turn)
	
	#Reset replacements
	turnPlayer.replacementsDone = 0
	
	#Have the current player draw a card
	turnPlayer.Draw()
	
	#Set all of the player's creatures to be ready for combat
	for lane in turnPlayer.lanes:
		if lane.myCard != null:
			lane.myCard.exhausted = false

func EndTurn():
	gameState = STATE_ATTACK

func _process(delta):
	if gameState == STATE_SETUP:
		gameState = STATE_PLAY
	#If we're in the play state
	elif gameState == STATE_PLAY:
		#and it's game over
		if gameOver == true:
			#and both players have been defeated
			if player1.currentHP <= 0 and player2.currentHP <= 0:
				#We drew!
				GlobalVariables.message = "YOU DREW!"
			#If player 1 is defeated
			elif player1.currentHP <= 0:
				#We lost!
				GlobalVariables.message = "YOU LOSE!"
			#If player 2 is defeated
			elif player2.currentHP <= 0:
				#We won!
				GlobalVariables.message = "YOU WIN!"
			
			#Change scene to the end game scene
			get_tree().change_scene("res://scenes/EndGame.tscn")
		
		var phaseString = ""
		
		if phase == DRAW_PHASE:
			phaseString = "DRAW"
		elif phase == PLAY_PHASE:
			phaseString = "PLAY"
		elif phase == ATTACK_PHASE:
			phaseString = "ATTACK"
		
		#Update the phase label and the mana counter label
		get_tree().get_root().get_node("Root/TurnLabel").set_text(turnPlayer.get_name() + "'s turn: " + phaseString)
		get_tree().get_root().get_node("Root/ManaLabel").set_text(str(turnPlayer.mana) + " Mana")
		
		#End game state
		if player1.currentHP <= 0 and gameOver == false:
			#Have the AI brain wrap up
			AIBrain.EndGame()
			gameOver = true
			#Have the players free up their resources
			player1.End()
			player2.End()
			#Serialise the results
			Serialise(2, float(AIBrain.turnTime / turn))
			return
		#Same process here
		elif player2.currentHP <= 0 and gameOver == false:
			AIBrain.EndGame()
			gameOver = true
			player1.End()
			player2.End()
			Serialise(1, float(AIBrain.turnTime / turn))
			return
		#And again
		elif player1.currentHP <= 0 and player2.currentHP <= 0 and gameOver == false:
			AIBrain.EndGame()
			gameOver = true
			player1.End()
			player2.End()
			return
	#If we're in the attack state
	elif gameState == STATE_ATTACK and gameOver == false:
		#Run the attacks for the current lane
		RunAttacks(attackLane)
		player1.ClearLanes()
		player2.ClearLanes()
		
		#Increment the lane
		attackLane += 1
		
		#If we're done, change state
		if attackLane == 4:
			gameState = STATE_END
			attackLane = 0
	#If we're in the end state
	elif gameState == STATE_END:
		#Change the current player
		if turnPlayer == player1:
			turnPlayer = player2
		else:
			turnPlayer = player1
			#Increment the turn
			turn += 1
		
		gameState = STATE_PLAY
		
		player1.ClearLanes(true)
		player2.ClearLanes(true)
		StartTurn()

#Time to run the attacks.
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
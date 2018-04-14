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

func _ready():
	randomize()
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
	
	if GlobalVariables.brainType == 0:
		AIBrain.set_script(load("res://random/RandomBrain.gd"))
	elif GlobalVariables.brainType == 1:
		AIBrain.set_script(load("res://rules/RulesBrain.gd"))
	elif GlobalVariables.brainType == 2:
		AIBrain.set_script(load("res://q-learner/QLearnerBrain.gd"))
		AIBrain.trainingCards = cards
	elif GlobalVariables.brainType == 3:
		AIBrain.set_script(load("res://multi-layer perceptron/TDLBrain.gd"))
		AIBrain.trainingCards = cards
	
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
		elif player2.currentHP <= 0 and gameOver == false:
			AIBrain.EndGame()
			gameOver = true
			player1.End()
			player2.End()
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
		elif turnPlayer == player2 and player2Card.exhausted == false:
			battleMarkers[index].Begin()
			player2Card.DoCombat(player1Card)
	
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
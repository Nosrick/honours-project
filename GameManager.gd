extends Node

var cards = []
var CardNode = load("res://scenes/Card.tscn")

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

func _ready():
	randomize()
	set_process(true)
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
	deck1.Shuffle()
	player1.set_script(load("Player.gd"))
	#Deck, life, mana
	player1.Begin(deck1, 20, 1, player2)
	
	player2.set_script(load("AIPlayer.gd"))
	var deck2 = load("Deck.gd").new(deckCards2)
	deck2.Shuffle()
	player2.Begin(deck2, 20, 1, player1)
	
	AIBrain = get_tree().get_root().get_node("Root/AIBrain")
	AIBrain.set_script(load("res://random/RandomBrain.gd"))
	AIBrain.player = player2
	
	turnPlayer = player1
	
	for i in range(4):
		player1.FreeDraw()
		player2.FreeDraw()
	
	StartTurn()

func IsMyTurn(player):
	return turnPlayer == player

func StartTurn():
	phase = DRAW_PHASE
	get_tree().get_root().get_node("Root/TurnLabel").set_text(turnPlayer.get_name() + "'s turn")
	turnPlayer.mana = min(MAX_MANA, turn)
	turnPlayer.replacementsDone = 0
	
	for lane in turnPlayer.lanes:
		if lane.myCard != null:
			lane.myCard.exhausted = false

func EndTurn():
	if turnPlayer == player1:
		turnPlayer = player2
	else:
		turnPlayer = player1
		turn += 1
	
	RunAttacks()
	
	StartTurn()

func _process(delta):
	var phaseString = ""
	
	if phase == DRAW_PHASE:
		phaseString = "DRAW"
	elif phase == PLAY_PHASE:
		phaseString = "PLAY"
	elif phase == ATTACK_PHASE:
		phaseString = "ATTACK"
	
	get_tree().get_root().get_node("Root/TurnLabel").set_text(turnPlayer.get_name() + "'s turn: " + phaseString)
	get_tree().get_root().get_node("Root/ManaLabel").set_text(str(turnPlayer.mana) + " Mana")

func RunAttacks():
	for i in range(player1.lanes.size()):
		var player1Card = player1.lanes[i].myCard
		var player2Card = player2.lanes[i].myCard
		
		if player1Card != null and player2Card != null:
			if turnPlayer == player1 and player1Card.exhausted == false:
				player1Card.DoCombat(player2Card)
			elif turnPlayer == player2 and player2Card.exhausted == false:
				player2Card.DoCombat(player1Card)
		
		else:
			if turnPlayer == player1 and player1Card != null:
				player2.life -= player1Card.power
			elif turnPlayer == player2 and player2Card != null:
				player1.life -= player2Card.power
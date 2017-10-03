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
	
	var deckCards = []
	for i in range(15):
		deckCards.append(cards[0])
		deckCards.append(cards[1])
	
	var deck = load("Deck.gd").new(deckCards)
	deck.Shuffle()
	
	player1 = get_tree().get_root().get_node("Root/Player1")
	player1.set_script(load("Player.gd"))
	#Deck, life, mana
	player1.Begin(deck, 20, 1)
	
	player2 = get_tree().get_root().get_node("Root/Player2")
	player2.set_script(load("AIPlayer.gd"))
	deck.Shuffle()
	player2.Begin(deck, 20, 1)
	
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

func EndTurn():
	if turnPlayer == player1:
		turnPlayer = player2
	else:
		turnPlayer = player1
		turn += 1
	
	StartTurn()

func _process(delta):
	get_tree().get_root().get_node("Root/ManaLabel").set_text(str(turnPlayer.mana) + " Mana")
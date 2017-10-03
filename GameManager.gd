extends Node

var cards = []
var CardNode = load("res://scenes/Card.tscn")

var player1
var player2

var turnPlayer
var haveDrawn
var haveAttacked

const DRAW_PHASE = 0
const PLAY_PHASE = 1
const ATTACK_PHASE = 2

var phase

func _ready():
	randomize()
	var cardLoader = load("CardLoader.gd").new()
	cards = cardLoader.LoadCards()
	
	var deckCards = []
	for i in range(15):
		deckCards.append(cards[0])
		deckCards.append(cards[1])
	
	set_process_input(true)
	
	player1 = get_tree().get_root().get_node("Root/Player1")
	player1.set_script(load("Player.gd"))
	var deck = load("Deck.gd").new(deckCards)
	deck.Shuffle()
	#Deck, life, mana
	player1.Begin(deck, 20, 1)
	
	player2 = get_tree().get_root().get_node("Root/Player2")
	player2.set_script(load("AIPlayer.gd"))
	deck.Shuffle()
	player2.Begin(deck, 20, 1)
	
	turnPlayer = player1
	
	for i in range(4):
		player1.FreeDraw()
		player2.FreeDraw()
	
	StartTurn()

func IsMyTurn(player):
	return turnPlayer == player

func StartTurn():
	phase = DRAW_PHASE

func EndTurn():
	if turnPlayer == player1:
		turnPlayer = player2
	else:
		turnPlayer = player1

func _input(event):
	pass
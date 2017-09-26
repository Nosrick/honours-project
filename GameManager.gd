extends Node

var cards = []
var CardNode = load("res://scenes/Card.tscn")

var player1

func _ready():
	var cardLoader = load("CardLoader.gd").new()
	cards = cardLoader.LoadCards()
	
	var deckCards = []
	for i in range(30):
		deckCards.append(cards[0])
	
	set_process_input(true)
	
	player1 = get_tree().get_root().get_node("Root/Player1")
	var deck = load("Deck.gd").new(deckCards)
	player1.Begin(deck, true)

func _input(event):
	if event.is_action_released("ui_accept"):
		player1.Draw()
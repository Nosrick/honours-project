extends Node

var cards = []
var CardNode = load("Card.tscn")

func _ready():
	var cardLoader = load("CardLoader.gd").new()
	cards = cardLoader.LoadCards()
	
	for i in range(cards.size()):
		var card = CardNode.instance()
		add_child(card)
		card.SetParameters(cards[i].name, cards[i].cost, cards[i].power, cards[i].toughness, cards[i].keywords, cards[i].image)
		card.SetDisplay()
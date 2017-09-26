extends Node

var deck
var playerControlled
var lanes = []
var cardNode = load("res://Card.tscn")

func _init(deckRef, playerControlledRef):
	deck = deckRef
	playerControlled = playerControlledRef

func Summon(cardRef, laneRef):
	if lanes[laneRef] != null:
		return false
	
	var card = cardNode.instance()
	card.SetParameters(cardRef.name, cardRef.cost, cardRef.power, cardRef.toughness, cardRef.keywords, cardRef.image)
	card.SetDisplay()
	card.set_position(Vector2(laneRef * 310), 400)
	self.add_child(card)
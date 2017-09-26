extends Node

var deck
var playerControlled
var hand = []
var lanes = []
var cardNode = load("res://scenes/Card.tscn")

func Begin(deckRef, playerControlledRef):
	deck = deckRef
	playerControlled = playerControlledRef

func Summon(cardRef, laneRef):
	if lanes[laneRef] != null:
		return false
	
	cardRef.set_position(Vector2(laneRef * 310), 500)
	return true
	#self.add_child(card)

func Draw():
	var card = deck.Draw()
	if card == null:
		return false
	
	var node = cardNode.instance()
	node.SetParameters(card)
	node.SetDisplay()
	hand.append(node)
	self.add_child(node)
	node.set_scale(Vector2(0.5, 0.5))
	node.set_pos(Vector2(hand.size() * node.WIDTH / 2, 800 - node.HEIGHT / 2))
	
	return true
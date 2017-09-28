extends Node

var deck
var playerControlled
var hand = []
var lanes = []
var cardNode = load("res://scenes/Card.tscn")

var draggingCard

func _ready():
	set_process_input(true)
	
func _input(event):
	if event.type != InputEvent.MOUSE_MOTION:
		return
	
	if draggingCard == null:
		return
	
	var position = draggingCard.get_global_pos()
	position += event.relative_pos
	draggingCard.set_global_pos(position)

func Begin(deckRef, playerControlledRef):
	deck = deckRef
	playerControlled = playerControlledRef
	for i in range(4):
		lanes.append(null)

func Summon(cardRef, laneRef):
	if lanes[laneRef] != null:
		return false
	
	lanes[laneRef] = cardRef
	hand.erase(cardRef)
	RedrawHand()
	return true
	#self.add_child(card)

func RedrawHand():
	for i in range(hand.size()):
		hand[i].set_pos(Vector2((i + 1) * hand[i].WIDTH / 2, 800 - hand[i].HEIGHT / 2))

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
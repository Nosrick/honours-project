extends Node

var life
var mana
var deck
var hand = []
var lanes = []
var cardNode = load("res://scenes/Card.tscn")

var manager

var draggingCard

func _ready():
	set_process_input(true)
	
func _input(event):
	if event.type == InputEvent.ACTION:
		if event.is_action_pressed("ui_accept") and manager.IsMyTurn(self):
			manager.EndTurn()
	
	if event.type != InputEvent.MOUSE_MOTION:
		return
	
	if draggingCard == null:
		return
	
	var position = draggingCard.get_global_pos()
	position += event.relative_pos
	draggingCard.set_global_pos(position)

func Begin(deckRef, lifeRef, manaRef):
	manager = self.get_tree().get_root().get_node("Root/GameManager")
	life = lifeRef
	mana = manaRef
	deck = deckRef
	for i in range(4):
		lanes.append(null)
	
	#Initialise the lanes to be player lanes
	for i in range(1, 5):
		var node = self.get_node("LaneContainer/Lane" + str(i))
		node.set_script(load("Lane.gd"))
		node.player = self

func Summon(cardRef, laneRef):
	if lanes[laneRef] != null:
		return false
	
	if mana < int(cardRef.cost):
		return false
	
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	lanes[laneRef] = cardRef
	hand.erase(cardRef)
	print(self.get_name() + " summoned " + cardRef.name + " to lane " + str((laneRef + 1)))
	mana -= int(cardRef.cost)
	RedrawHand()
	return true
	#self.add_child(card)

func RedrawHand():
	for i in range(hand.size()):
		hand[i].set_pos(Vector2((i + 1) * hand[i].WIDTH / 2 + ((i + 1) * 10), 800 - hand[i].HEIGHT / 2))

func Draw():
	if manager.phase != manager.DRAW_PHASE:
		return
	
	manager.phase = manager.PLAY_PHASE
	
	return FreeDraw()
	
func FreeDraw():
	var card = deck.Draw()
	if card == null:
		return false
	
	var node = cardNode.instance()
	node.SetParameters(card)
	node.SetDisplay()
	hand.append(node)
	self.add_child(node)
	node.set_scale(Vector2(0.5, 0.5))
	node.set_pos(Vector2(hand.size() * node.WIDTH / 2 + (10 * hand.size()), 800 - node.HEIGHT / 2))
	
	return true
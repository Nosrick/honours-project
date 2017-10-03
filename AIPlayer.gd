extends Node

var life
var mana
var deck
var hand = []
var lanes = []
var cardNode = load("res://scenes/Card.tscn")
var manager

func Begin(deckRef, lifeRef, manaRef):
	manager = get_tree().get_root().get_node("Root/GameManager")
	
	life = lifeRef
	mana = manaRef
	deck = deckRef
	for i in range(4):
		lanes.append(null)
	
	#Initialise the lanes to AILanes
	for i in range(1, 5):
		var node = self.get_node("LaneContainer/Lane" + str(i))
		node.set_script(load("AILane.gd"))
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
	
	var lane = self.get_node("LaneContainer/Lane" + str(laneRef + 1))
	lane.myCard = cardRef
	
	return true

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
	
	return true

func _ready():
	pass

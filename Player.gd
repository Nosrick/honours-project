extends Node

var life
var mana
var deck
var hand = []
var lanes = []
var cardNode = load("res://scenes/Card.tscn")

var manager

var draggingCard

var otherPlayer

func _ready():
	set_process_input(true)
	
func _input(event):
	if event.is_action_released("ui_accept") and manager.IsMyTurn(self):
		manager.EndTurn()
	
	if event.type != InputEvent.MOUSE_MOTION:
		return
	
	if draggingCard == null:
		return
	
	var position = draggingCard.get_global_pos()
	position += event.relative_pos
	draggingCard.set_global_pos(position)

func Begin(deckRef, lifeRef, manaRef, otherPlayerRef):
	manager = self.get_tree().get_root().get_node("Root/GameManager")
	otherPlayer = otherPlayerRef
	life = lifeRef
	mana = manaRef
	deck = deckRef
	
	#Initialise the lanes to be player lanes
	for i in range(1, 5):
		var node = self.get_node("LaneContainer/Lane" + str(i))
		node.set_script(load("Lane.gd"))
		node.player = self
		lanes.append(node)

func Summon(cardRef, laneRef):
	if cardRef.type != cardRef.CREATURE:
		return false
	
	if lanes[laneRef].myCard != null:
		return false
	
	if mana < cardRef.cost:
		return false
	
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	lanes[laneRef].myCard = cardRef
	hand.erase(cardRef)
	print(self.get_name() + " summoned " + cardRef.name + " to lane " + str((laneRef + 1)))
	mana -= cardRef.cost
	cardRef.inPlay = true
	RedrawHand()
	return true

func Enhance(spellRef, receiver):
	if spellRef.type != spellRef.SPELL:
		return false
	
	if receiver.type != receiver.CREATURE:
		return false
	
	var onField = false
	
	for lane in lanes:
		if lane.myCard == receiver:
			onField = true
	
	if not onField:
		return false
	
	if mana < spellRef.cost:
		return false
	
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	receiver.enhancements.push_back(spellRef)
	hand.erase(spellRef)
	spellRef.inPlay = true
	print(self.get_name() + " enhanced " + receiver.name + " with " + spellRef.name)
	mana -= spellRef.cost
	RedrawHand()
	return true

func Hinder(spellRef, receiver):
	if spellRef.type != spellRef.SPELL:
		return false
	
	if receiver.type != receiver.CREATURE:
		return false
	
	var onField = false
	
	for lane in otherPlayer.lanes:
		if lane.myCard == receiver:
			onField = true
	
	if not onField:
		return false
	
	if mana < spellRef.cost:
		return false
	
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	receiver.hinderances.push_back(spellRef)
	hand.erase(spellRef)
	spellRef.inPlay = true
	print(self.get_name() + " hindered " + receiver.name + " with " + spellRef.name)
	mana -= spellRef.cost
	RedrawHand()
	return true

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
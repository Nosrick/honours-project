extends Node

var currentHP
var mana
var deck
var discardPile = []
var hand = []
var lanes = []
var cardNode = load("res://scenes/Card.tscn")

var manager

var draggingCard

var otherPlayer

var replacementsThisTurn
var replacementsDone

#Used for combat calculations
var power = 0

func SetDisplay():
	self.get_node("LifeLabel").set_text(get_name() + "'s life: " + str(currentHP))

func _ready():
	set_process_input(true)
	set_process(true)

func _process(delta):
	pass

func _input(event):
	if event.is_action_released("ui_cancel"):
		draggingCard = null
	
	if event.is_action_released("ui_accept") and manager.IsMyTurn(self) and manager.phase == manager.PLAY_PHASE:
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
	currentHP = lifeRef
	mana = manaRef
	deck = deckRef
	
	replacementsDone = 0
	replacementsThisTurn = 1
	
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
	
	if cardRef.keywords.has("Haste"):
		cardRef.exhausted = false
	
	lanes[laneRef].myCard = cardRef
	cardRef.player = self
	hand.erase(cardRef)
	print(self.get_name() + " summoned " + cardRef.name + " to lane " + str((laneRef + 1)))
	mana -= cardRef.cost
	cardRef.inPlay = true
	
	if cardRef.associatedScript != null:
		cardRef.associatedScript.Do(cardRef)
	
	RedrawHand()
	return true

func Enhance(spellRef, receiver):
	if spellRef.type != spellRef.SPELL and spellRef.type != spellRef.INSTANT:
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
	
	self.remove_child(spellRef)
	if spellRef.type == spellRef.SPELL:
		receiver.add_child(spellRef)
		spellRef.ScaleUp()
		receiver.AddEnhancement(spellRef)
	
	hand.erase(spellRef)
	spellRef.inPlay = true
	print(self.get_name() + " enhanced " + receiver.name + " with " + spellRef.name)
	mana -= spellRef.cost
	if spellRef.associatedScript != null:
		spellRef.associatedScript.Do(receiver)
	RedrawHand()
	return true

func Hinder(spellRef, receiver):
	if spellRef.type != spellRef.SPELL and spellRef.type != spellRef.INSTANT:
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
	
	self.remove_child(spellRef)
	if spellRef.type == spellRef.SPELL:
		receiver.add_child(spellRef)
		spellRef.ScaleUp()
		receiver.AddHinderance(spellRef)
	
	hand.erase(spellRef)
	spellRef.inPlay = true
	print(self.get_name() + " hindered " + receiver.name + " with " + spellRef.name)
	mana -= spellRef.cost
	if spellRef.associatedScript != null:
		spellRef.associatedScript.Do(receiver)
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
		for discard in discardPile:
			deck.Return(discard)
		deck.Shuffle()
	
	var node = cardNode.instance()
	node.SetParameters(card)
	node.SetDisplay()
	node.player = self
	hand.append(node)
	self.add_child(node)
	node.set_scale(Vector2(0.5, 0.5))
	node.set_pos(Vector2(hand.size() * node.WIDTH / 2 + (10 * hand.size()), 800 - node.HEIGHT / 2))
	
	return true

func ReplaceDraw(cardToReplace):
	var card = deck.Draw()
	deck.Return(cardToReplace.get_script())
	var attempts = 0
	var MAX_ATTEMPTS = 4
	while card.name == cardToReplace.name and attempts < MAX_ATTEMPTS:
		deck.Return(card)
		deck.Shuffle()
		card = deck.Draw()
		attempts += 1
	
	var node = cardNode.instance()
	node.SetParameters(card)
	node.SetDisplay()
	node.player = self
	hand.append(node)
	self.add_child(node)
	node.set_scale(Vector2(0.5, 0.5))
	node.set_pos(Vector2(hand.size() * node.WIDTH / 2 + (10 * hand.size()), 800 - node.HEIGHT / 2))
	
	return true

func Replace(card):
	if replacementsDone == replacementsThisTurn:
		return false
	
	replacementsDone += 1
	
	deck.Return(card)
	hand.erase(card)
	self.remove_child(card)
	return ReplaceDraw(card)
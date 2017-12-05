extends Node

var currentHP
var mana
var deck
var hand = []
var lanes = []
var cardNode = load("res://scenes/Card.tscn")
var manager

var otherPlayer

var replacementsThisTurn
var replacementsDone

#Used for combat calculations
var power = 0

func SetDisplay():
	self.get_node("LifeLabel").set_text(get_name() + "'s life: " + str(currentHP))

func Begin(deckRef, lifeRef, manaRef, otherPlayerRef):
	manager = get_tree().get_root().get_node("Root/GameManager")
	otherPlayer = otherPlayerRef
	
	currentHP = lifeRef
	mana = manaRef
	deck = deckRef
	
	#Initialise the lanes to AILanes
	for i in range(1, 5):
		var node = self.get_node("LaneContainer/Lane" + str(i))
		node.set_script(load("AILane.gd"))
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
	mana -= int(cardRef.cost)
	
	var lane = self.get_node("LaneContainer/Lane" + str(laneRef + 1))
	lane.myCard = cardRef
	cardRef.ScaleDown()
	self.add_child(cardRef)
	
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
	
	receiver.AddEnhancement(spellRef)
	hand.erase(spellRef)
	receiver.add_child(spellRef)
	print(self.get_name() + " enhanced " + receiver.name + " with " + spellRef.name)
	mana -= spellRef.cost
	#spellRef.ScaleDown()
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
	
	receiver.AddHinderance(spellRef)
	hand.erase(spellRef)
	receiver.add_child(spellRef)
	print(self.get_name() + " hindered " + receiver.name + " with " + spellRef.name)
	mana -= spellRef.cost
	#spellRef.ScaleDown()
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

func Replace(card):
	if replacementsDone == replacementsThisTurn:
		return false
	
	replacementsDone += 1
	
	deck.Return(card)
	hand.erase(card)
	return FreeDraw()

func _ready():
	set_process(true)

func _process(delta):
	pass
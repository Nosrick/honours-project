extends Node

var currentHP
var mana
var deck
var discardPile = []
var hand = []
var lanes = []
var cardNode = load("res://scenes/Card.tscn")
var manager

var otherPlayer

var replacementsThisTurn
var replacementsDone

#Used for combat calculations
var power = 0

func CloneCard(cardRef):
	var newCard = cardNode.instance()
	newCard.SetParametersFromCard(cardRef)
	newCard.SetDisplay()
	newCard.hinderances = []
	for hinderance in cardRef.hinderances:
		newCard.hinderances.push_back(CloneCard(hinderance))
	
	newCard.enhancements = []
	for enhancement in cardRef.enhancements:
		newCard.enhancements.push_back(CloneCard(enhancement))
	
	return newCard

func _init(handRef, deckRef, manaRef, currentHPRef, discardRef):
	
	for card in handRef:
		hand.push_back(CloneCard(card))
	
	var cards = []
	deck = load("res://Deck.gd").new(cards)
	
	for i in range(0, deckRef.cards.size()):
		deck.Return(CloneCard(deckRef.cards[i]))
	
	for card in discardRef:
		discardPile.push_back(CloneCard(card))
	
	mana = manaRef
	currentHP = currentHPRef
	
	#Initialise the lanes to null
	for i in range(1, 5):
		var placeHolder = {}
		placeHolder.myCard = null
		lanes.append(placeHolder)

func FillLanes(lanesRef):
	for i in range(0, lanesRef.size()):
		if lanesRef[i].myCard != null:
			lanes[i].myCard = CloneCard(lanesRef[i].myCard)

func CleanUpLanes():
	for lane in lanes:
		if lane.myCard != null:
			if lane.myCard.currentHP <= 0:
				for enhancement in lane.myCard.enhancements:
					discardPile.push_back(enhancement)
				
				for hinderance in lane.myCard.hinderances:
					discardPile.push_back(hinderance)
				
				lane.myCard.inPlay = false
				discardPile.push_back(lane.myCard)
				lane.myCard = null

func Summon(cardRef, laneRef):
	if cardRef.type != cardRef.CREATURE:
		return false
	
	if lanes[laneRef].myCard != null:
		return false
	
	if mana < cardRef.cost:
		return false
	
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	if cardRef.inPlay == true:
		return false
	
	if cardRef.keywords.has("Haste"):
		cardRef.exhausted = false
	
	lanes[laneRef].myCard = cardRef
	cardRef.player = self
	cardRef.inPlay = true
	hand.erase(cardRef)
	print(self.get_name() + " summoned " + cardRef.name + " to lane " + str((laneRef + 1)))
	mana -= int(cardRef.cost)
	
	if cardRef.associatedScript != null:
		cardRef.associatedScript.Do(cardRef)
	
	return true

func Enhance(spellRef, receiver):
	if spellRef.type != spellRef.SPELL and spellRef.type != spellRef.INSTANT:
		return false
	
	if receiver.type != receiver.CREATURE:
		return false
	
	if spellRef.inPlay == true:
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
	
	hand.erase(spellRef)
	if spellRef.type == spellRef.SPELL:
		receiver.AddEnhancement(spellRef)
		spellRef.inPlay = true
	
	print(self.get_name() + " enhanced " + receiver.name + " with " + spellRef.name)
	mana -= spellRef.cost
	if spellRef.associatedScript != null:
		spellRef.associatedScript.Do(receiver)
	#spellRef.ScaleDown()
	return true

func Hinder(spellRef, receiver):
	if spellRef.type != spellRef.SPELL and spellRef.type != spellRef.INSTANT:
		return false
	
	if receiver.type != receiver.CREATURE:
		return false
	
	if spellRef.inPlay == true:
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
	
	if spellRef.type == spellRef.SPELL:
		receiver.AddHinderance(spellRef)
		#spellRef.inPlay = true
	
	hand.erase(spellRef)
	spellRef.inPlay = true
	print(self.get_name() + " hindered " + receiver.name + " with " + spellRef.name)
	mana -= spellRef.cost
	if spellRef.associatedScript != null:
		spellRef.associatedScript.Do(receiver)
	#spellRef.ScaleDown()
	
	otherPlayer.CleanUpLanes()
	CleanUpLanes()
	
	return true

func Draw():
	if manager.phase != manager.DRAW_PHASE:
		return
	
	manager.phase = manager.PLAY_PHASE
	
	return FreeDraw()

func FreeDraw():
	if hand.size() == 6:
		return false
	
	var card = deck.Draw()
	if card == null:
		for discard in discardPile:
			deck.Return(discard)
		deck.Shuffle()
		card = deck.Draw()
	
	var node = cardNode.instance()
	node.SetParametersFromCard(card)
	node.SetDisplay()
	node.player = self
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

func SetDisplay():
	pass
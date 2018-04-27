extends Node

#Current hit points
var currentHP

#Current mana
var mana

#Deck and discard pile
var deck
var discardPile = []

#Hand of cards
var hand = []

#Lanes on the board
var lanes = []

#Card node used for instantiating new cards
var cardNode = load("res://scenes/Card.tscn")

#The game manager
var manager

#Whether we're dragging a card or not
var draggingCard

#The other player in the game
var otherPlayer

#How many replacements we've done this round
var replacementsThisTurn
var replacementsDone

#Used for combat calculations
var power = 0

#Our name
var name

#The y-coord for our hand
const HAND_Y = 491

#Timer stuff
const MAX_TIMER = 0.15
var timer = 0
var useTimer = false

func SetTimer():
	timer = 0
	useTimer = true

func ResetTimer():
	timer = 0
	useTimer = false

func SetDisplay():
	self.get_node("LifeLabel").set_text(get_name() + "'s life: " + str(currentHP))

func ClearLanes(force = false):
	if timer >= MAX_TIMER or force == true:
		for lane in lanes:
			if lane.myCard != null and lane.myCard.currentHP <= 0:
				remove_child(lane.myCard)
				discardPile.push_back(lane.myCard)
				lane.myCard = null
		ResetTimer()

func _ready():
	set_process_input(true)
	set_process(true)
	name = self.get_name()

func _process(delta):
	if useTimer == true:
		timer += delta
	
	if useTimer == true and timer >= MAX_TIMER:
		ClearLanes()
		otherPlayer.ClearLanes()

func _input(event):
	#Clear the dragging card, just in case it gets stuck (Pushing Escape here)
	if event.is_action_released("ui_cancel"):
		draggingCard = null
	
	#Push Space to end the turn
	if event.is_action_released("ui_accept") and manager.IsMyTurn(self) and manager.phase == manager.PLAY_PHASE:
		manager.EndTurn()
	
	#No point in continuing if it isn't a mouse motion event
	if event.type != InputEvent.MOUSE_MOTION:
		return
	
	#Or if we don't have a card being dragged
	if draggingCard == null:
		return
	
	#If we do have a card being dragged, move its position
	var position = draggingCard.get_global_pos()
	position += event.relative_pos
	draggingCard.set_global_pos(position)

#Just a simple setup function
func Begin(deckRef, lifeRef, manaRef, otherPlayerRef):
	#Set up the manager
	manager = self.get_tree().get_root().get_node("Root/GameManager")
	
	#The other player
	otherPlayer = otherPlayerRef
	
	#And the HP, mana and deck
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

#Freeing up everything
func End():
	#deck.Destroy()
	deck.free()
	
	for card in hand:
		card.free()
	
	for card in discardPile:
		card.free()
	
	hand.clear()
	for lane in lanes:
		lane.free()

#Attempting to summon a creature to a lane
func Summon(cardRef, laneRef):
	#If it's not a creature, return false
	if cardRef.type != cardRef.CREATURE:
		return false
	
	#If there's already a card in the lane, return false
	if lanes[laneRef].myCard != null:
		return false
	
	#If it's more mana than we have, return false
	if mana < cardRef.cost:
		return false
	
	#If it isn't our turn, or isn't the play phase, return false
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	#If it has haste, it moves this round
	if cardRef.keywords.has("Haste"):
		cardRef.exhausted = false
	
	#Set the lane's card to the card being played
	lanes[laneRef].myCard = cardRef
	
	#Set the card's player to us
	cardRef.player = self
	
	#Remove the card from our hand
	hand.erase(cardRef)
	
	#Debug printing
	print(self.get_name() + " summoned " + cardRef.name + " to lane " + str((laneRef + 1)))
	
	#Decrement our mana
	mana -= cardRef.cost
	
	#Mark the card as in play
	cardRef.inPlay = true
	
	#Run any associated script
	if cardRef.associatedScript != null:
		cardRef.associatedScript.Do(cardRef)
	
	#Redraw our hand without that card in it
	RedrawHand()
	
	#Set our timer and clear our lanes
	SetTimer()
	ClearLanes()
	
	#Clear the other player's lanes
	otherPlayer.ClearLanes(true)
	
	#We made it! Return true.
	return true

#Enhance a creature
func Enhance(spellRef, receiver):
	#If it isn't a spell or an instant card, return false
	if spellRef.type != spellRef.SPELL and spellRef.type != spellRef.INSTANT:
		return false
	
	#If the receiver isn't a creature, return false
	if receiver.type != receiver.CREATURE:
		return false
	
	#Check if the receiver is actually on the field, for sanity's sake
	var onField = false
	for lane in lanes:
		if lane.myCard == receiver:
			onField = true
	
	#If it's not, return false
	if not onField:
		return false
	
	#If it's costing more mana to cast than we have, return false
	if mana < spellRef.cost:
		return false
	
	#If it's not the play phase, or not our turn, return false
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	self.remove_child(spellRef)
	#Add the enhancement to the receiver
	if spellRef.type == spellRef.SPELL:
		receiver.add_child(spellRef)
		spellRef.ScaleUp()
		receiver.AddEnhancement(spellRef)
	
	#Remove the card from our hand
	hand.erase(spellRef)
	
	#Mark the card as being in play
	spellRef.inPlay = true
	
	#Debug printing
	print(self.get_name() + " enhanced " + receiver.name + " with " + spellRef.name)
	
	#Decrement our mana
	mana -= spellRef.cost
	
	#Do the associated script
	if spellRef.associatedScript != null:
		spellRef.associatedScript.Do(receiver)
	
	#Redraw our hand without the card in it
	RedrawHand()
	SetTimer()
	
	#We made it! Return true.
	return true

#Attempt to hinder a creature.
func Hinder(spellRef, receiver):
	#If the card isn't a spell or instant, return false
	if spellRef.type != spellRef.SPELL and spellRef.type != spellRef.INSTANT:
		return false
	
	#If the receiver isn't a creature, return false
	if receiver.type != receiver.CREATURE:
		return false
	
	#Check that the creature is on the field, for sanity's sake
	var onField = false
	for lane in otherPlayer.lanes:
		if lane.myCard == receiver:
			onField = true
	
	#If it's not, return false
	if not onField:
		return false
	
	#If it's costing more mana to cast than we have, return false
	if mana < spellRef.cost:
		return false
	
	#If it's not the play phase, or not our turn, return false
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	#Add the hindrance to the receiver
	self.remove_child(spellRef)
	if spellRef.type == spellRef.SPELL:
		receiver.add_child(spellRef)
		spellRef.ScaleUp()
		receiver.AddHinderance(spellRef)
	
	#Remove the card from our hand
	hand.erase(spellRef)
	
	#Mark the card as being in play
	spellRef.inPlay = true
	
	#Set the card's player to us
	spellRef.player = self
	
	#Debug printing
	print(self.get_name() + " hindered " + receiver.name + " with " + spellRef.name)
	
	#Decrement our mana
	mana -= spellRef.cost
	
	#Do any associated scripts
	if spellRef.associatedScript != null:
		spellRef.associatedScript.Do(receiver)
	
	#Redraw our hand, minus the played card
	RedrawHand()
	
	#Clear the lanes, just in case
	SetTimer()
	ClearLanes()
	otherPlayer.ClearLanes(true)
	
	#We made it! Return true.
	return true

#Just reorganises the hand to be pretty at the bottom of the screen again.
func RedrawHand():
	for i in range(hand.size()):
		hand[i].set_pos(Vector2((i + 1) * hand[i].WIDTH / 2 + ((i + 1) * 10), HAND_Y))

#Draws a single card per turn.
func Draw():
	if manager.phase != manager.DRAW_PHASE:
		return
	
	manager.phase = manager.PLAY_PHASE
	
	return FreeDraw()

#Draws a card, up to the hand limit of 6.
func FreeDraw():
	if hand.size() == 6:
		return false
		
	var card = deck.Draw()
	
	#If the card comes back null, we've run out of cards
	if card == null:
		#So we return our discard pile to the deck
		for discard in discardPile:
			deck.Return(discard)
		#Shuffle the deck
		deck.Shuffle()
		
		#And draw a card
		card = deck.Draw()
	
	#Instantiate a new card
	var node = cardNode.instance()
	node.SetParametersFromCard(card)
	node.SetDisplay()
	node.player = self
	hand.append(node)
	self.add_child(node)
	node.set_scale(Vector2(0.5, 0.5))
	node.set_pos(Vector2(hand.size() * node.WIDTH / 2 + (10 * hand.size()), 800 - node.HEIGHT / 2))
	RedrawHand()
	return true

#Replace a card from the hand
func ReplaceDraw(cardToReplace):
	var card = deck.Draw()
	deck.Return(cardToReplace)
	var attempts = 0
	var MAX_ATTEMPTS = 4
	#If the card we've just drawn is the same as the card we're returning, draw another card
	while card.name == cardToReplace.name and attempts < MAX_ATTEMPTS:
		deck.Return(card)
		deck.Shuffle()
		card = deck.Draw()
		attempts += 1
	
	#If we run out of attempts, it's probably because we only have that card left in the deck.
	#So, instantiate a new card either way.
	var node = cardNode.instance()
	node.SetParametersFromCard(card)
	node.SetDisplay()
	node.player = self
	hand.append(node)
	self.add_child(node)
	node.set_scale(Vector2(0.5, 0.5))
	node.set_pos(Vector2(hand.size() * node.WIDTH / 2 + (10 * hand.size()), 800 - node.HEIGHT / 2))
	
	return true

#Wrapper function for the ReplaceDraw function
func Replace(card):
	if replacementsDone == replacementsThisTurn:
		return false
	
	replacementsDone += 1
	
	deck.Return(card)
	hand.erase(card)
	self.remove_child(card)
	return ReplaceDraw(card)
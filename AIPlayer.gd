extends Node

#Stat stuff
var currentHP
var mana

#Deck stuff
var deck
var discardPile = []
var hand = []

#Our lanes
var lanes = []

#For instantiating cards
var cardNode = load("res://scenes/Card.tscn")

#Link to the manager
var manager

#Link to the other player
var otherPlayer

#Replacement stuff
var replacementsThisTurn
var replacementsDone

#Used for combat calculations
var power = 0

#Our name
var name

#Not used
var draggingCard = null

#Used for slowing things down and making 'animations'
const MAX_TIMER = 0.8
var timer = 0
var useTimer = false

func SetTimer():
	useTimer = true
	timer = 0

func ResetTimer():
	useTimer = false
	timer = 0

#Clear dead creatures from the lanes
func ClearLanes():
	if timer >= MAX_TIMER:
		for lane in lanes:
			#If we have a card and it has 0 or less HP
			if lane.myCard != null and lane.myCard.currentHP <= 0:
				#Remove the card
				remove_child(lane.myCard)
				
				#Push it into the discard pile
				discardPile.push_back(lane.myCard)
				
				#Set the lane's card to null
				lane.myCard = null
			
			#Attempt to remove instant hindrances
			if lane.myCard != null:
				for hinderance in lane.myCard.hinderances:
					if hinderance.type == hinderance.INSTANT:
						hinderance.remove_and_skip()
		ResetTimer()

#Get the label and set its text to represent our life
func SetDisplay():
	self.get_node("LifeLabel").set_text(get_name() + "'s life: " + str(currentHP))

#Set up!
func Begin(deckRef, lifeRef, manaRef, otherPlayerRef):
	#Get the manager
	manager = get_tree().get_root().get_node("Root/GameManager")
	
	#Set up the other player
	otherPlayer = otherPlayerRef
	
	#Set HP, mana and deck
	currentHP = lifeRef
	mana = manaRef
	deck = deckRef
	
	name = self.get_name()
	
	#Initialise the lanes to AILanes
	for i in range(1, 5):
		var node = self.get_node("LaneContainer/Lane" + str(i))
		node.set_script(load("AILane.gd"))
		node.player = self
		lanes.append(node)

#Free up all the resources we're using
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

#Attempt to summon a card
#Takes a card, and a lane number
func Summon(cardRef, laneRef):
	#If we're trying to summon a non-creature, return false
	if cardRef.type != cardRef.CREATURE:
		return false
	
	#If there's already a creature in the lane, return false
	if lanes[laneRef].myCard != null:
		return false
	
	#If we don't have enough mana, return false
	if mana < cardRef.cost:
		return false
	
	#If it isn't the play phase, or isn't our turn, return false
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	#If the card is already in play, return false
	if cardRef.inPlay == true:
		return false
	
	#If the card has the keyword Haste, it is not exhausted!
	if cardRef.keywords.has("Haste"):
		cardRef.exhausted = false
	
	#Set the lane's card to the casting card
	lanes[laneRef].myCard = cardRef
	
	#The card's player is us
	cardRef.player = self
	
	#The card is now in play
	cardRef.inPlay = true
	
	#Remove the card from our hand
	hand.erase(cardRef)
	
	#Some debug info
	print(self.get_name() + " summoned " + cardRef.name + " to lane " + str((laneRef + 1)))
	
	#And decrement our mana
	mana -= int(cardRef.cost)
	
	#Make sure the card isn't super huge
	cardRef.ScaleDown()
	self.add_child(cardRef)
	
	#If the card has an associated script, run it
	if cardRef.associatedScript != null:
		cardRef.associatedScript.Do(cardRef)
	
	#Set the timer for the animation
	SetTimer()
	
	#We made it!
	return true

#Attempt to enhance one of our cards
#Takes a spell to play, and a receiver (a card)
func Enhance(spellRef, receiver):
	#If it's not a spell of an instant, return false
	if spellRef.type != spellRef.SPELL and spellRef.type != spellRef.INSTANT:
		return false
	
	#If the receiver isn't a creature, return false
	if receiver.type != receiver.CREATURE:
		return false
	
	#If the spell is already in play, return false
	if spellRef.inPlay == true:
		return false
	
	#Check to make sure our receiver is actually on our side of the field
	var onField = false
	for lane in lanes:
		if lane.myCard == receiver:
			onField = true
	
	#If it's not, return false
	if onField == false:
		return false
	
	#If the spell costs more mana than we have, return false
	if mana < spellRef.cost:
		return false
	
	#If it's not the play phase, or not our turn, return false
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	#Remove the card from our hand
	hand.erase(spellRef)
	
	#If it's not an instant...
	if spellRef.type == spellRef.SPELL:
		#...add the spell to our receiver
		receiver.add_child(spellRef)
		receiver.AddEnhancement(spellRef)
		spellRef.inPlay = true
	
	#Debug stuff
	print(self.get_name() + " enhanced " + receiver.name + " with " + spellRef.name)
	
	#Decrement our mana
	mana -= spellRef.cost
	
	#If the card has an associated script, run it
	if spellRef.associatedScript != null:
		spellRef.associatedScript.Do(receiver)
	
	#Animation timer
	SetTimer()
	
	#We made it!
	return true

#Attempt to hinder a creature, much like enhancing, but on an enemy creature
#Takes a hindrance and a receiving card
func Hinder(spellRef, receiver):
	#You know the drill by now
	if spellRef.type != spellRef.SPELL and spellRef.type != spellRef.INSTANT:
		return false
	
	if receiver.type != receiver.CREATURE:
		return false
	
	if spellRef.inPlay == true:
		return false
	
	#Check the other side of the field
	var onField = false
	for lane in otherPlayer.lanes:
		if lane.myCard == receiver:
			onField = true
	
	if onField == false:
		return false
	
	if mana < spellRef.cost:
		return false
	
	if manager.phase != manager.PLAY_PHASE or not manager.IsMyTurn(self):
		return false
	
	if spellRef.type == spellRef.SPELL:
		receiver.add_child(spellRef)
		receiver.AddHinderance(spellRef)
	#This time, if it's an instant, place it upon the creature
	elif spellRef.type == spellRef.INSTANT:
		receiver.add_child(spellRef)
		spellRef.ScaleDown()
		spellRef.set_global_pos(receiver.get_global_pos())
		spellRef.raise()
	
	hand.erase(spellRef)
	spellRef.inPlay = true
	print(self.get_name() + " hindered " + receiver.name + " with " + spellRef.name)
	mana -= spellRef.cost
	if spellRef.associatedScript != null:
		spellRef.associatedScript.Do(receiver)
	#spellRef.ScaleDown()
	SetTimer()
	return true

#Draw a card
func Draw():
	if manager.phase != manager.DRAW_PHASE:
		return false
	
	manager.phase = manager.PLAY_PHASE
	
	return FreeDraw()

#Freely draw a card
func FreeDraw():
	#If the hand size is at maximum, don't draw any more
	if hand.size() == 6:
		return false
	
	#Draw a card from the deck
	var card = deck.Draw()
	
	#If there are no cards left...
	if card == null:
		#...turn the discard pile into the new deck
		for discard in discardPile:
			deck.Return(discard)
		#and shuffle it
		deck.Shuffle()
		
		#Then draw a card
		card = deck.Draw()
	
	#Instantiate a card
	var node = cardNode.instance()
	
	#Set the parameters of the card (HP, power, toughness, etc)
	node.SetParametersFromCard(card)
	
	#Make sure the parameters are set to display properly
	node.SetDisplay()
	
	#Set the player to ourselves
	node.player = self
	
	#Add the card to our hand
	hand.append(node)
	
	#We made it to the end!
	return true

#Replace a card
func Replace(card):
	#If we've already tried to replace a card this turn, return false
	if replacementsDone == replacementsThisTurn:
		return false
	
	replacementsDone += 1
	
	#Return the card to the deck
	deck.Return(card)
	
	#And remove it from our hand
	hand.erase(card)
	
	#Return a new card
	return FreeDraw()

func _ready():
	set_process(true)

func _process(delta):
	if useTimer == true:
		timer += delta
	
	if useTimer == true and timer >= MAX_TIMER:
		ClearLanes()
		otherPlayer.ClearLanes()
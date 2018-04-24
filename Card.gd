extends Node

#Stats and stuff
var name = "UNINITIALISED"
var image
#Cost to play
var cost = 1
#Attack value
var power = 0
#Maximum hit points
var toughness = 1
#What key words are associated with this card
var keywords = []
#Creature, spell or instant?
var type
#Any script to be run, can be null
var associatedScript

#The card types
const CREATURE = 1
const SPELL = 2
const INSTANT = 3

#The sizes of the card on the screen
const WIDTH = 308
const HEIGHT = 408

#Is the card being dragged?
var dragging
#Is the card zoomed in at the moment?
var zoomed

#What player do we belong to?
var player

#Enhancements and hinderances(sp)
var enhancements = []
var hinderances = []

#Are we on the field?
var inPlay
#Our current hit points
var currentHP
#Have we acted this turn?
var exhausted

#Whether or not the card is ready to be removed
var safeForRemoval = false

#Copy the parameters of one card to another
#Note this is a shallow copy
#Godot does not support deep copies, unless under very specific circumstances
func SetParametersFromCard(cardRef):
	name = cardRef.name
	image = cardRef.image
	cost = cardRef.cost
	power = cardRef.power
	toughness = cardRef.toughness
	currentHP = toughness
	#Such as this; this is a deep copy
	keywords = [] + cardRef.keywords
	type = cardRef.type
	if cardRef.associatedScript != null:
		associatedScript = cardRef.associatedScript
	else:
		associatedScript = null
	
	inPlay = cardRef.inPlay
	zoomed = cardRef.zoomed
	exhausted = cardRef.exhausted
	player = cardRef.player

#The same as above, but uses a dictionary rather than a card
func SetParameters(cardRef):
	name = cardRef.name
	image = cardRef.image
	cost = int(cardRef.cost)
	power = int(cardRef.power)
	toughness = int(cardRef.toughness)
	currentHP = toughness
	keywords = cardRef.keywords
	type = cardRef.type
	if cardRef.script != null:
		associatedScript = cardRef.script
	else:
		associatedScript = null
	
	inPlay = false
	#dragging = false
	zoomed = false
	exhausted = true

#Sets up the labels on the card node to display the correct parameters
func SetDisplay():
	self.get_node("Container/Image").set_texture(image)
	self.get_node("Container/PowerToughness").set_text(str(power) + "/" + str(currentHP))
	self.get_node("Container/Name").set_text(name)
	self.get_node("Container/Cost").set_text(str(cost))
	var displayWords = ""
	for i in range(keywords.size()):
		displayWords += keywords[i] + ", "
	
	displayWords = displayWords.substr(0, displayWords.length() - 2)
	self.get_node("Container/Keywords").set_text(displayWords)

func _ready():
	set_process_input(true)
	set_process(true)

#This card's input event handler
func _input(event):
	#Create a scaled rectangle representing the true size of the card
	var rect = self.get_rect()
	var scale = self.get_scale()
	var scaledRect = Rect2(rect.pos.x, rect.pos.y, scale.x * rect.size.x, scale.y * rect.size.y)
	
	#If the input event is a mouse button changing
	#and the scaled card contains the mouse
	if event.type == InputEvent.MOUSE_BUTTON and scaledRect.has_point(event.pos):
		#If our player's manager isn't in the play phase, return.
		if player.manager.phase != player.manager.PLAY_PHASE:
			return
		
		#If the event is a left mouse button being pressed
		if event.is_action_pressed("mouse_left"):
			#If the card is already in play, return
			if inPlay == true:
				return
			
			#...then set us to being dragged
			dragging = true
			
			#and the player's dragging card to us!
			player.draggingCard = self
			
		#else if the left mouse button has been released, and the player is dragging a card
		elif event.is_action_released("mouse_left") and player.draggingCard != null:
			if inPlay == true:
				return
			
			#then iterate through the lanes
			for lane in player.lanes:
				#Get the lane rectangle
				var laneRect = Rect2(lane.get_global_pos(), lane.get_size())
				
				#Get the global position of the mouse (not relative to us)
				var pos = event.global_pos
				
				#if this lane doesn't contain the mouse, continue
				if not laneRect.has_point(pos): 
					continue
				
				#if it does, try to summon us!
				if player.Summon(self, lane.laneNumber):
					break
				
				#If we're a hindrance, don't try to summon us,
				#because we don't belong in player lanes
				if self.keywords.has("Hinderance"):
					continue
				
				#Performing a check for enhancements to see if there's a card
				#If there isn't, continue
				if lane.myCard == null:
					continue
				
				#Otherwise, try to enhance!
				if player.Enhance(self, lane.myCard):
					break
			
			#Now, move onto the other player's lanes
			for lane in player.otherPlayer.lanes:
				#If the other player has no card in their lane, continue
				#Because the only thing we can do to other player's lanes
				#Is hinder the creatures in them
				if lane.myCard == null:
					continue
				
				#Get the lane rectangle
				var laneRect = Rect2(lane.get_global_pos(), lane.get_size())
				
				#Get the global mouse position
				var pos = event.global_pos
				
				#If the lane rectangle doesn't contain the mouse position, continue
				if not laneRect.has_point(pos):
					continue
				
				#If we're an enhancement, we don't belong here, so continue
				if self.keywords.has("Enhancement"):
					continue
				
				#Otherwise, try to hinder
				if player.Hinder(self, lane.myCard):
					break
			
			#And drop the card
			dragging = false
			player.draggingCard = null
			
		elif event.is_action_released("mouse_right"):
			zoomed = !zoomed
			if zoomed:
				ScaleUp()
			else:
				ScaleDown()
			
			self.raise()

func _process(delta):
	pass

func AddEnhancement(card):
	enhancements.push_back(card)
	ModifyMe(card)

func AddHinderance(card):
	hinderances.push_back(card)
	ModifyMe(card)

func ModifyMe(card):
	power += card.power
	toughness += card.toughness
	currentHP += card.toughness
	
	#for keyword in card.keywords:
	#	keywords.push_back(keyword)
	
	SetDisplay()
	

func ScaleUp():
	#self.get_parent().move_child(self, self.get_parent().get_children().size())
	self.set_scale(Vector2(1.0, 1.0))
	var position = self.get_pos()
	var size = self.get_size()
	self.set_pos(Vector2(position.x, position.y - (size.y / 2)))

func ScaleDown():
	var position = self.get_pos()
	var size = self.get_size()
	self.set_pos(Vector2(position.x, position.y + (size.y / 2)))
	self.set_scale(Vector2(0.5, 0.5))
	
func ToString():
	return "[ " + name + " : " + player.get_name() + " ]"
	
func DamageMe(value):
	self.currentHP -= value
	SetDisplay()

func DoCombat(other):
	self.currentHP -= other.power
	other.currentHP -= self.power
	SetDisplay()
	other.SetDisplay()
extends Node

var name = "UNINITIALISED"
var image
var cost = 1
var power = 0
var toughness = 1
var keywords = []
var type
var associatedScript

const CREATURE = 1
const SPELL = 2
const INSTANT = 3

const WIDTH = 308
const HEIGHT = 408

var dragging
var zoomed

var player

var enhancements = []
var hinderances = []

var inPlay
var currentHP
var exhausted

var safeForRemoval = false

func SetParametersFromCard(cardRef):
	name = cardRef.name
	image = cardRef.image
	cost = cardRef.cost
	power = cardRef.power
	toughness = cardRef.toughness
	currentHP = toughness
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

func _input(event):	
	var rect = self.get_rect()
	var scale = self.get_scale()
	var scaledRect = Rect2(rect.pos.x, rect.pos.y, scale.x * rect.size.x, scale.y * rect.size.y)
	
	if event.type == InputEvent.MOUSE_BUTTON and scaledRect.has_point(event.pos):
		if player.manager.phase != player.manager.PLAY_PHASE:
			return
		
		if event.is_action_pressed("mouse_left"):
			if inPlay == true:
				return
			
			dragging = true
			player.draggingCard = self
			
		elif event.is_action_released("mouse_left") and player.draggingCard != null:
			if inPlay == true:
				return
			
			for lane in player.lanes:
				var laneRect = Rect2(lane.get_global_pos(), lane.get_size())
				
				var pos = event.global_pos
				
				if not laneRect.has_point(pos): 
					continue
				
				if player.Summon(self, lane.laneNumber):
					break
				
				if self.keywords.has("Hinderance"):
					continue
				
				if lane.myCard == null:
					continue
				
				if player.Enhance(self, lane.myCard):
					break
			
			for lane in player.otherPlayer.lanes:
				if lane.myCard == null:
					continue
				
				var laneRect = Rect2(lane.get_global_pos(), lane.get_size())
				
				var pos = event.global_pos
				
				if not laneRect.has_point(pos):
					continue
				
				if self.keywords.has("Enhancement"):
					continue
				
				if player.Hinder(self, lane.myCard):
					break
			
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
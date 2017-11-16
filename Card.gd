extends Node

var name = "Debug Cat"
var image
var cost = 1
var power = 0
var toughness = 1
var keywords = []
var type
var script

const CREATURE = 1
const SPELL = 2

const WIDTH = 308
const HEIGHT = 408

var dragging
var zoomed

var player

var enhancements = []
var hinderances = []

var inPlay

func SetParameters(cardRef):
	name = cardRef.name
	image = cardRef.image
	cost = cardRef.cost
	power = cardRef.power
	toughness = cardRef.toughness
	keywords = cardRef.keywords
	type = cardRef.type
	if cardRef.script != "none":
		script = "res://cards/scripts/" + cardRef.script
	
	inPlay = false
	#dragging = false
	zoomed = false

func SetDisplay():
	self.get_node("Container/Image").set_texture(image)
	self.get_node("Container/PowerToughness").set_text(str(power) + "/" + str(toughness))
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
	player = self.get_tree().get_root().get_node("Root/Player1")

func _input(event):
	var rect = self.get_rect()
	var scale = self.get_scale()
	var scaledRect = Rect2(rect.pos.x, rect.pos.y, scale.x * rect.size.x, scale.y * rect.size.y)
	
	if event.type == InputEvent.MOUSE_BUTTON and scaledRect.has_point(event.pos):
		if event.is_action_pressed("mouse_left"):
			if inPlay == true:
				return
			
			dragging = true
			player.draggingCard = self
			
		elif event.is_action_released("mouse_left") and player.draggingCard != null:
			if inPlay == true:
				return
			
			for lane in player.lanes:
				if lane.myCard == null:
					continue
				
				var laneRect = lane.myCard.get_rect()
				var laneScale = lane.myCard.get_scale()
				var scaledLane = Rect2(laneRect.pos.x, laneRect.pos.y, laneScale.x * laneRect.size.x, laneScale.y * laneRect.size.y)
				
				if not scaledLane.intersects(scaledRect):
					continue
				
				if player.Enhance(self, lane.myCard):
					break
			
			for lane in player.otherPlayer.lanes:
				if lane.myCard == null:
					continue
				
				var laneRect = lane.myCard.get_rect()
				var laneScale = lane.myCard.get_scale()
				var scaledLane = Rect2(laneRect.pos.x, laneRect.pos.y, laneScale.x * laneRect.size.x, laneScale.y * laneRect.size.y)
				
				if not scaledLane.intersects(scaledRect):
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

func _process(delta):
	pass

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
	
func OnMouseEnter():
	pass
	#self.get_parent().move_child(self, self.get_parent().get_children().size() - 1)

func OnMouseExit():
	pass
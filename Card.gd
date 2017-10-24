extends Node

var name = "Debug Cat"
var image
var cost = 1
var power = 0
var toughness = 1
var keywords = []
var type

const CREATURE = 1
const SPELL = 2

const WIDTH = 308
const HEIGHT = 408

var dragging
var zoomed

var player

var enhancements = []

func SetParameters(cardRef):
	name = cardRef.name
	image = cardRef.image
	cost = cardRef.cost
	power = cardRef.power
	toughness = cardRef.toughness
	keywords = cardRef.keywords
	type = cardRef.type

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
		if event.is_action_pressed("mouse_left") and player.draggingCard == null:
			dragging = true
			player.draggingCard = self
		elif event.is_action_released("mouse_left") and player.draggingCard != null:
			dragging = false
			player.draggingCard = null
		elif event.is_action_released("mouse_right"):
			zoomed = !zoomed
			if zoomed:
				ScaleUp()
			else:
				ScaleDown()
	
	if event.type == InputEvent.MOUSE_MOTION and scaledRect.has_point(event.pos):
		if player.draggingCard == null:
			return
		
		if player.Enhance(player.draggingCard, self):
			enhancements.push_back(player.draggingCard)
			player.draggingCard.dragging = false
			player.draggingCard = null

func _process(delta):
	var position = self.get_pos()
	for i in range(enhancements.size()):
		enhancements[i].set_pos(Vector2(position.x, position.y + ((i + 1) * 30)))

func ScaleUp():
	self.get_parent().move_child(self, self.get_parent().get_children().size())
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
	self.get_parent().move_child(self, self.get_parent().get_children().size() - 1)

func OnMouseExit():
	pass
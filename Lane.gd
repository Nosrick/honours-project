extends Panel

var player
var manager
var laneNumber
var myCard

func _ready():
	var name = self.get_name()
	laneNumber = int(name.substr(4, 1)) - 1
	set_process_input(true)
	set_process(true)

func _input(event):
	if event.type == InputEvent.MOUSE_BUTTON:
		
		if player.draggingCard == null:
			return
		
		if myCard != null:
			return
		
		var mousePos = event.pos
		if not self.get_rect().has_point(mousePos):
			return
		
		if player.Summon(player.draggingCard, laneNumber):
			player.draggingCard.set_global_pos(self.get_global_pos())
			myCard = player.draggingCard
			player.draggingCard.dragging = false
			player.draggingCard = null

func _process(delta):
	if myCard == null:
		return
	
	myCard.set_global_pos(self.get_global_pos())
	#myCard.get_parent().move_child(myCard, myCard.get_parent().get_children().size())
	var modifiers = []
	
	for enhancement in myCard.enhancements:
		modifiers.append(enhancement)
	
	for hinderance in myCard.hinderances:
		modifiers.append(hinderance)
	
	for i in range(modifiers.size()):
		var position = myCard.get_global_pos()
		modifiers[i].set_global_pos(Vector2(position.x, position.y + ((i + 1) * 30)))
		modifiers[i].get_parent().move_child(modifiers[i], modifiers[i].get_parent().get_children().size() - (i + 1))
		modifiers[i].set_draw_behind_parent(true)
	
	myCard.raise()
	
	if myCard.currentHP <= 0:
		for i in range(myCard.hinderances.size()):
			self.remove_child(myCard.hinderances[0])
		
		for i in range(myCard.enhancements.size()):
			self.remove_child(myCard.enhancements[0])
		
		player.remove_child(myCard)
		myCard = null
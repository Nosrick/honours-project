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
	if event.type == InputEvent.MOUSE_MOTION:
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
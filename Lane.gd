extends Panel

var player
var laneNumber
var myCard

func _ready():
	var name = self.get_name()
	laneNumber = int(name.substr(4, 1)) - 1
	player = self.get_tree().get_root().get_node("Root/Player1")
	set_process_input(true)
	set_process(true)

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		if player.draggingCard == null:
			return
		
		if myCard != null:
			return
		
		var mousePos = event.pos
		if mousePos.x > self.get_global_pos().x and mousePos.x < self.get_global_pos().x + self.get_size().x and mousePos.y > self.get_global_pos().y and mousePos.y < self.get_global_pos().y + self.get_size().y:
			player.draggingCard.set_global_pos(self.get_global_pos())
			player.Summon(player.draggingCard, laneNumber)
			player.draggingCard.dragging = false
			myCard = player.draggingCard

func _process(delta):
	if myCard == null:
		return
	
	myCard.set_global_pos(self.get_global_pos())
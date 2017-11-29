extends Container

var player

func _ready():
	player = self.get_tree().get_root().get_node("Root/Player1")
	set_process_input(true)
	
func _input(event):
	if event.type == InputEvent.MOUSE_BUTTON:
		if event.is_action_released("mouse_left"):
			if self.get_global_rect().has_point(event.global_pos):
				if player.draggingCard == null and player.manager.phase == player.manager.DRAW_PHASE:
					player.Draw()
				elif player.draggingCard != null:
					player.Replace(player.draggingCard)
					player.RedrawHand()
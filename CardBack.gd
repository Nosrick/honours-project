extends Container

var player

func _ready():
	player = self.get_tree().get_root().get_node("Root/Player1")
	set_process_input(true)

#The input event for the card back
func _input(event):
	#if the event type is a mouse button
	if event.type == InputEvent.MOUSE_BUTTON:
		#and it's the left mouse button being released
		if event.is_action_released("mouse_left"):
			#if we contain the global mouse position
			if self.get_global_rect().has_point(event.global_pos):
				#and the player is dragging a card
				if player.draggingCard != null:
					#replace the card
					player.Replace(player.draggingCard)
					#and redraw the player's hand with the new card in its place
					player.RedrawHand()
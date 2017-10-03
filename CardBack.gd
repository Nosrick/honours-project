extends Container

var player

func _ready():
	player = self.get_tree().get_root().get_node("Root/Player1")
	set_process_input(true)
	
func _input(event):
	if event.type == InputEvent.MOUSE_BUTTON:
		if event.is_action_pressed("mouse_left"):
			player.Draw()
extends Button

func Pressed():
	if GlobalVariables.brainOrder.size() != 0:
		get_tree().change_scene("res://scenes/Root.tscn")
	else:
		get_tree().change_scene("res://scenes/BrainSelect.tscn")
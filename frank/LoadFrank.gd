extends BaseButton

func Pressed():
	GlobalVariables.brainOrder.push_back(4)
	get_tree().change_scene("res://scenes/Root.tscn")
extends BaseButton

func Pressed():
	GlobalVariables.brainOrder.push_back(1)
	get_tree().change_scene("res://scenes/Root.tscn")
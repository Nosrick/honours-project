extends BaseButton

func Pressed():
	GlobalVariables.brainOrder.push_back(0)
	get_tree().change_scene("res://scenes/Root.tscn")
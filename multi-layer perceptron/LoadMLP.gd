extends BaseButton

func Pressed():
	GlobalVariables.brainOrder.push_back(3)
	get_tree().change_scene("res://scenes/Root.tscn")
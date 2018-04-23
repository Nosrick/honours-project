extends BaseButton

func Pressed():
	GlobalVariables.brainOrder.push_back(2)
	get_tree().change_scene("res://scenes/Root.tscn")
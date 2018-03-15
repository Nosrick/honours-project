extends BaseButton

func Pressed():
	GlobalVariables.brainType = 3
	get_tree().change_scene("res://scenes/Root.tscn")
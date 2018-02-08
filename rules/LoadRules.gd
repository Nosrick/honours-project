extends BaseButton

func Pressed():
	GlobalVariables.brainType = 1
	get_tree().change_scene("res://scenes/Root.tscn")
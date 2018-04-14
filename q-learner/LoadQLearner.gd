extends BaseButton

func Pressed():
	GlobalVariables.brainType = 2
	get_tree().change_scene("res://scenes/Root.tscn")
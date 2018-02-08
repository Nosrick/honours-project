extends BaseButton

func Pressed():
	GlobalVariables.brainType = 0
	get_tree().change_scene("res://scenes/Root.tscn")
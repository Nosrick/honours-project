extends Label

func _ready():
	set_text(GlobalVariables.message)
	get_tree().get_root().get_node("Root/MatchIDLabel").set_text(GlobalVariables.lastMatchID)
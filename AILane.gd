extends Panel

var player
var laneNumber
var myCard

func _ready():
	var name = self.get_name()
	laneNumber = int(name.substr(4, 1)) - 1
	set_process_input(true)
	set_process(true)

func _process(delta):
	if myCard == null:
		return
	
	myCard.set_global_pos(self.get_global_pos())
	
	if myCard.currentHP <= 0:
		player.remove_child(myCard)
		myCard = null
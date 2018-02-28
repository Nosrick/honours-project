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
	
	var modifiers = []
	
	for enhancement in myCard.enhancements:
		modifiers.append(enhancement)
	
	for hinderance in myCard.hinderances:
		modifiers.append(hinderance)
	
	for i in range(modifiers.size()):
		var position = myCard.get_pos()
		modifiers[i].set_global_pos(Vector2(position.x, position.y + ((i + 1) * 30)))
		modifiers[i].get_parent().move_child(modifiers[i], modifiers[i].get_parent().get_children().size() - (i + 1))
		modifiers[i].set_draw_behind_parent(true)
	
	myCard.raise()
	
	if myCard.currentHP <= 0:
		player.remove_child(myCard)
		player.discardPile.push_back(myCard)
		myCard = null
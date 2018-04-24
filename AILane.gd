extends Panel

var player
var laneNumber
var myCard

func _ready():
	#Set the lane number for this lane
	var name = self.get_name()
	laneNumber = int(name.substr(4, 1)) - 1
	
	#Turn on processing
	set_process_input(true)
	set_process(true)

func _process(delta):
	#No point in doing anything here if we don't have a card!
	if myCard == null:
		return
	
	#Keep our card set to our position
	myCard.set_global_pos(self.get_global_pos())
	
	var modifiers = []
	
	for enhancement in myCard.enhancements:
		modifiers.append(enhancement)
	
	for hinderance in myCard.hinderances:
		modifiers.append(hinderance)
	
	#Make a "tail" of modifiers
	for i in range(modifiers.size()):
		var position = myCard.get_pos()
		modifiers[i].set_global_pos(Vector2(position.x, position.y + ((i + 1) * 30)))
		modifiers[i].get_parent().move_child(modifiers[i], modifiers[i].get_parent().get_children().size() - (i + 1))
		modifiers[i].set_draw_behind_parent(true)
	
	#Ensure the card is on top of the draw order
	myCard.raise()
	
	if myCard.currentHP <= 0:
		player.remove_child(myCard)
		player.discardPile.push_back(myCard)
		myCard = null
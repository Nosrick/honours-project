extends Panel
#For all intents and purposes, this is almost identical to the AILane class

#The player that this lane belongs to
var player

#The identifying lane number for this lane
var laneNumber

#The card currently in this lane
var myCard

func _ready():
	#Set our lane number
	var name = self.get_name()
	laneNumber = int(name.substr(4, 1)) - 1
	
	#Set our processes to process
	set_process_input(true)
	set_process(true)

func _input(event):
	pass

func _process(delta):
	#No point in doing anything if we don't have a card
	if myCard == null:
		return
	
	#Set our card's position to our position
	myCard.set_global_pos(self.get_global_pos())
	#myCard.get_parent().move_child(myCard, myCard.get_parent().get_children().size())
	var modifiers = []
	
	#Add our enhancements
	for enhancement in myCard.enhancements:
		modifiers.append(enhancement)
	
	#and out hindrances to the same list
	for hinderance in myCard.hinderances:
		modifiers.append(hinderance)
	
	#So they can be made into a 'tail'
	for i in range(modifiers.size()):
		var position = myCard.get_global_pos()
		modifiers[i].set_global_pos(Vector2(position.x, position.y + ((i + 1) * 30)))
		modifiers[i].get_parent().move_child(modifiers[i], modifiers[i].get_parent().get_children().size() - (i + 1))
		modifiers[i].set_draw_behind_parent(true)
	
	#Raise our card to the top of the order
	myCard.raise()
extends Node

static func Do(card):
	var player = card.player
	var otherPlayer = card.player.otherPlayer
	
	var manager = card.player.manager
	for i in range(0, player.lanes.size()):
		if player.lanes[i].myCard == card and otherPlayer.lanes[i].myCard != null:
			var curse = manager.GetCard("Curse")
			otherPlayer.lanes[i].myCard.add_child(curse)
			otherPlayer.lanes[i].myCard.AddHinderance(curse)
extends Node

func Do(card):
	var player = card.player
	for i in range(player.lanes.size()):
		if player.lanes[i].myCard == card:
			if i != 0 and player.lanes[i - 1].myCard != null:
				player.lanes[i - 1].myCard.DamageMe(1)
			
			player.lanes[i].myCard.DamageMe(2)
			
			if i != 3 and player.lanes[i + 1].myCard != null:
				player.lanes[i + 1].myCard.DamageMe(1)

func _ready():
	pass
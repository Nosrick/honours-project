extends Node

var cards = []

func _init(cardsRef):
	cards = cardsRef
	
#Based on the Fisher-Yates shuffle
func Shuffle():
	var n = cards.size()
	while n > 1:
		n -= 1
		var k = randi() % (n + 1)
		var value = cards[k]
		cards[n] = cards[k]
		cards[k] = value

func Draw():
	return cards.pop_front()
	
func Return(card):
	cards.push_back(card)
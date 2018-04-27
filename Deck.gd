extends Node

var cards = []

#The constructor for the class
func _init(cardsRef):
	cards = cardsRef

#Destroys the entire deck by freeing the memory used by the cards
func Destroy():
	for card in cards:
		card.free()

#Based on the Fisher-Yates shuffle
func Shuffle():
	var n = cards.size()
	while n > 1:
		n -= 1
		var k = randi() % (n + 1)
		var kValue = cards[k]
		var nValue = cards[n]
		cards[n] = kValue
		cards[k] = nValue

#Draw a card from the deck
func Draw():
	if cards.size() > 0:
		var card = cards[0]
		cards.pop_front()
		return card
	
	return null
	
#Returns a card to the deck
func Return(card):
	cards.push_back(card)
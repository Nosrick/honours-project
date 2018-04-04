extends Node

var cards = []
var CardNode = load("res://scenes/Card.tscn")

var player1
var player2

var turnPlayer
var haveDrawn
var haveAttacked

const DRAW_PHASE = 0
const PLAY_PHASE = 1
const ATTACK_PHASE = 2

var phase

const MAX_MANA = 6
var turn = 1

var gameOver = false

func _ready():
	pass

func IsMyTurn(player):
	return turnPlayer == player

func StartTurn():
	phase = DRAW_PHASE
	turnPlayer.mana = min(MAX_MANA, turn)
	turnPlayer.replacementsDone = 0
	turnPlayer.Draw()
	
	for lane in turnPlayer.lanes:
		if lane.myCard != null:
			lane.myCard.exhausted = false

func EndTurn():
	if turnPlayer == player1:
		turnPlayer = player2
	else:
		turnPlayer = player1
		turn += 1
	
	RunAttacks()
	
	StartTurn()

func _process(delta):
	Run()

func Run():
	if player1 == null or player2 == null:
		return
	
	#End game state
	if player1.currentHP <= 0:
		gameOver = true
	elif player2.currentHP <= 0:
		gameOver = true

func RunAttacks():
	for i in range(player1.lanes.size()):
		var player1Card = player1.lanes[i].myCard
		var player2Card = player2.lanes[i].myCard
		
		if player1Card != null and player2Card != null:
			if turnPlayer == player1 and player1Card.exhausted == false:
				player1Card.DoCombat(player2Card)
			elif turnPlayer == player2 and player2Card.exhausted == false:
				player2Card.DoCombat(player1Card)
		
		else:
			if turnPlayer == player1 and player1Card != null and player1Card.exhausted == false:
				player1Card.DoCombat(player2)
			elif turnPlayer == player2 and player2Card != null and player2Card.exhausted == false:
				player2Card.DoCombat(player1)
	
	player1.CleanUpLanes()
	player2.CleanUpLanes()

func GetCard(name):
	for card in cards:
		if card.name == name:
			var newCard = CardNode.instance()
			newCard.SetParametersFromCard(card)
			newCard.SetDisplay()
			return newCard
	
	return null
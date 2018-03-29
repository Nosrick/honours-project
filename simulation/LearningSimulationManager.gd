 extends Node

var brain1
var brain2

var simulationManager = load("res://simulation/SimulationManager.gd").new()
var cards = []

var player1Name
var player2Name

var player1Wins = 0
var player2Wins = 0
var draws = 0
var errors = 0
var gamesTotal = 0

var GUID = randi()

const filePath = "res://SimulationStats.json"

func AttachBrains():
	
	var cardLoader = load("res://CardLoader.gd").new()
	cards = cardLoader.LoadCards()
	
	var deckCards1 = []
	for i in range(4):
		for card in cards:
			deckCards1.append(card)
	
	var deckCards2 = []
	for i in range(4):
		for card in cards:
			deckCards2.append(card)
	
	var hand1 = []
	var discard1 = []
	var deck1 = load("res://Deck.gd").new(deckCards1)
	for i in range(0, 10):
		deck1.Shuffle()
	
	var brain1Node = get_tree().get_root().get_node("Root/Brain1")
	brain1Node.set_script(brain1.get_script())
	brain1Node.player = load("res://simulation/SimulationPlayer.gd").new(hand1, deck1, 1, 20, discard1)
	
	brain1Node.trainingCards = cards
	
	var hand2 = []
	var discard2 = []
	var deck2 = load("res://Deck.gd").new(deckCards2)
	for i in range(0, 10):
		deck2.Shuffle()
	
	var brain2Node = get_tree().get_root().get_node("Root/Brain2")
	brain2Node.set_script(brain2.get_script())
	brain2Node.player = load("res://simulation/SimulationPlayer.gd").new(hand2, deck2, 1, 20, discard2)
	
	brain2Node.trainingCards = cards

	brain1Node.otherPlayer = brain2Node.player
	brain2Node.otherPlayer = brain1Node.player
	
	simulationManager.player1 = brain1Node.player
	simulationManager.player2 = brain2Node.player
	
	simulationManager.player1.otherPlayer = brain2Node.player
	simulationManager.player2.otherPlayer = brain1Node.player
	
	simulationManager.player1.manager = simulationManager
	simulationManager.player2.manager = simulationManager
	
	simulationManager.turnPlayer = simulationManager.player1
	
	brain1Node.Begin()
	brain1Node.manager = simulationManager
	
	brain2Node.Begin()
	brain2Node.manager = simulationManager
	
	simulationManager.cards = cards
	
	brain1 = brain1Node
	brain2 = brain2Node
	
	player1Name = brain1.name
	player2Name = brain2.name
	
	simulationManager.StartTurn()

func _ready():
	randomize()
	set_process(true)

func _process(delta):
	simulationManager.Run()
	
	if simulationManager.gameOver == true:
		gamesTotal = 1
		
		if simulationManager.player1.currentHP <= 0 and simulationManager.player2.currentHP >= 0:
			player2Wins = 1
		elif simulationManager.player2.currentHP <= 0 and simulationManager.player1.currentHP >= 0:
			player1Wins = 1
		elif simulationManager.player1.currentHP <= 0 and simulationManager.player2.currentHP <= 0:
			draws = 1
		else:
			errors = 1
		
		brain1.EndGame()
		brain2.EndGame()
		Serialise()
		GUID = randi()
		gamesTotal = 0
		player2Wins = 0
		player1Wins = 0
		draws = 0
		errors = 0
		
		simulationManager = load("res://simulation/SimulationManager.gd").new()
		AttachBrains()
		get_tree().get_root().get_node("Root/Label").set_text("Simulating")
		

func Serialise():
	get_tree().get_root().get_node("Root/Label").set_text("Serialising...")
	var file = File.new()
	if file.file_exists(filePath):
		file.open(filePath, File.READ_WRITE)
	else:
		file.open(filePath, File.WRITE_READ)
	
	var string = file.get_as_text()
	var oldData = {}
	oldData.parse_json(string)
	
	var data = {}
	data["simulation"] = {}
	data["simulation"][GUID] = {}
	data["simulation"][GUID]["opponents"] = player1Name + " vs " + player2Name
	data["simulation"][GUID]["draws"] = draws
	data["simulation"][GUID]["errors"] = errors
	data["simulation"][GUID]["gamesTotal"] = gamesTotal
	
	data["simulation"][GUID]["player1"] = {}
	data["simulation"][GUID]["player1"]["player1Name"] = player1Name
	data["simulation"][GUID]["player1"]["player1Wins"] = player1Wins
	
	data["simulation"][GUID]["player2"] = {}
	data["simulation"][GUID]["player2"]["player2Name"] = player2Name
	data["simulation"][GUID]["player2"]["player2Wins"] = player2Wins
	
	JoinDictionaries(data, oldData)
	string = data.to_json()
	
	file.store_line(string)
	file.close()

func GetWinRatio():
	var file = File.new()
	if file.file_exists(filePath):
		file.open(filePath, File.READ)
	else:
		return Vector2(0, 0)
	
	var string = file.get_as_text()
	var data = {}
	data.parse_json(string)
	var winRatio = Vector3(0, 0, 0)
	
	for GUID in data["simulation"]:
		var simPlayer1Name = data["simulation"][GUID]["player1"]["player1Name"]
		var simPlayer2Name = data["simulation"][GUID]["player2"]["player2Name"]
		
		if (simPlayer1Name == player1Name and simPlayer2Name == player2Name):
			winRatio.x += data["simulation"][GUID]["player1"]["player1Wins"]
			winRatio.y += data["simulation"][GUID]["player2"]["player2Wins"]
			winRatio.z += data["simulation"][GUID]["gamesTotal"]
		elif (simPlayer1Name == player2Name and simPlayer2Name == player1Name):
			winRatio.x += data["simulation"][GUID]["player2"]["player2Wins"]
			winRatio.y += data["simulation"][GUID]["player1"]["player1Wins"]
			winRatio.z += data["simulation"][GUID]["gamesTotal"]
	
	return winRatio

func JoinDictionaries(left, right):
	if right.has("simulation"):
		for key in right["simulation"]:
			left["simulation"][key] = right["simulation"][key]
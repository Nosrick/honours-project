extends Node

var console
var neuralNet

var lastColour

var inputStage = 0
var AWAIT_COLOUR = 0
var AWAIT_ANSWER = 1

func _ready():
	console = get_tree().get_root().get_node("./Root/TextConsole")
	neuralNet = get_tree().get_root().get_node("./Root/NeuralNet")
	
	set_process_input(true)
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		var input = get_text()
		input = input.to_lower()
		
		if input == "clear":
			clear()
		
		elif inputStage == AWAIT_COLOUR:
			var colour = Color(input)
			
			var red = colour.r
			var green = colour.g
			var blue = colour.b
			
			var colours = []
			colours.append(red)
			colours.append(green)
			colours.append(blue)
			
			lastColour = colours
			
			var winner = neuralNet.GetBestMatch(colours)
			
			var myColour = Color(winner.weights[0], winner.weights[1], winner.weights[2])
			
			console.append_bbcode("[color=" + input + "]Your colour: " + input + "\n")
			console.append_bbcode("[color=#" + myColour.to_html() + "]My colour: " + myColour.to_html() + "\n")
			console.add_text("Is this close enough? Y/N\n")
			inputStage = AWAIT_ANSWER
			set_text("")
			
		elif inputStage == AWAIT_ANSWER:
			if input == "n":
				neuralNet.Retrain(lastColour)
				console.add_text("Retraining.\n")
			elif input == "y":
				console.add_text("Reinforcing.\n")
				neuralNet.Reinforce(lastColour)
			
			inputStage = AWAIT_COLOUR
			set_text("")
	
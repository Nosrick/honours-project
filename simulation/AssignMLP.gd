extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func Pressed():
	var buttonManager = get_tree().get_root().get_node("Root/ButtonManager")
	var brain = load("res://multi-layer perceptron/TDLBrain.gd")
	buttonManager.players.push_back(brain)
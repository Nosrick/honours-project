extends Node

func _ready():
	randomize()

func Pressed():
	get_tree().change_scene("res://scenes/Simulation.tscn")

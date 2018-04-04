extends Node

func Pressed():
	var simulationManager = get_tree().get_root().get_node("Root")
	simulationManager.brain1.EndGame()
	simulationManager.brain2.EndGame()
	simulationManager.Serialise()
	#get_tree().change_scene("res://scenes/Simulation.tscn")
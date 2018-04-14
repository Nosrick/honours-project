extends Button

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func Pressed():
	var simulationManager = get_tree().get_root().get_node("Root")
	var winRatio = simulationManager.GetWinRatio()
	
	var string = simulationManager.player1Name + ": " + str(winRatio.x) + " | " + simulationManager.player2Name + ": " + str(winRatio.y) + " | Total Games: " + str(winRatio.z)
	get_tree().get_root().get_node("Root/StatsButton/StatsLabel").set_text(string)
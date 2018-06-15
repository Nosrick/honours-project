extends Tree

const fileName = "res://PlayStats.json"

func GetStats():
	var file = File.new()
	
	file.open(fileName, File.READ)
	
	var string = file.get_as_text()
	var data = {}
	data.parse_json(string)
	
	file.close()
	
	var stats = {}
	stats.random = {}
	stats.random.AIWins = 0
	stats.random.totalGames = 0
	stats.random.averageTurnTime = 0
	
	stats.rulesBased = {}
	stats.rulesBased.AIWins = 0
	stats.rulesBased.totalGames = 0
	stats.rulesBased.averageTurnTime = 0
	
	stats.qLearner = {}
	stats.qLearner.AIWins = 0
	stats.qLearner.totalGames = 0
	stats.qLearner.averageTurnTime = 0
	
	stats.TDL = {}
	stats.TDL.AIWins = 0
	stats.TDL.totalGames = 0
	stats.TDL.averageTurnTime = 0
	
	stats.frank = {}
	stats.frank.AIWins = 0
	stats.frank.totalGames = 0
	stats.frank.averateTurnTime = 0
	
	for key in data.keys():
		var item = data[key]
		if item.brainType == 0:
			if item.whichPlayerWon == 2:
				stats.random.AIWins += 1
			stats.random.totalGames += 1
			stats.random.averageTurnTime = item.averageTurnTime
		
		elif item.brainType == 1:
			if item.whichPlayerWon == 2:
				stats.rulesBased.AIWins += 1
			stats.rulesBased.totalGames += 1
			stats.rulesBased.averageTurnTime = item.averageTurnTime
		
		elif item.brainType == 2:
			if item.whichPlayerWon == 2:
				stats.qLearner.AIWins += 1
			stats.qLearner.totalGames += 1
			stats.qLearner.averageTurnTime = item.averageTurnTime
		
		elif item.brainType == 3:
			if item.whichPlayerWon == 2:
				stats.TDL.AIWins += 1
			stats.TDL.totalGames += 1
			stats.TDL.averageTurnTime = item.averageTurnTime
		
		elif item.brainType == 4:
			if item.whichPlayerWon == 2:
				stats.frank.AIWins += 1
			stats.frank.totalGames += 1
			stats.frank.averageTurnTime = item.averageTurnTime
	
	return stats

func _ready():
	var stats = GetStats()
	var node = self.create_item()
	for item in stats.keys():
		var child = self.create_item(node)
		child.set_text(0, item)
		MakeChild(child, stats[item])

func MakeChild(node, dict):
	if typeof(dict) == TYPE_DICTIONARY:
		for item in dict.keys():
			var child = self.create_item(node)
			child.set_text(0, item)
			MakeChild(child, dict[item])
	else:
		var child = self.create_item(node)
		child.set_text(0, str(dict))
extends Control

var myCard

var tooltips = {}
var directory = "res://cards/tooltips"

func _ready():
	myCard = self.get_parent()
	LoadTooltips()
	
func LoadTooltips():
	var files = []
	
	var dir = Directory.new()
	dir.open(directory)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif file.ends_with(".json"):
			files.append(file)

	dir.list_dir_end()
	
	for i in range(files.size()):
		var dict = {}
		var file = File.new()
		file.open(directory + "/" + files[i], file.READ)
		var fileString = file.get_as_text()
		dict.parse_json(fileString)
		
		var keyword = dict.name
		tooltips[keyword] = dict.tooltip

func OnMouseEnter():
	var tooltip = ""
	for i in range(myCard.keywords.size()):
		if(tooltips.has(myCard.keywords[i])):
			tooltip += myCard.keywords[i] + ": " + tooltips[myCard.keywords[i]] + "\n"
	
	self.set_tooltip(tooltip)
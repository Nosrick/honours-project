extends Node

var directory = "res://cards"

func LoadCards():
	var cards = []
	
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
		dict.image = load("res://cards/images/" + dict.image)
		cards.append(dict)
	
	return cards
extends Node

const directory = "res://cards"
var cardNode = load("res://Card.gd")

#Load all the card .jsons
func LoadCards():
	var cards = []
	
	var files = []
	var dir = Directory.new()
	
	#Open the directory
	dir.open(directory)
	
	#Go to the start of the directory
	dir.list_dir_begin()

	#While true...
	while true:
		#Get the next file
		var file = dir.get_next()
		#if it's blank...
		if file == "":
			#...we break out of this while loop
			break
		#otherwise, if the file ends in .json...
		elif file.ends_with(".json"):
			#...append it to the files list
			files.append(file)

	#end the directory
	dir.list_dir_end()
	
	#Go through the files list
	for i in range(files.size()):
		var dict = {}
		
		var file = File.new()
		
		#Open the file
		file.open(directory + "/" + files[i], file.READ)
		
		#Get the whole file as text
		var fileString = file.get_as_text()
		
		#Parse the file as a JSON string
		dict.parse_json(fileString)
		
		#Load the image
		dict.image = load("res://cards/images/" + dict.image)
		
		#Get the cost
		dict.cost = int(dict.cost)
		
		#Get the type
		dict.type = int(dict.type)
		
		#Load the script, if there is one
		if dict.script != "none":
			dict.script = load("res://cards/scripts/" + dict.script + ".gd")
		else:
			dict.script = null
		
		#And create the card
		var card = cardNode.new()
		card.SetParameters(dict)
		
		#Add the card to the cards list
		cards.append(card)
	
	#We made it! Return the completed cards list.
	return cards
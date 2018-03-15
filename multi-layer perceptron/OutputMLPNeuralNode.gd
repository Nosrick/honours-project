extends Node

var mana
var weight

var tools = load("res://Tools.gd").new()

func _init(manaRef):
	mana = manaRef
	weight = (randf() / 2) - randf()

func ToString():
	return "[ " + str(mana) + " : " + str(weight) + " ]"

func Save():
	var data = {}
	data.mana = mana
	data.weight = weight
	
	return data
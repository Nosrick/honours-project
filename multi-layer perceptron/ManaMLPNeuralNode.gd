extends Node

var targetMana
var weight
var tWeight

func _init(manaRef):
	weight = (randf() / 2) - randf()
	tWeight = randf()
	targetMana = manaRef

func ToString():
	return "[" + targetMana + " : " + tWeight + "]"

func Save():
	var data = {}
	data.targetMana = targetMana
	data.tWeight = tWeight
	data.weight = weight
	return data
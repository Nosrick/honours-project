extends Node

#Tells the game what kind of brain type to use
#0 is random
#1 is rules based
#2 is Q-learning self-organising map
#3 is Temporal Difference Learning multi-layer perceptron
#4 is Frank

var brainType = 0

var message = "YOU WIN!"

var brainOrder = []

var lastMatchID = -1
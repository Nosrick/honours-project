extends Sprite

const FADE_RATE = 0.05
const MAX_ALPHA = 1.0

var alpha = MAX_ALPHA

func Begin():
	alpha = MAX_ALPHA
	set_modulate(Color(1.0, 1.0, 1.0, alpha))

func _ready():
	set_process(true)

func _process(delta):
	if alpha > 0:
		alpha -= FADE_RATE
		set_modulate(Color(1.0, 1.0, 1.0, alpha))
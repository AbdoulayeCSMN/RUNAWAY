extends Area2D
class_name Terminal
## Terminal = objectif secondaire (GDD 5.3). Maintenir E -> bonus de score.
## Ne declenche PAS l'alarme (contrairement au coffre).

@export var hold_time := 2.0
@export var bonus := 250

var _player_in := false
var _t := 0.0
var _done := false

@onready var prompt: Label = $Prompt
@onready var screen: Polygon2D = $Screen

func _ready() -> void:
	add_to_group("interactables")
	prompt.visible = false
	body_entered.connect(func(b): if b.is_in_group("player"): _player_in = true)
	body_exited.connect(func(b): if b.is_in_group("player"): _player_in = false)

func _process(delta: float) -> void:
	if _done or GameState.mission_over:
		return
	if _player_in:
		prompt.visible = true
		if Input.is_action_pressed("interact"):
			_t += delta
			prompt.text = "Acces... %d%%" % int(100.0 * _t / hold_time)
			if _t >= hold_time:
				_complete()
		else:
			_t = max(0.0, _t - delta * 2.0)
			prompt.text = "[E] Pirater le terminal (+%d)" % bonus
	else:
		prompt.visible = false
		_t = max(0.0, _t - delta * 2.0)

func _complete() -> void:
	_done = true
	prompt.text = "TERMINAL PIRATE  +%d" % bonus
	screen.color = Color(0.3, 0.85, 0.4)
	GameState.add_score(bonus)
	AudioManager.play_sfx("vault")

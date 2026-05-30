extends Area2D
class_name Coffre
## Coffre-fort = objectif principal (GDD 5.3).
## Maintenir E pendant 3s -> debloque l'objectif ET declenche l'alarme.

@export var hold_time := 3.0

var _player_in := false
var _t := 0.0
var _done := false

@onready var prompt: Label = $Prompt
@onready var body_rect: Polygon2D = $Body

func _ready() -> void:
	add_to_group("interactables")
	body_entered.connect(func(b): if b.is_in_group("player"): _player_in = true)
	body_exited.connect(func(b): if b.is_in_group("player"): _player_in = false)
	prompt.visible = false

func _process(delta: float) -> void:
	if _done or GameState.mission_over:
		return
	if _player_in:
		prompt.visible = true
		if Input.is_action_pressed("interact"):
			_t += delta
			prompt.text = "Piratage... %d%%" % int(100.0 * _t / hold_time)
			if _t >= hold_time:
				_complete()
		else:
			_t = max(0.0, _t - delta * 2.0)
			prompt.text = "[E] Pirater le coffre"
	else:
		prompt.visible = false
		_t = max(0.0, _t - delta * 2.0)

func _complete() -> void:
	_done = true
	prompt.text = "DONNEES RECUPEREES — FUYEZ !"
	body_rect.color = Color(0.2, 0.8, 0.3, 1.0)
	GameState.complete_objective()
	# Le coffre declenche l'alarme et reveille les gardes proches du coffre
	# (pas tout le batiment : ceux des etages eloignes restent en patrouille).
	GameState.notify_combat()
	GameState.alert_guards_near(global_position, 760.0)
	AudioManager.play_sfx("vault")

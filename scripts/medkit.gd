extends Area2D
class_name Medkit
## Trousse de soin : ramassage automatique au contact -> +1 PV (usage unique).

var _used := false

@onready var prompt: Label = $Prompt
@onready var body_rect: Polygon2D = $Body

func _ready() -> void:
	add_to_group("interactables")
	prompt.visible = false
	body_entered.connect(_on_enter)
	body_exited.connect(func(b): if b.is_in_group("player"): prompt.visible = false)

func _on_enter(b: Node) -> void:
	if _used or not b.is_in_group("player"):
		return
	if GameState.health >= GameState.MAX_HEALTH:
		prompt.visible = true
		prompt.text = "PV deja au max"
		return
	_used = true
	GameState.heal_player(1)
	AudioManager.play_sfx("vault")
	body_rect.color = Color(0.3, 0.3, 0.34)
	$Cross.visible = false
	prompt.visible = true
	prompt.text = "+1 PV"

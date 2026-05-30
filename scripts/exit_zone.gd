extends Area2D
class_name ExitZone
## Point d'exfiltration (GDD : Zone D). Atteindre la sortie APRES l'objectif = victoire.

@onready var prompt: Label = $Prompt

func _ready() -> void:
	add_to_group("exit")
	prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(func(b): if b.is_in_group("player"): prompt.visible = false)

func _on_body_entered(b: Node) -> void:
	if not b.is_in_group("player"):
		return
	# Le niveau courant exige-t-il l'objectif (coffre) avant de pouvoir sortir ?
	var lvl := get_tree().get_first_node_in_group("level")
	var needs_obj := true
	if lvl and lvl.has_method("needs_objective"):
		needs_obj = lvl.needs_objective()
	if needs_obj and not GameState.objective_done:
		prompt.visible = true
		prompt.text = "Recupere d'abord les donnees !"
		return
	# Sortie franchie : passe au niveau suivant ou termine la campagne.
	AudioManager.play_sfx("exfil")
	GameState.advance_or_finish("Exfiltration reussie.")

extends Control
## Ecran de briefing avant la mission (GDD 6.2).

const SCREEN := Vector2(1280, 720)

const BRIEF := "Agent Zero, le complexe Eclipse abrite des donnees classifiees.

OBJECTIFS
  - Infiltrer le batiment sans declencher l'alarme.
  - Pirater le coffre central (maintenir E pres du coffre).
  - Rejoindre la zone d'exfiltration (en haut a gauche).

CONSIGNES
  - Evitez les cones de vision des gardes.
  - Sprinter fait du bruit : les gardes peuvent vous entendre.
  - Restez pres des murs : mise en couverture automatique.
  - Une fois le coffre pirate, l'alarme se declenche : fuyez !

Discretion totale = bonus de score. Bonne chance."

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.08)
	add_child(bg)

	var title := Label.new()
	title.text = "BRIEFING DE MISSION"
	title.position = Vector2(0, 60)
	title.size = Vector2(SCREEN.x, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.5, 0.65, 0.95))
	add_child(title)

	var body := Label.new()
	body.text = BRIEF
	body.position = Vector2(SCREEN.x / 2 - 380, 160)
	body.size = Vector2(760, 400)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
	add_child(body)

	_button("COMMENCER", Vector2(SCREEN.x / 2 - 270, 600), _on_start)
	_button("RETOUR", Vector2(SCREEN.x / 2 + 10, 600), _on_back)

func _button(txt: String, pos: Vector2, cb: Callable) -> void:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = Vector2(260, 56)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(cb)
	add_child(b)

func _on_start() -> void:
	AudioManager.play_sfx("ui_click")
	GameState.reset_campaign()
	get_tree().change_scene_to_file("res://scenes/Level_01.tscn")

func _on_back() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# Bouton RETOUR Android : revient au menu principal.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()

extends Control
## Menu principal (GDD 6.2). Construit en code pour rester robuste.

const SCREEN := Vector2(1280, 720)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.07)
	add_child(bg)

	_label("RUNAWAY", 88, Color(0.9, 0.93, 1.0), Vector2(0, 140), 100)
	_label("OPERATION ECLIPSE", 30, Color(0.5, 0.65, 0.95), Vector2(0, 250), 44)

	var touch := DisplayServer.is_touchscreen_available()
	_button("JOUER", Vector2(SCREEN.x / 2 - 130, 380), _on_play)
	# Sur mobile on n'affiche pas de bouton "Quitter" (le systeme gere la sortie).
	if not touch:
		_button("QUITTER", Vector2(SCREEN.x / 2 - 130, 452), _on_quit)

	var hint := "Stick gauche : se deplacer (a fond = sprint)    Stick droit : viser et tirer    E : interagir    R : recharger    Retour : pause" if touch \
		else "WASD / Fleches : se deplacer    Clic : tirer    E : interagir    R : recharger    Maj : sprint    Echap : pause"
	_label(hint, 16, Color(0.5, 0.5, 0.6), Vector2(0, SCREEN.y - 50), 30)

func _label(txt: String, sz: int, col: Color, pos: Vector2, h: float) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.size = Vector2(SCREEN.x, h)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l

func _button(txt: String, pos: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = Vector2(260, 56)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(cb)
	add_child(b)
	return b

func _on_play() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/Briefing.tscn")

func _on_quit() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().quit()

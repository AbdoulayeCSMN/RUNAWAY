extends CanvasLayer
## HUD en jeu (GDD 6.1) : vies, munitions, alarme, score, minimap.
## Plus l'ecran de fin de mission (reussite / echec).

const MINIMAP_SCRIPT := preload("res://scripts/minimap.gd")
const SCREEN := Vector2(1280, 720)

var _hearts: Array = []
var _sprint: ProgressBar
var _ammo: Label
var _alarm: Label
var _score: Label
var _overlay: Control
var _result_title: Label
var _result_body: Label
var _player: Node
var _pause: Control
var _paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # capter Echap meme en pause
	_build()
	GameState.health_changed.connect(_on_health)
	GameState.score_changed.connect(_on_score)
	GameState.alarm_changed.connect(_on_alarm)
	GameState.mission_ended.connect(_on_mission_ended)
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.ammo_changed.connect(_on_ammo)
		_player.reload_state.connect(_on_reload)
		_player.sprint_changed.connect(_on_sprint)
		_on_ammo(_player.ammo, _player.MAG_SIZE)
	_on_health(GameState.health, GameState.MAX_HEALTH)
	_on_score(GameState.score)
	_on_alarm(GameState.alarm_state)

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- Vies (haut gauche) ---
	for i in range(GameState.MAX_HEALTH):
		var h := ColorRect.new()
		h.size = Vector2(26, 26)
		h.position = Vector2(16 + i * 32, 16)
		h.color = Color(0.85, 0.2, 0.2)
		root.add_child(h)
		_hearts.append(h)

	# --- Barre de sprint (sous les vies) ---
	_sprint = ProgressBar.new()
	_sprint.position = Vector2(16, 50)
	_sprint.size = Vector2(120, 10)
	_sprint.min_value = 0.0
	_sprint.max_value = 1.0
	_sprint.value = 1.0
	_sprint.show_percentage = false
	root.add_child(_sprint)

	# --- Munitions (haut droite) ---
	_ammo = _make_label(root, Vector2(SCREEN.x - 220, 16), Vector2(204, 28), "8 / 8", HORIZONTAL_ALIGNMENT_RIGHT)
	_ammo.add_theme_font_size_override("font_size", 22)

	# --- Score (bas droite) ---
	_score = _make_label(root, Vector2(SCREEN.x - 240, SCREEN.y - 44), Vector2(224, 28), "Score : 0", HORIZONTAL_ALIGNMENT_RIGHT)
	_score.add_theme_font_size_override("font_size", 20)

	# --- Minimap + libelle d'alarme ---
	# Taille reelle de la minimap (cases * CELL=6) pour un placement exact.
	var lvl := get_tree().get_first_node_in_group("level")
	var msz: Vector2i = lvl.map_size() if lvl and lvl.has_method("map_size") else Vector2i(46, 32)
	var mm_size := Vector2(msz.x * 6, msz.y * 6)
	var touch := DisplayServer.is_touchscreen_available()

	var mm := Control.new()
	mm.set_script(MINIMAP_SCRIPT)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ne capte aucun toucher (sticks libres)
	if touch:
		# Tactile : haut-droite, a l'ecart des sticks (pouces en bas) et des boutons E/R.
		mm.position = Vector2(SCREEN.x - 16 - mm_size.x, 52)
		root.add_child(mm)
		# Alarme sous les vies/sprint (haut-gauche), loin du pouce de deplacement.
		_alarm = _make_label(root, Vector2(16, 66), Vector2(260, 28), "CALME", HORIZONTAL_ALIGNMENT_LEFT)
	else:
		# Clavier/souris : bas-gauche (entierement visible, ne deborde plus).
		mm.position = Vector2(16, SCREEN.y - 16 - mm_size.y)
		root.add_child(mm)
		_alarm = _make_label(root, Vector2(16, SCREEN.y - 16 - mm_size.y - 34), Vector2(260, 28), "CALME", HORIZONTAL_ALIGNMENT_LEFT)
	_alarm.add_theme_font_size_override("font_size", 22)

	# --- Overlay de fin (cache) ---
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	_overlay.add_child(dim)
	_result_title = _make_label(_overlay, Vector2(SCREEN.x / 2 - 300, 220), Vector2(600, 50), "", HORIZONTAL_ALIGNMENT_CENTER)
	_result_title.add_theme_font_size_override("font_size", 42)
	_result_body = _make_label(_overlay, Vector2(SCREEN.x / 2 - 300, 290), Vector2(600, 120), "", HORIZONTAL_ALIGNMENT_CENTER)
	_result_body.add_theme_font_size_override("font_size", 20)
	var btn := Button.new()
	btn.text = "Recommencer"
	btn.position = Vector2(SCREEN.x / 2 - 90, 430)
	btn.size = Vector2(180, 44)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(_on_restart)
	_overlay.add_child(btn)
	var btn_q := Button.new()
	btn_q.text = "Quitter"
	btn_q.position = Vector2(SCREEN.x / 2 - 90, 484)
	btn_q.size = Vector2(180, 40)
	btn_q.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_q.pressed.connect(func(): get_tree().quit())
	_overlay.add_child(btn_q)

	_build_pause_menu()

func _build_pause_menu() -> void:
	_pause = Control.new()
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.visible = false
	_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	_pause.add_child(dim)
	var title := _make_label(_pause, Vector2(SCREEN.x / 2 - 300, 180), Vector2(600, 60), "PAUSE", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 48)
	_pause_button("REPRENDRE", 300, _toggle_pause)
	_pause_button("RECOMMENCER", 360, _on_restart)
	_pause_button("MENU PRINCIPAL", 420, _on_main_menu)
	_pause_button("QUITTER", 480, func(): get_tree().quit())

func _pause_button(txt: String, y: float, cb: Callable) -> void:
	var b := Button.new()
	b.text = txt
	b.position = Vector2(SCREEN.x / 2 - 130, y)
	b.size = Vector2(260, 48)
	b.focus_mode = Control.FOCUS_NONE
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	_pause.add_child(b)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not GameState.mission_over:
		_toggle_pause()
		get_viewport().set_input_as_handled()

# Bouton RETOUR Android : met en pause / reprend (n'abandonne jamais la partie).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not GameState.mission_over:
		_toggle_pause()

func _toggle_pause() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	_pause.visible = _paused
	AudioManager.play_sfx("ui_click")

func _on_main_menu() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _make_label(parent: Node, pos: Vector2, sz: Vector2, txt: String, align: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.text = txt
	l.horizontal_alignment = align
	parent.add_child(l)
	return l

# --- Callbacks ---
func _on_health(hp: int, _maxhp: int) -> void:
	for i in range(_hearts.size()):
		_hearts[i].color = Color(0.85, 0.2, 0.2) if i < hp else Color(0.2, 0.2, 0.24)

func _on_ammo(ammo: int, mag: int) -> void:
	_ammo.text = "%d / %d" % [ammo, mag]

func _on_reload(active: bool) -> void:
	if active:
		_ammo.text = "RECHARGEMENT..."

func _on_sprint(ratio: float) -> void:
	_sprint.value = ratio

func _on_score(s: int) -> void:
	_score.text = "Score : %d" % s

func _on_alarm(state: int) -> void:
	match state:
		GameState.Alarm.CALM:
			_alarm.text = "CALME"
			_alarm.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		GameState.Alarm.SUSPICION:
			_alarm.text = "SUSPICION"
			_alarm.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
		GameState.Alarm.ALERT:
			_alarm.text = "! ALERTE !"
			_alarm.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))

func _on_mission_ended(success: bool, reason: String) -> void:
	get_tree().paused = true
	_overlay.visible = true
	if success:
		_result_title.text = "MISSION REUSSIE"
		_result_title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	else:
		_result_title.text = "MISSION ECHOUEE"
		_result_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	var disc := "Discretion totale !" if not GameState.alarm_ever_triggered else "Alarme declenchee"
	_result_body.text = "%s\n\nTemps : %d s\nGardes neutralises : %d\n%s\n\nSCORE FINAL : %d" % [
		reason, int(GameState.mission_time), GameState.guards_neutralized, disc, GameState.final_score()
	]

func _on_restart() -> void:
	get_tree().paused = false
	GameState.reset_campaign()
	get_tree().reload_current_scene()

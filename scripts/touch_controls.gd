extends Control
## Controles tactiles Android (twin-stick) :
##  - Stick gauche (moitie gauche de l'ecran) : deplacement. Pleine course = sprint.
##  - Stick droit (moitie droite) : visee + tir (actif tant qu'on draggue).
##  - Boutons E (interagir) et R (recharger) sur le bord droit.
##
## Activation PARESSEUSE : meme si un ecran tactile est present (ex: PC tactile),
## l'overlay reste invisible et NE TOUCHE PAS aux actions tant que l'utilisateur
## n'a pas pose un doigt. On ne pilote les actions de deplacement QUE pendant
## qu'un stick est tenu -> aucune interference avec le clavier/souris.

const SCREEN := Vector2(1280, 720)
const MAX_RADIUS := 90.0
const DEADZONE := 12.0
const SPRINT_THRESHOLD := 0.82

# Etat des doigts (index de l'evenement tactile, -1 = inactif)
var _move_id := -1
var _move_origin := Vector2.ZERO
var _move_cur := Vector2.ZERO
var _aim_id := -1
var _aim_origin := Vector2.ZERO
var _aim_cur := Vector2.ZERO

# Sorties lues par le joueur
var move_vec := Vector2.ZERO   # composantes -1..1
var aim_vec := Vector2.ZERO    # direction normalisee, ZERO si inactif
var firing := false

var _btn_rects: Array[Rect2] = []
var _buttons: Array[Button] = []
var _active := false       # ecran tactile present
var _engaged := false      # l'utilisateur a touche l'ecran au moins une fois
var _move_owned := false   # on pilote actuellement les actions de deplacement

func _ready() -> void:
	add_to_group("touch_controls")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_active = DisplayServer.is_touchscreen_available()
	if not _active:
		set_process(false)
		set_process_input(false)
		return
	_build_buttons()
	_set_buttons_visible(false)

func _build_buttons() -> void:
	var inter := _make_button("E", Vector2(SCREEN.x - 140, 250), "interact")
	var reload := _make_button("R", Vector2(SCREEN.x - 140, 360), "reload")
	_buttons = [inter, reload]
	_btn_rects = [Rect2(inter.position, inter.size), Rect2(reload.position, reload.size)]

func _make_button(txt: String, pos: Vector2, action: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = Vector2(120, 90)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 34)
	add_child(b)
	b.button_down.connect(func(): Input.action_press(action))
	b.button_up.connect(func(): Input.action_release(action))
	return b

func _set_buttons_visible(v: bool) -> void:
	for b in _buttons:
		b.visible = v

func _in_button(pos: Vector2) -> bool:
	for r in _btn_rects:
		if r.has_point(pos):
			return true
	return false

func _engage() -> void:
	if _engaged:
		return
	_engaged = true
	visible = true
	_set_buttons_visible(true)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var pos: Vector2 = event.position
		if event.pressed:
			_engage()
			if _in_button(pos):
				return
			if pos.x < SCREEN.x * 0.5:
				if _move_id == -1:
					_move_id = event.index
					_move_origin = pos
					_move_cur = pos
			else:
				if _aim_id == -1:
					_aim_id = event.index
					_aim_origin = pos
					_aim_cur = pos
		else:
			if event.index == _move_id:
				_move_id = -1
			elif event.index == _aim_id:
				_aim_id = -1
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == _move_id:
			_move_cur = event.position
		elif event.index == _aim_id:
			_aim_cur = event.position
		queue_redraw()

func _process(_dt: float) -> void:
	if not _engaged:
		return

	# --- Stick de deplacement : on ne pilote les actions QUE doigt pose ---
	if _move_id != -1:
		var off := _move_cur - _move_origin
		var mag: float = min(off.length(), MAX_RADIUS)
		move_vec = Vector2.ZERO if mag < DEADZONE else off.normalized() * (mag / MAX_RADIUS)
		_apply_move_actions()
		_move_owned = true
	else:
		move_vec = Vector2.ZERO
		if _move_owned:
			_release_move_actions()  # relache UNE fois -> laisse le clavier libre
			_move_owned = false

	# --- Stick de visee / tir ---
	if _aim_id != -1:
		var off2 := _aim_cur - _aim_origin
		if off2.length() < DEADZONE:
			aim_vec = Vector2.ZERO
			firing = false
		else:
			aim_vec = off2.normalized()
			firing = true
	else:
		aim_vec = Vector2.ZERO
		firing = false

func _apply_move_actions() -> void:
	_axis("move_left", "move_right", move_vec.x)
	_axis("move_up", "move_down", move_vec.y)
	if move_vec.length() >= SPRINT_THRESHOLD:
		Input.action_press("sprint")
	else:
		Input.action_release("sprint")

func _release_move_actions() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "sprint"]:
		Input.action_release(a)

func _axis(neg: String, pos_a: String, v: float) -> void:
	if v < -0.01:
		Input.action_press(neg, -v)
		Input.action_release(pos_a)
	elif v > 0.01:
		Input.action_press(pos_a, v)
		Input.action_release(neg)
	else:
		Input.action_release(neg)
		Input.action_release(pos_a)

func _draw() -> void:
	if not _engaged:
		return
	if _move_id != -1:
		_draw_stick(_move_origin, _move_cur, Color(0.4, 0.8, 1.0))
	if _aim_id != -1:
		_draw_stick(_aim_origin, _aim_cur, Color(1.0, 0.5, 0.4))

func _draw_stick(origin: Vector2, cur: Vector2, col: Color) -> void:
	draw_circle(origin, MAX_RADIUS, Color(col.r, col.g, col.b, 0.12))
	draw_arc(origin, MAX_RADIUS, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.4), 3.0)
	var off := cur - origin
	if off.length() > MAX_RADIUS:
		off = off.normalized() * MAX_RADIUS
	draw_circle(origin + off, 28.0, Color(col.r, col.g, col.b, 0.5))

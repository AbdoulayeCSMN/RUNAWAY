extends Control
## Minimap coin bas-gauche (GDD 6.1). Revele les zones visitees uniquement.

const CELL := 6.0
const REVEAL_RADIUS := 3  # cases revelees autour du joueur

var _map: Array = []
var _w := 0
var _h := 0
var _visited := {}
var _player: Node2D
var _level: Node2D

func _ready() -> void:
	_level = get_tree().get_first_node_in_group("level")
	if _level:
		_map = _level.get_map()
		var sz: Vector2i = _level.map_size()
		_w = sz.x; _h = sz.y
		custom_minimum_size = Vector2(_w * CELL, _h * CELL)
		size = custom_minimum_size

func _process(_dt: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	var cx := int(_player.global_position.x / 64.0)
	var cy := int(_player.global_position.y / 64.0)
	for dy in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
		for dx in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
			var k := Vector2i(cx + dx, cy + dy)
			if k.x >= 0 and k.y >= 0 and k.x < _w and k.y < _h:
				_visited[k] = true
	queue_redraw()

func _draw() -> void:
	# Fond
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5), true)
	for k in _visited.keys():
		var c: String = _map[k.y][k.x]
		var col := Color(0.3, 0.3, 0.36)  # sol
		match c:
			"#": col = Color(0.6, 0.45, 0.3)   # mur (brique)
			"o": col = Color(0.55, 0.4, 0.25)  # caisse
			"C": col = Color(0.9, 0.75, 0.2)   # coffre
			"X": col = Color(0.2, 0.8, 0.4)    # sortie
		draw_rect(Rect2(k.x * CELL, k.y * CELL, CELL, CELL), col, true)
	# Joueur
	if _player:
		var px := _player.global_position.x / 64.0 * CELL
		var py := _player.global_position.y / 64.0 * CELL
		draw_circle(Vector2(px, py), 3.0, Color(0.3, 0.8, 1.0))

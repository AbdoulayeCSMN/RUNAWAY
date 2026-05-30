extends Node2D
## Generateur de niveau data-driven (campagne monde ouvert).
## Lit LevelCatalog.get_level(GameState.current_level) et construit la scene
## selon le theme : "research" (interieur), "forest" (foret), "city" (ville).
## Legende :  # mur/obstacle  . sol  o couverture  W eau  P joueur  C coffre  X sortie

const TILE := 64

# --- Textures interieur (Niveau 0) ---
const FLOOR_TEX := preload("res://kenney_top-down-shooter/PNG/Tiles/tile_07.png")
const WALL_TEX := preload("res://assets/tiles/wall.png")
const CRATE_TEX := preload("res://assets/tiles/crate.png")

const KT_DESK := preload("res://kenney_top-down-shooter/PNG/Tiles/tile_453.png")
const KT_CHAIR := preload("res://kenney_top-down-shooter/PNG/Tiles/tile_528.png")
const KT_TABLE := preload("res://kenney_top-down-shooter/PNG/Tiles/tile_454.png")
const KT_RECEPTION := preload("res://kenney_top-down-shooter/PNG/Tiles/tile_538.png")
const KT_LOCKER := preload("res://kenney_top-down-shooter/PNG/Tiles/tile_503.png")
const KT_RUG := preload("res://kenney_top-down-shooter/PNG/Tiles/tile_511.png")
const KT_SOFA_O := [
	preload("res://kenney_top-down-shooter/PNG/Tiles/tile_474.png"),
	preload("res://kenney_top-down-shooter/PNG/Tiles/tile_475.png"),
	preload("res://kenney_top-down-shooter/PNG/Tiles/tile_476.png"),
]
const KT_SOFA_G := [
	preload("res://kenney_top-down-shooter/PNG/Tiles/tile_447.png"),
	preload("res://kenney_top-down-shooter/PNG/Tiles/tile_448.png"),
	preload("res://kenney_top-down-shooter/PNG/Tiles/tile_449.png"),
]

const DECO_PLANTS := [
	preload("res://mes_assets/nature/plant_small_leaf.png"),
	preload("res://mes_assets/nature/plant_grass_wild.png"),
	preload("res://mes_assets/nature/plant_flowers_yellow.png"),
	preload("res://mes_assets/nature/bush_round_flowers.png"),
	preload("res://mes_assets/nature/plant_palm_spread.png"),
	preload("res://mes_assets/nature/plant_tropical_large.png"),
]
const DECO_TREES := [
	preload("res://mes_assets/nature/tree_palm_top.png"),
	preload("res://mes_assets/nature/tree_round_dense.png"),
	preload("res://mes_assets/nature/tree_round_light.png"),
]

# --- Textures foret (Niveau 1) ---
const FOREST_TREES := [
	preload("res://mes_assets/nature/tree_round_dense.png"),
	preload("res://mes_assets/nature/tree_round_dark.png"),
	preload("res://mes_assets/nature/tree_round_light.png"),
	preload("res://mes_assets/nature/tree_maple.png"),
	preload("res://mes_assets/nature/tree_olive.png"),
]
const FOREST_BUSHES := [
	preload("res://mes_assets/nature/tree_bush_1.png"),
	preload("res://mes_assets/nature/tree_bush_2.png"),
	preload("res://mes_assets/nature/tree_bush_3.png"),
	preload("res://mes_assets/nature/bush_round_flowers.png"),
]
const FOREST_GROUND := [
	preload("res://mes_assets/nature/plant_grass_wild.png"),
	preload("res://mes_assets/nature/plant_small_leaf.png"),
	preload("res://mes_assets/nature/plant_flowers_yellow.png"),
]

# --- Textures ville (Niveau 2) ---
const CITY_CARS := [
	preload("res://mes_assets/car_bus/car_red.png"),
	preload("res://mes_assets/car_bus/car_sport_blue.png"),
	preload("res://mes_assets/car_bus/car_taxi.png"),
	preload("res://mes_assets/car_bus/car_grey.png"),
	preload("res://mes_assets/car_bus/car_police.png"),
	preload("res://mes_assets/car_bus/car_yellow.png"),
	preload("res://mes_assets/car_bus/car_blue_small.png"),
	preload("res://mes_assets/car_bus/truck_white_long.png"),
]

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const GUARD_SCENE := preload("res://scenes/Guard.tscn")
const COFFRE_SCENE := preload("res://scenes/Coffre.tscn")
const EXIT_SCENE := preload("res://scenes/Exit.tscn")
const MEDKIT_SCENE := preload("res://scenes/Medkit.tscn")
const TERMINAL_SCENE := preload("res://scenes/Terminal.tscn")
const HUD_SCENE := preload("res://scenes/HUD.tscn")
const TOUCH_SCENE := preload("res://scenes/TouchControls.tscn")

var player: Player
var _astar: AStarGrid2D
var _solid_cells := {}            # cases occupees par du mobilier solide
var _level: Dictionary = {}       # definition courante (LevelCatalog)
var _map: Array = []
var _theme := "research"
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("level")
	_debug_level_override()
	_level = LevelCatalog.get_level(GameState.current_level)
	_map = _level["map"]
	_theme = _level["theme"]
	_rng.seed = 1337 + GameState.current_level * 101  # placement deterministe par niveau
	GameState.begin_level()
	AudioManager.restart_music()
	_add_dark_ambiance()
	_build_map()
	_build_astar()
	_spawn_guards()
	_add_lights()
	_add_decorations()
	_apply_furniture_physics()
	_validate_nav()
	add_child(HUD_SCENE.instantiate())
	add_child(TOUCH_SCENE.instantiate())
	_show_level_banner()

# Banniere d'intro : "Niveau X/3 — Nom" + sous-titre, qui s'estompe.
func _show_level_banner() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var box := Control.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)
	var title := Label.new()
	title.text = "NIVEAU %d/%d  -  %s" % [
		GameState.current_level + 1, GameState.LEVEL_COUNT, _level.get("name", "")
	]
	title.position = Vector2(0, 180)
	title.size = Vector2(1280, 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	box.add_child(title)
	var sub := Label.new()
	sub.text = str(_level.get("subtitle", ""))
	sub.position = Vector2(0, 244)
	sub.size = Vector2(1280, 36)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	box.add_child(sub)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(box, "modulate:a", 0.0, 1.0)
	tw.tween_callback(layer.queue_free)

func get_map() -> Array:
	return _map

func map_size() -> Vector2i:
	return Vector2i((_map[0] as String).length(), _map.size())

func needs_objective() -> bool:
	return bool(_level.get("needs_objective", true))

# Debug : permet de forcer le niveau via --level=N (validation headless).
func _debug_level_override() -> void:
	for a in OS.get_cmdline_user_args():
		if (a as String).begins_with("--level="):
			GameState.current_level = clampi(int((a as String).substr(8)), 0, GameState.LEVEL_COUNT - 1)

func cell_center(col: int, row: int) -> Vector2:
	return Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)

func _add_dark_ambiance() -> void:
	var cm := CanvasModulate.new()
	cm.color = _level.get("ambiance", Color(0.34, 0.34, 0.42))
	add_child(cm)

# ===========================================================================
# CONSTRUCTION DE LA CARTE
# ===========================================================================
func _build_map() -> void:
	var floors := Node2D.new(); floors.name = "Floors"; floors.z_index = -20; add_child(floors)
	var walls := Node2D.new(); walls.name = "Walls"; add_child(walls)
	var props := Node2D.new(); props.name = "Props"; add_child(props)

	var sz := map_size()
	# Sol : interieur = dalles texturees ; exterieur = fond uni colore.
	if _theme == "research":
		pass  # dalles placees case par case ci-dessous
	else:
		var bg := ColorRect.new()
		bg.position = Vector2.ZERO
		bg.size = Vector2(sz.x * TILE, sz.y * TILE)
		bg.color = _ground_color()
		floors.add_child(bg)

	for row in range(_map.size()):
		var line: String = _map[row]
		for col in range(line.length()):
			var c := line[col]
			var pos := cell_center(col, row)
			match c:
				"#":
					_make_wall(walls, pos)
				"o":
					_make_floor(floors, pos)
					_make_cover(walls, pos)
				"W":
					_make_water(walls, pos)
				".":
					_make_floor(floors, pos)
				"P":
					_make_floor(floors, pos)
					_spawn_player(pos)
				"C":
					_make_floor(floors, pos)
					var cof := COFFRE_SCENE.instantiate()
					cof.position = pos
					props.add_child(cof)
				"X":
					_make_floor(floors, pos)

	_place_exit(props)
	for cell in _level.get("medkits", []):
		var m := MEDKIT_SCENE.instantiate()
		m.position = cell_center(cell.x, cell.y)
		props.add_child(m)
	for cell in _level.get("terminals", []):
		var t := TERMINAL_SCENE.instantiate()
		t.position = cell_center(cell.x, cell.y)
		props.add_child(t)

func _ground_color() -> Color:
	match _theme:
		"forest": return Color(0.16, 0.27, 0.15)
		"city": return Color(0.11, 0.12, 0.14)
	return Color(0.17, 0.18, 0.22)

# Sol case par case (interieur uniquement ; l'exterieur a un fond uni).
func _make_floor(parent: Node, pos: Vector2) -> void:
	if _theme != "research":
		return
	var s := Sprite2D.new()
	s.texture = FLOOR_TEX
	s.position = pos
	parent.add_child(s)

# Mur plein selon le theme (brique / arbre / immeuble). Collision layer 1.
func _make_wall(parent: Node, pos: Vector2) -> void:
	var body := _solid_body(pos)
	match _theme:
		"forest":
			_visual_tree(body)
		"city":
			_visual_building(body)
		_:
			var spr := Sprite2D.new(); spr.texture = WALL_TEX; body.add_child(spr)
	parent.add_child(body)

# Couverture basse selon le theme (caisse / rocher-buisson / voiture).
func _make_cover(parent: Node, pos: Vector2) -> void:
	var body := _solid_body(pos)
	match _theme:
		"forest":
			_visual_bush_or_rock(body)
		"city":
			_visual_car(body)
		_:
			var spr := Sprite2D.new(); spr.texture = CRATE_TEX; body.add_child(spr)
	parent.add_child(body)

# Eau : infranchissable (bloque mouvement ET vision), visuel bleu.
func _make_water(parent: Node, pos: Vector2) -> void:
	var body := _solid_body(pos)
	var col := Color(0.14, 0.33, 0.48) if _theme == "forest" else Color(0.12, 0.26, 0.40)
	var base := Polygon2D.new()
	base.polygon = _square(TILE / 2.0)
	base.color = col
	base.z_index = -5
	body.add_child(base)
	var ripple := Polygon2D.new()
	ripple.polygon = PackedVector2Array([
		Vector2(-22, -6 + _rng.randf_range(-4, 4)), Vector2(22, -6),
		Vector2(22, -2), Vector2(-22, -2)])
	ripple.color = Color(col.r + 0.12, col.g + 0.14, col.b + 0.16, 0.5)
	ripple.z_index = -5
	body.add_child(ripple)
	parent.add_child(body)

# StaticBody2D plein-case sur la couche "world" (bloque mouvement + vision).
func _solid_body(pos: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	body.add_to_group("walls")
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	col.shape = rect
	body.add_child(col)
	return body

func _square(h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])

# --- Visuels exterieurs ---
func _visual_tree(body: Node) -> void:
	# Base ombre + feuillage + parfois un vrai sprite d'arbre.
	var shadow := Polygon2D.new()
	shadow.polygon = _square(TILE / 2.0)
	shadow.color = Color(0.07, 0.12, 0.07)
	body.add_child(shadow)
	if _rng.randf() < 0.55:
		var t := Sprite2D.new()
		t.texture = FOREST_TREES[_rng.randi() % FOREST_TREES.size()]
		t.scale = Vector2.ONE * (TILE * 1.35 / 256.0)
		t.rotation = _rng.randf_range(0, TAU)
		t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		body.add_child(t)
	else:
		var foliage := Polygon2D.new()
		var pts := PackedVector2Array()
		var rad := TILE * 0.52
		for i in range(12):
			var a := TAU * i / 12.0
			pts.append(Vector2(cos(a), sin(a)) * rad * _rng.randf_range(0.85, 1.05))
		foliage.polygon = pts
		foliage.color = Color(0.13, 0.30, 0.15)
		body.add_child(foliage)

func _visual_bush_or_rock(body: Node) -> void:
	if _rng.randf() < 0.5:
		var b := Sprite2D.new()
		b.texture = FOREST_BUSHES[_rng.randi() % FOREST_BUSHES.size()]
		b.scale = Vector2.ONE * (TILE * 0.9 / 256.0)
		b.rotation = _rng.randf_range(0, TAU)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		body.add_child(b)
	else:
		var rock := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in range(7):
			var a := TAU * i / 7.0
			pts.append(Vector2(cos(a), sin(a)) * TILE * 0.42 * _rng.randf_range(0.8, 1.1))
		rock.polygon = pts
		rock.color = Color(0.42, 0.40, 0.36)
		body.add_child(rock)
		var hi := Polygon2D.new()
		hi.polygon = PackedVector2Array([Vector2(-10, -10), Vector2(6, -12), Vector2(2, -4), Vector2(-12, -2)])
		hi.color = Color(0.55, 0.53, 0.49)
		body.add_child(hi)

func _visual_building(body: Node) -> void:
	var base := Polygon2D.new()
	base.polygon = _square(TILE / 2.0)
	base.color = Color(0.20, 0.21, 0.25).lerp(Color(0.28, 0.29, 0.34), _rng.randf())
	body.add_child(base)
	# Toit legerement plus clair (effet de relief vu de dessus).
	var roof := Polygon2D.new()
	roof.polygon = _square(TILE * 0.42)
	roof.color = Color(base.color.r + 0.06, base.color.g + 0.06, base.color.b + 0.07)
	body.add_child(roof)
	# Fenetres : petits carres faiblement lumineux.
	for dx in [-1, 1]:
		for dy in [-1, 1]:
			if _rng.randf() < 0.7:
				var w := Polygon2D.new()
				w.polygon = PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)])
				w.position = Vector2(dx * 15, dy * 15)
				var lit := _rng.randf() < 0.5
				w.color = Color(0.85, 0.8, 0.45) if lit else Color(0.10, 0.12, 0.16)
				body.add_child(w)

func _visual_car(body: Node) -> void:
	var s := Sprite2D.new()
	s.texture = CITY_CARS[_rng.randi() % CITY_CARS.size()]
	var dim: float = maxf(s.texture.get_width(), s.texture.get_height())
	s.scale = Vector2.ONE * (TILE * 0.92 / dim)
	s.rotation = PI / 2.0 if _rng.randf() < 0.5 else -PI / 2.0  # alignees a la rue
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	body.add_child(s)

# ===========================================================================
# SORTIE (zone d'exfiltration) — placement generique sur les cases 'X'
# ===========================================================================
func _place_exit(parent: Node) -> void:
	var xs := _find_all_cells("X")
	if xs.is_empty():
		return
	var minc := 999; var maxc := -1; var minr := 999; var maxr := -1
	for cell in xs:
		minc = mini(minc, cell.x); maxc = maxi(maxc, cell.x)
		minr = mini(minr, cell.y); maxr = maxi(maxr, cell.y)
	var wc := maxc - minc + 1
	var hc := maxr - minr + 1
	var ex := EXIT_SCENE.instantiate()
	ex.position = Vector2(minc * TILE, minr * TILE) + Vector2(wc * TILE / 2.0, hc * TILE / 2.0)
	# La scene Exit n'embarque pas de forme : on l'ajoute dimensionnee a la zone.
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(wc * TILE, hc * TILE)
	col.shape = rect
	ex.add_child(col)
	# Marqueur visuel ajuste a la largeur.
	var marker := ex.get_node_or_null("Marker")
	if marker:
		marker.scale = Vector2(wc / 2.0, float(hc))
	parent.add_child(ex)
	# Repere d'exfil specifique (helipad en ville).
	if _theme == "city":
		_make_helipad(parent, ex.position)

func _make_helipad(parent: Node, pos: Vector2) -> void:
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 56.0)
	ring.polygon = pts
	ring.color = Color(0.9, 0.8, 0.2, 0.18)
	ring.position = pos
	ring.z_index = -1
	parent.add_child(ring)
	var h := Label.new()
	h.text = "H"
	h.position = pos + Vector2(-16, -28)
	h.add_theme_font_size_override("font_size", 48)
	h.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	parent.add_child(h)

# ===========================================================================
# NAVIGATION (AStar) + collisions du mobilier
# ===========================================================================
func _build_astar() -> void:
	_astar = AStarGrid2D.new()
	var sz := map_size()
	_astar.region = Rect2i(0, 0, sz.x, sz.y)
	_astar.cell_size = Vector2(TILE, TILE)
	_astar.offset = Vector2(TILE / 2.0, TILE / 2.0)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for row in range(_map.size()):
		var line: String = _map[row]
		for col in range(line.length()):
			var c := line[col]
			if c == "#" or c == "o" or c == "W":
				_astar.set_point_solid(Vector2i(col, row), true)

func _apply_furniture_physics() -> void:
	var bodies := Node2D.new(); bodies.name = "FurnitureColliders"; add_child(bodies)
	for cell in _solid_cells:
		if _astar.is_point_solid(cell):
			continue
		_make_furniture_collider(bodies, cell)
		_astar.set_point_solid(cell, true)

func _make_furniture_collider(parent: Node, cell: Vector2i) -> void:
	var body := _solid_body(cell_center(cell.x, cell.y))
	parent.add_child(body)

func _cell_of(world: Vector2) -> Vector2i:
	var sz := map_size()
	var col := clampi(int(world.x / TILE), 0, sz.x - 1)
	var row := clampi(int(world.y / TILE), 0, sz.y - 1)
	return Vector2i(col, row)

func find_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	if _astar == null:
		return PackedVector2Array()
	var from_id := _cell_of(from_world)
	var to_id := _cell_of(to_world)
	if _astar.is_point_solid(to_id):
		to_id = _nearest_free(to_id)
	if _astar.is_point_solid(from_id):
		from_id = _nearest_free(from_id)
	return _astar.get_point_path(from_id, to_id)

func _nearest_free(id: Vector2i) -> Vector2i:
	var sz := map_size()
	for radius in range(1, 8):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var n := Vector2i(id.x + dx, id.y + dy)
				if n.x >= 0 and n.y >= 0 and n.x < sz.x and n.y < sz.y:
					if not _astar.is_point_solid(n):
						return n
	return id

# ===========================================================================
# VALIDATION DE NAVIGATION (avertissements en cas de blocage)
# ===========================================================================
func _validate_nav() -> void:
	var start := _find_char_cell("P")
	if start == Vector2i(-1, -1):
		push_warning("[nav] joueur 'P' introuvable dans la carte")
		return
	var reached := _flood_fill(start)
	var targets := {}
	var coffre := _find_char_cell("C")
	if coffre != Vector2i(-1, -1):
		targets[coffre] = "coffre"
	for c in _find_all_cells("X"):
		targets[c] = "sortie"
	for c in _level.get("medkits", []):
		targets[c] = "medkit"
	for c in _level.get("terminals", []):
		targets[c] = "terminal"
	for d in _level.get("guards", []):
		targets[d["cell"]] = "garde-spawn"
		for p in d["patrol"]:
			targets[p] = "garde-patrouille"
	for cell in targets:
		if _astar.is_point_solid(cell):
			push_warning("[nav] case solide: %s (%s)" % [str(cell), targets[cell]])
		elif not reached.has(cell):
			push_warning("[nav] inatteignable depuis le joueur: %s (%s)" % [str(cell), targets[cell]])

func _flood_fill(start: Vector2i) -> Dictionary:
	var seen := {}
	if _astar.is_point_solid(start):
		return seen
	var sz := map_size()
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = cur + d
			if n.x < 0 or n.y < 0 or n.x >= sz.x or n.y >= sz.y:
				continue
			if seen.has(n) or _astar.is_point_solid(n):
				continue
			seen[n] = true
			queue.append(n)
	return seen

func _find_char_cell(ch: String) -> Vector2i:
	for row in range(_map.size()):
		var c: int = (_map[row] as String).find(ch)
		if c != -1:
			return Vector2i(c, row)
	return Vector2i(-1, -1)

func _find_all_cells(ch: String) -> Array:
	var out := []
	for row in range(_map.size()):
		var line: String = _map[row]
		for col in range(line.length()):
			if line[col] == ch:
				out.append(Vector2i(col, row))
	return out

# ===========================================================================
# ACTEURS
# ===========================================================================
func _spawn_player(pos: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = pos
	add_child(player)

func _spawn_guards() -> void:
	var container := Node2D.new(); container.name = "Guards"; add_child(container)
	for data in _level.get("guards", []):
		var g := GUARD_SCENE.instantiate() as Guard
		g.guard_type = data["type"]
		var spawn := _free_cell(data["cell"])
		g.position = cell_center(spawn.x, spawn.y)
		var pts: Array[Vector2] = []
		for cell in data["patrol"]:
			var fc := _free_cell(cell)
			pts.append(cell_center(fc.x, fc.y))
		g.patrol_points = pts
		container.add_child(g)

# Ramene une case sur la case libre la plus proche (robustesse des defs).
func _free_cell(cell: Vector2i) -> Vector2i:
	if _astar != null and _astar.is_point_solid(cell):
		return _nearest_free(cell)
	return cell

# ===========================================================================
# LUMIERES
# ===========================================================================
func _make_light_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex

func _add_lights() -> void:
	var tex := _make_light_texture()
	var lights := Node2D.new(); lights.name = "Lights"; add_child(lights)
	for d in _lamp_defs():
		var l := PointLight2D.new()
		l.texture = tex
		l.position = cell_center(d[0], d[1])
		l.color = d[2]
		l.energy = d[3]
		l.texture_scale = d[4]
		l.blend_mode = Light2D.BLEND_MODE_ADD
		lights.add_child(l)
		var fix := Polygon2D.new()
		fix.polygon = PackedVector2Array([Vector2(-7, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-7, 7)])
		fix.color = Color(d[2].r, d[2].g, d[2].b, 0.9)
		fix.position = l.position
		lights.add_child(fix)

func _lamp_defs() -> Array:
	match _theme:
		"forest":
			return [
				[17, 1, Color(0.9, 0.95, 0.7), 1.2, 2.0],    # exfil
				[21, 15, Color(0.7, 0.85, 1.0), 1.0, 2.2],   # pont (clair de lune)
				[6, 8, Color(0.7, 0.8, 1.0), 0.8, 2.4],
				[38, 8, Color(0.7, 0.8, 1.0), 0.8, 2.4],
				[6, 24, Color(0.7, 0.8, 1.0), 0.8, 2.4],
				[38, 24, Color(0.7, 0.8, 1.0), 0.8, 2.4],
				[20, 29, Color(0.8, 0.85, 1.0), 0.8, 2.2],
			]
		"city":
			var arr := [
				[15, 1, Color(1.0, 0.85, 0.3), 1.4, 2.2],   # helipad
				[15, 5, Color(0.8, 0.9, 1.0), 0.9, 2.0],    # bord du fleuve
			]
			# Lampadaires aux carrefours.
			for r in [10, 16, 20, 25, 29]:
				for c in [6, 22, 40]:
					arr.append([c, r, Color(0.95, 0.85, 0.55), 0.85, 1.8])
			return arr
		_:
			return [
				[7, 2, Color(1.0, 0.95, 0.8), 1.1, 1.7],
				[38, 2, Color(1.0, 0.95, 0.8), 1.1, 1.7],
				[7, 11, Color(0.85, 0.9, 1.0), 1.0, 1.9],
				[22, 11, Color(1.0, 0.85, 0.45), 1.4, 2.1],
				[38, 11, Color(0.85, 0.9, 1.0), 1.0, 1.9],
				[12, 21, Color(0.8, 0.85, 1.0), 1.0, 2.0],
				[34, 21, Color(0.8, 0.85, 1.0), 1.0, 2.0],
				[12, 28, Color(0.9, 0.9, 0.95), 1.0, 1.9],
				[34, 28, Color(0.9, 0.9, 0.95), 1.0, 1.9],
			]

# ===========================================================================
# DECORATIONS (par theme)
# ===========================================================================
func _add_decorations() -> void:
	match _theme:
		"forest": _decorate_forest()
		"city": _decorate_city()
		_: _decorate_research()

# --- Sol vegetal disperse sur les clairieres (foret) ---
func _decorate_forest() -> void:
	var deco := Node2D.new(); deco.name = "Deco"; deco.z_index = -12; add_child(deco)
	for row in range(_map.size()):
		var line: String = _map[row]
		for col in range(line.length()):
			if line[col] == "." and _rng.randf() < 0.10:
				var s := Sprite2D.new()
				s.texture = FOREST_GROUND[_rng.randi() % FOREST_GROUND.size()]
				s.position = cell_center(col, row) + Vector2(_rng.randf_range(-16, 16), _rng.randf_range(-16, 16))
				s.scale = Vector2.ONE * (_rng.randf_range(30, 46) / 256.0)
				s.rotation = _rng.randf_range(0, TAU)
				s.modulate = Color(0.9, 1.0, 0.9, 0.85)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				deco.add_child(s)

# --- Marquages au sol des avenues (ville) ---
func _decorate_city() -> void:
	var deco := Node2D.new(); deco.name = "Deco"; deco.z_index = -13; add_child(deco)
	var sz := map_size()
	# Lignes centrales jaunes sur les longues bandes de sol horizontales.
	for row in range(_map.size()):
		var line: String = _map[row]
		var run_start := -1
		for col in range(line.length() + 1):
			var open: bool = col < line.length() and (line[col] == "." or line[col] == "o")
			if open and run_start == -1:
				run_start = col
			elif not open and run_start != -1:
				if col - run_start >= 6:
					_road_dashes(deco, run_start, col - 1, row)
				run_start = -1

func _road_dashes(parent: Node, c0: int, c1: int, row: int) -> void:
	var y := row * TILE + TILE / 2.0
	var x := c0 * TILE + TILE
	while x < c1 * TILE:
		var dash := Polygon2D.new()
		dash.polygon = PackedVector2Array([Vector2(-12, -2), Vector2(12, -2), Vector2(12, 2), Vector2(-12, 2)])
		dash.color = Color(0.75, 0.68, 0.25, 0.55)
		dash.position = Vector2(x, y)
		parent.add_child(dash)
		x += TILE * 1.6

# --- Amenagement interieur "Centre de recherche" (Niveau 0) ---
func _decorate_research() -> void:
	var rugs := Node2D.new(); rugs.name = "Rugs"; rugs.z_index = -11; add_child(rugs)
	var deco := Node2D.new(); deco.name = "Deco"; deco.z_index = -10; add_child(deco)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	_kt_rect(rugs, KT_RUG, 20, 9, 4, 4)
	for cell in [Vector2i(16, 8), Vector2i(28, 8), Vector2i(16, 15), Vector2i(28, 15)]:
		_make_server(deco, cell.x, cell.y)
	for cell in [Vector2i(19, 9), Vector2i(25, 9), Vector2i(19, 14), Vector2i(25, 14)]:
		_make_laser(deco, cell.x, cell.y)

	for cell in [Vector2i(3, 7), Vector2i(6, 7), Vector2i(9, 7),
			Vector2i(3, 11), Vector2i(6, 11), Vector2i(9, 11)]:
		_make_workstation(deco, cell.x, cell.y)
	for r in [14, 15, 16]:
		_kt(deco, KT_LOCKER, 2, r, 0.0, true)

	for c in [33, 35, 37, 39]:
		_make_server(deco, c, 7)
		_make_server(deco, c, 13)
	_make_workstation(deco, 41, 15)

	for c in range(9, 17):
		_kt(deco, KT_TABLE, c, 20, 0.0, true)
	for c in [9, 11, 13, 15]:
		_kt(deco, KT_CHAIR, c, 19, PI, true)
		_kt(deco, KT_CHAIR, c, 21, 0.0, true)
	_kt_rect(rugs, KT_RUG, 30, 19, 3, 3)

	_kt_rect(rugs, KT_RUG, 17, 25, 10, 2)
	for c in range(18, 26):
		_kt(deco, KT_RECEPTION, c, 25, 0.0, true)
	_make_sofa(deco, KT_SOFA_O, 3, 29)
	_make_sofa(deco, KT_SOFA_G, 39, 29)

	_make_workstation(deco, 33, 2)
	_make_workstation(deco, 36, 2)
	for r in [1, 2, 3]:
		_kt(deco, KT_LOCKER, 43, r, 0.0, true)

	for cell in [Vector2i(2, 6), Vector2i(13, 6), Vector2i(31, 6), Vector2i(42, 6),
			Vector2i(2, 30), Vector2i(43, 30), Vector2i(13, 11), Vector2i(31, 11)]:
		_make_plant(deco, cell_center(cell.x, cell.y), rng)
	for cell in [Vector2i(2, 26), Vector2i(43, 26), Vector2i(2, 22), Vector2i(43, 22)]:
		_make_tree(deco, cell_center(cell.x, cell.y), rng)

# --- Helpers mobilier interieur ---
func _mark_solid(col: int, row: int) -> void:
	_solid_cells[Vector2i(col, row)] = true

func _kt(parent: Node, tex: Texture2D, col: int, row: int, rot: float = 0.0, solid: bool = false) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = cell_center(col, row)
	s.rotation = rot
	parent.add_child(s)
	if solid:
		_mark_solid(col, row)

func _kt_rect(parent: Node, tex: Texture2D, col: int, row: int, wc: int, hc: int) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(wc, hc)
	s.position = Vector2(col * TILE + wc * TILE / 2.0, row * TILE + hc * TILE / 2.0)
	parent.add_child(s)

func _make_workstation(parent: Node, col: int, row: int) -> void:
	_kt(parent, KT_DESK, col, row, 0.0, true)
	_make_screen(parent, col, row)
	_kt(parent, KT_CHAIR, col, row + 1, 0.0, true)

func _make_screen(parent: Node, col: int, row: int) -> void:
	var pos := cell_center(col, row) + Vector2(0, -6)
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2(-12, -8), Vector2(12, -8), Vector2(12, 8), Vector2(-12, 8)])
	frame.color = Color(0.08, 0.09, 0.11)
	frame.position = pos
	parent.add_child(frame)
	var glass := Polygon2D.new()
	glass.polygon = PackedVector2Array([Vector2(-9, -5), Vector2(9, -5), Vector2(9, 5), Vector2(-9, 5)])
	glass.color = Color(0.25, 0.85, 1.0)
	glass.position = pos
	parent.add_child(glass)

func _make_server(parent: Node, col: int, row: int) -> void:
	_mark_solid(col, row)
	_mark_solid(col, row + 1)
	var n := Node2D.new()
	n.position = Vector2(col * TILE + TILE / 2.0, row * TILE + TILE)
	var w := TILE * 0.7
	var h := TILE * 1.8
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-w/2, -h/2), Vector2(w/2, -h/2), Vector2(w/2, h/2), Vector2(-w/2, h/2)])
	body.color = Color(0.09, 0.10, 0.13)
	n.add_child(body)
	for i in range(7):
		var led := Polygon2D.new()
		var ly := -h/2 + 7 + i * ((h - 14) / 6.0)
		led.polygon = PackedVector2Array([Vector2(-w/2+6, ly), Vector2(w/2-6, ly), Vector2(w/2-6, ly+3), Vector2(-w/2+6, ly+3)])
		led.color = Color(0.2, 0.8, 1.0) if i % 3 != 0 else Color(0.3, 1.0, 0.6)
		n.add_child(led)
	parent.add_child(n)

func _make_laser(parent: Node, col: int, row: int) -> void:
	var dot := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(10):
		var a := TAU * i / 10.0
		pts.append(Vector2(cos(a), sin(a)) * 7.0)
	dot.polygon = pts
	dot.color = Color(0.9, 0.2, 0.25)
	dot.position = cell_center(col, row)
	parent.add_child(dot)

func _make_sofa(parent: Node, pieces: Array, col: int, row: int) -> void:
	for i in range(pieces.size()):
		_kt(parent, pieces[i], col + i, row, 0.0, true)

func _make_plant(parent: Node, pos: Vector2, rng: RandomNumberGenerator) -> void:
	_make_sprite_deco(parent, pos, DECO_PLANTS[rng.randi() % DECO_PLANTS.size()],
		rng.randf_range(46.0, 62.0), rng.randf_range(0.0, TAU))

func _make_tree(parent: Node, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var cell := _cell_of(pos)
	_mark_solid(cell.x, cell.y)
	_make_sprite_deco(parent, pos, DECO_TREES[rng.randi() % DECO_TREES.size()],
		rng.randf_range(78.0, 96.0), rng.randf_range(0.0, TAU))

func _make_sprite_deco(parent: Node, pos: Vector2, tex: Texture2D, target_px: float, rot: float) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.rotation = rot
	s.scale = Vector2.ONE * (target_px / 256.0)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(s)

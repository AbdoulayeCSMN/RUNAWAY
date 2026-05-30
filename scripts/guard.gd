extends CharacterBody2D
class_name Guard
## Garde ennemi. Machine a etats (GDD 4.2) :
## PATROUILLE -> SUSPICION -> COMBAT -> RECHERCHE.
## Vision conique 90 deg avec raycast (GDD 4.3). Detection du bruit en sprint.
## Pas de spawn de renforts : en alerte, les gardes convergent vers le joueur.

enum Type { BASIC, ALERT, ARMED }
enum State { PATROL, SUSPICION, COMBAT, SEARCH }

# Textures par type (sprites Kenney)
const TEX := {
	Type.BASIC: preload("res://assets/characters/guard_basic.png"),
	Type.ALERT: preload("res://assets/characters/guard_alert.png"),
	Type.ARMED: preload("res://assets/characters/guard_armed.png"),
}

# --- Reglages (GDD 4.1 / 4.3) ---
const VISION_ANGLE := 45.0          # demi-angle -> cone total de 90 deg
const RANGE_CALM := 180.0
const RANGE_ALERT := 260.0
const NOISE_HEARING := 120.0
const PATROL_SPEED := 80.0
const CHASE_SPEED := 120.0
const CONFIRM_TIME := 0.55          # vu en continu -> alerte confirmee
const SEARCH_TIME := 6.0            # duree de recherche avant retour patrouille
const TURN_SPEED := 6.0
const FIRE_COOLDOWN := 0.9

@export var guard_type: Type = Type.BASIC
@export var patrol_points: Array[Vector2] = []
@export var bullet_scene: PackedScene

var state: int = State.PATROL
var hp := 2
var can_shoot := false
var _player: Node2D
var _patrol_idx := 0
var _last_seen := Vector2.ZERO
var _seen_timer := 0.0
var _search_timer := 0.0
var _fire_t := 0.0
var _wait_t := 0.0

# --- Pathfinding (AStarGrid2D du niveau) ---
const TILE := 64.0
const REPATH_DIST := 28.0       # recalculer le chemin si la cible bouge de +
const WAYPOINT_REACH := 12.0
var _level: Node
var _path: PackedVector2Array = PackedVector2Array()
var _path_idx := 0
var _path_target := Vector2.INF

# --- Alerte locale + fouille ---
const ALERT_RADIUS := 420.0     # propagation d'alerte aux gardes proches (~6 cases)
const SEARCH_RADIUS := 120.0    # rayon de fouille autour de l'ancre de recherche
const SEARCH_SPREAD := 150.0    # eloignement de l'ancre par garde (dispersion)
const SEARCH_LEAD := 0.55       # anticipation de la fuite (pos + vitesse*lead)
var _search_target := Vector2.INF
var _search_anchor := Vector2.INF   # centre de fouille propre a CE garde
var _rng := RandomNumberGenerator.new()

# --- Perception fine + tactique de combat ---
const PROXIMITY_SENSE := 48.0   # repere un intrus colle, meme hors du cone
const PREFERRED_RANGE := 190.0  # distance de tir ideale (garde arme)
const RANGE_HYSTERESIS := 45.0  # zone morte autour de la distance ideale
const BASIC_KEEP_DIST := 240.0  # garde non arme : reste loin et appelle a l'aide
const STRAFE_PERIOD := 1.2
const BULLET_SPEED := 700.0      # doit suivre Bullet.speed (visee anticipee)
const ALLY_LANE_WIDTH := 26.0    # demi-largeur du couloir de tir (anti tir ami)
const GUNFIRE_ALERT_RADIUS := 520.0  # le bruit d'un tir alerte les gardes proches
const FLANK_REACH := 42.0        # tolerance d'arrivee sur le poste d'encerclement
var _last_seen_vel := Vector2.ZERO  # vitesse du joueur au dernier contact (prediction)
var _strafe_dir := 1.0
var _strafe_t := 0.0
var _backup_call_t := 0.0
var _flank_bearing := 0.0        # secteur d'encerclement propre a CE garde (stable)

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var cone: Polygon2D = $VisionCone

func _ready() -> void:
	add_to_group("guards")
	sprite.texture = TEX[guard_type]
	match guard_type:
		Type.BASIC:
			hp = 2; can_shoot = false
		Type.ALERT:
			hp = 2; can_shoot = true
		Type.ARMED:
			hp = 3; can_shoot = true
	_player = get_tree().get_first_node_in_group("player")
	if patrol_points.is_empty():
		patrol_points = [global_position]
	_rng.randomize()  # fouille dispersee (chaque garde son propre bruit)
	# Secteur d'encerclement unique et stable (suite de Weyl sur l'id) :
	# les gardes armes se repartissent autour du joueur au lieu de s'agglutiner.
	_flank_bearing = fmod(float(get_instance_id()) * 0.61803398875, 1.0) * TAU
	_rebuild_cone(RANGE_CALM)

func _physics_process(delta: float) -> void:
	if GameState.mission_over:
		velocity = Vector2.ZERO
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	if _fire_t > 0.0:
		_fire_t -= delta

	var sees := _can_see_player()
	var hears := _can_hear_player()
	if sees:
		_last_seen = _player.global_position
		_last_seen_vel = _player.velocity  # memorise la fuite pour anticiper
		GameState.report_player_pos(_last_seen)

	match state:
		State.PATROL:   _do_patrol(delta, sees, hears)
		State.SUSPICION: _do_suspicion(delta, sees, hears)
		State.COMBAT:   _do_combat(delta, sees)
		State.SEARCH:   _do_search(delta, sees, hears)

	_update_cone_color()
	move_and_slide()

# ============================================================
#  ETATS
# ============================================================
func _do_patrol(delta: float, sees: bool, hears: bool) -> void:
	# Pas de convergence globale : un garde en patrouille ne reagit qu'a ce
	# qu'il voit/entend, ou a une alerte transmise par un garde proche (_alert_nearby).
	if sees:
		_enter_suspicion()
		return
	if hears:
		_last_seen = _player.global_position
		_enter_suspicion()
		return
	# Avance vers le point de patrouille courant
	var target: Vector2 = patrol_points[_patrol_idx]
	if global_position.distance_to(target) < 12.0:
		_wait_t -= delta
		velocity = Vector2.ZERO
		if _wait_t <= 0.0:
			_patrol_idx = (_patrol_idx + 1) % patrol_points.size()
			_wait_t = 0.6
	else:
		_move_toward(target, PATROL_SPEED, delta)

func _do_suspicion(delta: float, sees: bool, _hears: bool) -> void:
	GameState.raise_suspicion()
	if sees:
		# Confirmation plus rapide de pres, plus lente de loin (perception realiste).
		var dist := global_position.distance_to(_player.global_position)
		var factor := clampf(RANGE_ALERT / maxf(dist, 1.0), 0.55, 2.2)
		_seen_timer += delta * factor
		_face(_player.global_position, delta)
		# Confirme -> combat (garde arme/alerte) ou alerte directe
		if _seen_timer >= CONFIRM_TIME:
			_enter_combat()
			return
		# se rapproche pour verifier
		_move_toward(_player.global_position, PATROL_SPEED, delta)
	else:
		_seen_timer = max(0.0, _seen_timer - delta * 0.5)
		# va au dernier point vu, puis regarde autour
		if global_position.distance_to(_last_seen) > 12.0:
			_move_toward(_last_seen, PATROL_SPEED, delta)
		else:
			velocity = Vector2.ZERO
			rotation += delta * 1.5  # balaye du regard
			_search_timer += delta
			if _search_timer >= 2.5:
				_enter_patrol()

func _do_combat(delta: float, sees: bool) -> void:
	GameState.notify_combat()  # maintient l'alerte tant que le combat dure
	if not sees:
		_enter_search()
		return
	_last_seen = _player.global_position
	_last_seen_vel = _player.velocity
	_face(_player.global_position, delta)
	var to_p := _player.global_position - global_position
	var dist := to_p.length()

	if not can_shoot:
		# Garde non arme : appelle des renforts et se replie VERS un allie (regroupe).
		_backup_call_t -= delta
		if _backup_call_t <= 0.0:
			_alert_nearby(_player.global_position)
			_backup_call_t = 1.2
		if dist < BASIC_KEEP_DIST:
			var away := (-to_p).normalized()
			var ally := _nearest_ally()
			if ally != null:  # se replie en biais vers le soutien le plus proche
				away = (away + (ally.global_position - global_position).normalized()).normalized()
			velocity = away * CHASE_SPEED
		else:
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
		return

	# Garde arme : ENCERCLE le joueur (secteur propre) a distance de tir + esquive.
	_strafe_t -= delta
	if _strafe_t <= 0.0:
		_strafe_dir = -_strafe_dir
		_strafe_t = STRAFE_PERIOD * (0.7 + _rng.randf() * 0.6)
	# Poste vise : un point a PREFERRED_RANGE du joueur, sur le secteur du garde.
	var bearing := _flank_bearing + _strafe_dir * 0.22
	var post := _player.global_position + Vector2(cos(bearing), sin(bearing)) * PREFERRED_RANGE
	if global_position.distance_to(post) > FLANK_REACH:
		_move_toward(post, CHASE_SPEED, delta)   # rejoint son poste (contourne les murs)
		_face(_player.global_position, delta)     # mais garde l'arme sur la cible
	else:
		velocity = to_p.orthogonal().normalized() * PATROL_SPEED * _strafe_dir  # se balance
		_face(_player.global_position, delta)
	# Tir : anticipe la trajectoire de fuite ET ne tire pas a travers un allie.
	if _fire_t <= 0.0 and dist <= RANGE_ALERT:
		var aim := _predict_aim()
		if not _lane_blocked_by_ally(aim):
			_shoot_at(aim)

func _do_search(delta: float, sees: bool, hears: bool) -> void:
	if sees or hears:
		_enter_combat()
		return
	# Fouille coordonnee : chaque garde inspecte SA zone (ancre distincte),
	# autour d'une position anticipee de la fuite -> couverture, pas d'attroupement.
	if _search_target == Vector2.INF or global_position.distance_to(_search_target) < 18.0:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(0.0, SEARCH_RADIUS)
		_search_target = _search_anchor + Vector2(cos(a), sin(a)) * r
	_move_toward(_search_target, CHASE_SPEED * 0.8, delta)
	_search_timer += delta
	if _search_timer >= SEARCH_TIME:
		_enter_patrol()

# ============================================================
#  TRANSITIONS
# ============================================================
func _enter_patrol() -> void:
	state = State.PATROL
	_seen_timer = 0.0
	_search_timer = 0.0
	_rebuild_cone(RANGE_CALM)

func _enter_suspicion() -> void:
	state = State.SUSPICION
	_seen_timer = 0.0
	_search_timer = 0.0
	_rebuild_cone(RANGE_ALERT)

func _enter_combat() -> void:
	var was_combat := state == State.COMBAT
	state = State.COMBAT
	_rebuild_cone(RANGE_ALERT)
	if not was_combat:
		_alert_nearby(_last_seen)  # previent seulement les gardes proches

func _enter_search() -> void:
	state = State.SEARCH
	_search_timer = 0.0
	_search_target = Vector2.INF
	# Ancre = derniere position + anticipation de la fuite + decalage propre au garde.
	var lead := _last_seen_vel * SEARCH_LEAD
	var ang := fmod(float(get_instance_id()) * 0.618034, 1.0) * TAU  # angle stable, unique
	_search_anchor = _last_seen + lead + Vector2(cos(ang), sin(ang)) * SEARCH_SPREAD
	_rebuild_cone(RANGE_ALERT)

# Propage une alerte aux gardes a portee (pas a tout le batiment).
func _alert_nearby(pos: Vector2) -> void:
	for g in get_tree().get_nodes_in_group("guards"):
		if g == self:
			continue
		if global_position.distance_to(g.global_position) <= ALERT_RADIUS:
			g.on_alerted(pos)

# Recu d'un garde proche (ou du coffre) : va inspecter sans avoir vu soi-meme.
func on_alerted(pos: Vector2) -> void:
	if state == State.COMBAT:
		return
	_last_seen = pos
	if state == State.PATROL or state == State.SUSPICION:
		_enter_search()

# ============================================================
#  PERCEPTION
# ============================================================
func _can_see_player() -> bool:
	if _player == null:
		return false
	var to_p: Vector2 = _player.global_position - global_position
	var dist := to_p.length()
	var rng := RANGE_ALERT if state != State.PATROL else RANGE_CALM
	if dist > rng:
		return false
	# Proche colle : repere meme hors du cone (sens de proximite).
	if dist > PROXIMITY_SENSE:
		var ang_off := absf(angle_difference(rotation, to_p.angle()))
		var half := deg_to_rad(VISION_ANGLE)
		if ang_off > half:
			return false  # totalement hors du cone
		# Vision peripherique : nette au centre, portee reduite vers les bords.
		var edge := 1.0 - (ang_off / half) * 0.45  # 100% axe -> 55% bord
		if dist > rng * edge:
			return false
	# Raycast : un mur bloque la vision (layer world = 1)
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, _player.global_position, 1)
	q.exclude = [self]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	# Si le raycast touche un mur avant le joueur -> bloque
	return false

func _can_hear_player() -> bool:
	if _player == null or not _player.has_method("is_making_noise"):
		return false
	if not _player.is_making_noise():
		return false
	return global_position.distance_to(_player.global_position) <= NOISE_HEARING

# ============================================================
#  DEPLACEMENT / VISEE
# ============================================================
func _move_toward(target: Vector2, speed: float, delta: float) -> void:
	## Deplacement avec contournement des murs via le pathfinding du niveau.
	if _level == null:
		_level = get_tree().get_first_node_in_group("level")
	if _level == null or not _level.has_method("find_path"):
		# Repli : ligne droite si pas de grille de navigation.
		velocity = (target - global_position).normalized() * speed
		_face(target, delta)
		return

	# Recalcule le chemin si la cible a bouge ou si le chemin est epuise.
	if _path.is_empty() or _path_idx >= _path.size() or _path_target.distance_to(target) > REPATH_DIST:
		_path = _level.find_path(global_position, target)
		_path_target = target
		_path_idx = 0
		# Le 1er point est la case actuelle : on le saute s'il est sous nos pieds.
		if _path.size() > 0 and global_position.distance_to(_path[0]) < TILE * 0.5:
			_path_idx = 1

	# Plus de waypoint : approche directe finale.
	if _path_idx >= _path.size():
		var d := target - global_position
		velocity = d.normalized() * speed if d.length() > 1.0 else Vector2.ZERO
		if d.length() > 1.0:
			_face(target, delta)
		return

	var wp: Vector2 = _path[_path_idx]
	if global_position.distance_to(wp) < WAYPOINT_REACH:
		_path_idx += 1
		if _path_idx >= _path.size():
			velocity = Vector2.ZERO
			return
		wp = _path[_path_idx]
	velocity = (wp - global_position).normalized() * speed
	_face(wp, delta)

func _face(target: Vector2, delta: float) -> void:
	var want := (target - global_position).angle()
	rotation = lerp_angle(rotation, want, clampf(TURN_SPEED * delta, 0.0, 1.0))

func _shoot_at(target: Vector2) -> void:
	_fire_t = FIRE_COOLDOWN
	AudioManager.play_sfx("shoot_guard")
	# Le bruit du coup de feu alerte les gardes proches (squad local, pas tout le batiment).
	for g in get_tree().get_nodes_in_group("guards"):
		if g != self and global_position.distance_to(g.global_position) <= GUNFIRE_ALERT_RADIUS \
				and g.has_method("on_alerted"):
			g.on_alerted(_last_seen)
	if bullet_scene == null:
		return
	var b := bullet_scene.instantiate() as Bullet
	var dir := (target - muzzle.global_position).normalized()
	b.global_position = muzzle.global_position
	b.setup(dir, false)
	get_tree().current_scene.add_child(b)

# Visee anticipee : vise la ou le joueur SERA, vu le temps de vol de la balle.
func _predict_aim() -> Vector2:
	if _player == null:
		return global_position
	var pv: Vector2 = _player.velocity
	var aim: Vector2 = _player.global_position
	for _i in range(2):  # deux iterations : convergence rapide
		var t := global_position.distance_to(aim) / BULLET_SPEED
		aim = _player.global_position + pv * t
	return aim

# Refuse le tir si un allie se trouve dans le couloir de tir (anti tir ami).
func _lane_blocked_by_ally(aim: Vector2) -> bool:
	var dir := aim - muzzle.global_position
	var dist := dir.length()
	if dist < 1.0:
		return false
	dir /= dist
	for g in get_tree().get_nodes_in_group("guards"):
		if g == self:
			continue
		var to_g: Vector2 = g.global_position - muzzle.global_position
		var proj := to_g.dot(dir)
		if proj <= 0.0 or proj >= dist:
			continue  # allie derriere nous ou au-dela de la cible
		if (to_g - dir * proj).length() < ALLY_LANE_WIDTH:
			return true
	return false

# Allie le plus proche (pour le repli coordonne des gardes non armes).
func _nearest_ally() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for g in get_tree().get_nodes_in_group("guards"):
		if g == self:
			continue
		var d := global_position.distance_to(g.global_position)
		if d < best_d:
			best_d = d
			best = g
	return best

# ============================================================
#  DEGATS
# ============================================================
func take_damage(amount: int = 1) -> void:
	hp -= amount
	# Etre touche : le garde reagit meme sans avoir vu (tir silencieux mais impact ressenti)
	GameState.report_player_pos(_player.global_position if _player else global_position)
	if hp <= 0:
		GameState.on_guard_neutralized()
		AudioManager.play_sfx("guard_down")
		queue_free()
		return
	if state == State.PATROL or state == State.SUSPICION:
		_enter_combat()

# ============================================================
#  CONE DE VISION (visuel)
# ============================================================
func _rebuild_cone(rng: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	var steps := 12
	var a0 := -deg_to_rad(VISION_ANGLE)
	var a1 := deg_to_rad(VISION_ANGLE)
	for i in range(steps + 1):
		var a: float = lerp(a0, a1, float(i) / steps)
		pts.append(Vector2(cos(a), sin(a)) * rng)
	cone.polygon = pts

func _update_cone_color() -> void:
	match state:
		State.PATROL:
			cone.color = Color(0.2, 0.9, 0.3, 0.12)
		State.SUSPICION:
			cone.color = Color(1.0, 0.7, 0.1, 0.18)
		_:
			cone.color = Color(1.0, 0.2, 0.2, 0.22)

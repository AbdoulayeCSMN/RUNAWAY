extends CharacterBody2D
class_name Player
## Agent Zero. Deplacement 8 directions, visee souris, tir, rechargement,
## sprint bruyant, couverture automatique, vies + invincibilite temporaire.

# --- Reglages (GDD 3.1 / 3.2 / 3.3) ---
const SPEED := 270.0
const SPRINT_MULT := 1.6
const TURN_SPEED := 14.0                 # vitesse de rotation vers la direction
const COVER_SPEED_MULT := 0.7          # -30% en couverture
const COVER_HITBOX_MULT := 0.6         # -40% de hitbox
const SPRINT_MAX := 2.2                 # secondes de sprint disponibles
const SPRINT_REGEN := 0.8               # regen par seconde
const SPRINT_NOISE_RADIUS := 120.0      # GDD 4.3 : bruit de pas en sprint
const MAG_SIZE := 8
const RELOAD_TIME := 1.2
const FIRE_COOLDOWN := 0.22             # cadence limitee
const IFRAME_TIME := 0.5                # invincibilite apres un hit

@export var bullet_scene: PackedScene

signal ammo_changed(ammo: int, mag: int)
signal reload_state(active: bool)
signal sprint_changed(ratio: float)

var ammo := MAG_SIZE
var reloading := false
var in_cover := false
var _reload_t := 0.0
var _fire_t := 0.0
var _iframe_t := 0.0
var _sprint_energy := SPRINT_MAX
var _sprinting := false
var _touch: Node          # controles tactiles (Android), null sur desktop

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var cover_area: Area2D = $CoverArea
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")
	ammo_changed.emit(ammo, MAG_SIZE)
	GameState.health_changed.emit(GameState.health, GameState.MAX_HEALTH)

func _physics_process(delta: float) -> void:
	if GameState.mission_over:
		velocity = Vector2.ZERO
		return
	_update_timers(delta)
	_aim(delta)
	_update_cover()
	_handle_movement(delta)
	_handle_shooting()
	_handle_reload()
	_update_iframe_visual()

# --- Orientation : direction de deplacement ---
#  Tactile -> stick de visee. Sinon : le personnage regarde la ou il marche.
#  A l'arret, il CONSERVE l'orientation de son dernier deplacement.
func _aim(delta: float) -> void:
	var tc := _touch_controls()
	if tc and tc.aim_vec != Vector2.ZERO:
		rotation = tc.aim_vec.angle()
		return
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir != Vector2.ZERO:
		rotation = lerp_angle(rotation, move_dir.angle(), clampf(TURN_SPEED * delta, 0.0, 1.0))
	# Sinon : on ne touche pas a la rotation (garde le dernier cap).

func _touch_controls() -> Node:
	# Renvoie les controles tactiles seulement s'ils sont actifs (Android).
	if _touch == null:
		_touch = get_tree().get_first_node_in_group("touch_controls")
	if _touch and _touch.visible:
		return _touch
	return null

# --- Deplacement 8 directions ---
func _handle_movement(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := SPEED

	_sprinting = false
	if Input.is_action_pressed("sprint") and _sprint_energy > 0.0 and dir != Vector2.ZERO and not in_cover:
		_sprinting = true
		speed *= SPRINT_MULT
		_sprint_energy = max(0.0, _sprint_energy - delta)
	else:
		_sprint_energy = min(SPRINT_MAX, _sprint_energy + SPRINT_REGEN * delta)
	sprint_changed.emit(_sprint_energy / SPRINT_MAX)

	if in_cover:
		speed *= COVER_SPEED_MULT

	velocity = dir * speed
	move_and_slide()

# --- Couverture automatique : colle a un mur proche ---
func _update_cover() -> void:
	var near_wall := cover_area.get_overlapping_bodies().size() > 0
	if near_wall != in_cover:
		in_cover = near_wall
		# Hitbox reduite en couverture
		collision.scale = Vector2.ONE * (COVER_HITBOX_MULT if in_cover else 1.0)

# --- Tir ---
func _handle_shooting() -> void:
	if reloading:
		return
	# Sur tactile : on tire avec le stick droit (ignore le clic souris emule).
	var tc := _touch_controls()
	var want_fire: bool = tc.firing if tc else Input.is_action_pressed("shoot")
	if want_fire and _fire_t <= 0.0:
		if ammo > 0:
			_shoot()
		else:
			_start_reload()

func _shoot() -> void:
	ammo -= 1
	_fire_t = FIRE_COOLDOWN
	ammo_changed.emit(ammo, MAG_SIZE)
	AudioManager.play_sfx("shoot_silenced")
	if bullet_scene:
		var b := bullet_scene.instantiate() as Bullet
		var dir := Vector2.RIGHT.rotated(rotation)
		b.global_position = muzzle.global_position
		b.setup(dir, true)
		# La balle vit dans le niveau, pas attachee au joueur
		get_tree().current_scene.add_child(b)
	if ammo <= 0:
		_start_reload()

# --- Rechargement manuel (R) ou auto quand vide ---
func _handle_reload() -> void:
	if Input.is_action_just_pressed("reload") and not reloading and ammo < MAG_SIZE:
		_start_reload()

func _start_reload() -> void:
	if reloading:
		return
	reloading = true
	_reload_t = RELOAD_TIME
	reload_state.emit(true)
	AudioManager.play_sfx("reload")

func _update_timers(delta: float) -> void:
	if _fire_t > 0.0:
		_fire_t -= delta
	if _iframe_t > 0.0:
		_iframe_t -= delta
	if reloading:
		_reload_t -= delta
		if _reload_t <= 0.0:
			reloading = false
			ammo = MAG_SIZE
			ammo_changed.emit(ammo, MAG_SIZE)
			reload_state.emit(false)

# --- Degats + invincibilite ---
func take_damage(amount: int = 1) -> void:
	if _iframe_t > 0.0 or GameState.mission_over:
		return
	_iframe_t = IFRAME_TIME
	AudioManager.play_sfx("hit")
	GameState.damage_player(amount)

func _update_iframe_visual() -> void:
	if _iframe_t > 0.0:
		# Clignotement pendant l'invincibilite
		sprite.modulate.a = 0.4 + 0.6 * absf(sin(_iframe_t * 30.0))
	else:
		sprite.modulate.a = 1.0

# --- Bruit : entendu par les gardes (GDD 4.3) ---
func is_making_noise() -> bool:
	return _sprinting

func noise_radius() -> float:
	return SPRINT_NOISE_RADIUS

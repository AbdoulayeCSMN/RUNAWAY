extends Area2D
class_name Bullet
## Projectile. Reutilise pour le joueur et les ennemis.
## from_player determine les collisions et la cible des degats.

var velocity: Vector2 = Vector2.ZERO
var speed: float = 700.0
var damage: int = 1
var from_player: bool = true
var life: float = 1.5  # disparition automatique (GDD : Bullet.tscn)

func setup(dir: Vector2, shooter_is_player: bool) -> void:
	from_player = shooter_is_player
	velocity = dir.normalized() * speed
	rotation = dir.angle()
	# Couches de collision : qui peut etre touche
	# layer world=1, player=2, guards=3, bullets_player=4, bullets_enemy=5
	collision_layer = 0
	if from_player:
		# La balle joueur touche murs(1) + gardes(3)
		set_collision_mask_value(1, true)
		set_collision_mask_value(3, true)
	else:
		# La balle ennemie touche murs(1) + joueur(2)
		set_collision_mask_value(1, true)
		set_collision_mask_value(2, true)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Mur ou obstacle statique
	if body is StaticBody2D or body.is_in_group("walls"):
		_impact()
		return
	if from_player and body.is_in_group("guards"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_impact()
		return
	if not from_player and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_impact()
		return

func _impact() -> void:
	# Phase 3 : instancier une particule d'impact ici
	queue_free()

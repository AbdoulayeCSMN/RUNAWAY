extends Node
## GameState — Autoload singleton.
## Cerveau central du jeu : etat d'alarme, score, vies, objectif.
## Tout le monde lit/ecrit ici et se branche sur les signaux.

# --- Etats d'alarme (GDD 3.4) ---
enum Alarm { CALM, SUSPICION, ALERT }

signal alarm_changed(new_state: int)
signal score_changed(new_score: int)
signal health_changed(new_health: int, max_health: int)
signal objective_changed(done: bool)
signal mission_ended(success: bool, reason: String)

# --- Config joueur ---
const MAX_HEALTH := 3

# --- Campagne (monde ouvert continu) ---
const LEVEL_COUNT := 3
var current_level: int = 0           # 0 recherche, 1 foret, 2 ville

# --- Etat courant ---
var alarm_state: int = Alarm.CALM
var score: int = 0
var health: int = MAX_HEALTH
var objective_done: bool = false
var mission_over: bool = false

# Derniere position connue du joueur (partagee : convergence des gardes en alerte)
var last_known_player_pos: Vector2 = Vector2.ZERO
var has_known_pos: bool = false

# Compteurs de score (GDD 3.5)
var mission_time: float = 0.0      # -1 pt/seconde
var guards_neutralized: int = 0    # +100 pt chacun
var alarm_ever_triggered: bool = false  # discretion: +500 si jamais declenchee

# Minuterie de retour au calme depuis suspicion
var _suspicion_timer: float = 0.0
const SUSPICION_TIMEOUT := 5.0  # GDD 3.4 : 5 secondes pour disparaitre
# Minuterie de retour au calme depuis alerte (aucun garde en combat)
var _combat_timer: float = 0.0
const ALERT_TIMEOUT := 7.0      # sans combat actif -> l'alerte retombe

func _ready() -> void:
	reset_campaign()

# Demarre une nouvelle campagne depuis le niveau 0 (remet tout a zero).
func reset_campaign() -> void:
	current_level = 0
	score = 0
	health = MAX_HEALTH
	mission_time = 0.0
	guards_neutralized = 0
	alarm_ever_triggered = false
	_reset_level_state()

# Compat : ancien point d'entree (= nouvelle campagne).
func reset() -> void:
	reset_campaign()

# Prepare l'etat propre a un niveau SANS toucher aux cumuls de campagne
# (score, vies, temps, gardes neutralises persistent d'un niveau a l'autre).
func begin_level() -> void:
	_reset_level_state()

func _reset_level_state() -> void:
	alarm_state = Alarm.CALM
	objective_done = false
	mission_over = false
	_suspicion_timer = 0.0
	_combat_timer = 0.0
	has_known_pos = false

# Sortie atteinte : passe au niveau suivant, ou termine la campagne.
func advance_or_finish(reason: String) -> void:
	if mission_over:
		return
	if current_level < LEVEL_COUNT - 1:
		current_level += 1
		add_score(300)  # bonus d'etape franchie
		begin_level()
		get_tree().reload_current_scene()
	else:
		end_mission(true, reason)

func is_last_level() -> bool:
	return current_level >= LEVEL_COUNT - 1

func _process(delta: float) -> void:
	if mission_over:
		return
	mission_time += delta
	# Decrue automatique de l'etat d'alarme (ambiance / musique).
	match alarm_state:
		Alarm.SUSPICION:
			_suspicion_timer -= delta
			if _suspicion_timer <= 0.0:
				_set_alarm_internal(Alarm.CALM)
		Alarm.ALERT:
			# Tant qu'un garde est en combat, notify_combat() remet ce timer a 0.
			_combat_timer += delta
			if _combat_timer >= ALERT_TIMEOUT:
				_set_alarm_internal(Alarm.SUSPICION)  # plus de combat -> redescend

# --- Alarme (ambiance globale : pilote la musique et le score) ---
# Applique reellement le changement d'etat. La montee comme la descente
# passent par ici ; les regles de transition sont gerees par les appelants.
func _set_alarm_internal(new_state: int) -> void:
	if mission_over or new_state == alarm_state:
		return
	alarm_state = new_state
	if new_state == Alarm.SUSPICION:
		_suspicion_timer = SUSPICION_TIMEOUT
	if new_state == Alarm.ALERT:
		alarm_ever_triggered = true
		_combat_timer = 0.0
	alarm_changed.emit(alarm_state)

# Un garde voit/entend quelque chose : monte (ou rafraichit) la suspicion.
func raise_suspicion() -> void:
	if alarm_state == Alarm.ALERT:
		return  # deja au-dessus
	if alarm_state == Alarm.SUSPICION:
		_suspicion_timer = SUSPICION_TIMEOUT
	else:
		_set_alarm_internal(Alarm.SUSPICION)

# Un garde est activement en combat. A appeler chaque frame de combat :
# maintient l'alerte tant que le joueur est engage, sinon elle retombe.
func notify_combat() -> void:
	_combat_timer = 0.0
	if alarm_state != Alarm.ALERT:
		_set_alarm_internal(Alarm.ALERT)

# Compat : declenchement direct de l'alarme (ex. ouverture du coffre).
func trigger_alarm() -> void:
	notify_combat()

func is_alert() -> bool:
	return alarm_state == Alarm.ALERT

# Reveille les gardes proches d'une position (alerte LOCALE, pas tout le batiment).
func alert_guards_near(pos: Vector2, radius: float) -> void:
	for g in get_tree().get_nodes_in_group("guards"):
		if g.global_position.distance_to(pos) <= radius and g.has_method("on_alerted"):
			g.on_alerted(pos)

# Un garde signale ou il a vu/entendu le joueur (memoire partagee facultative).
func report_player_pos(p: Vector2) -> void:
	last_known_player_pos = p
	has_known_pos = true

# --- Score ---
func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func on_guard_neutralized() -> void:
	guards_neutralized += 1
	add_score(100)

# --- Vies ---
func damage_player(amount: int = 1) -> void:
	if mission_over:
		return
	health = max(0, health - amount)
	add_score(-50 * amount)  # GDD 3.5 : -50 pt par PV perdu
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		end_mission(false, "Agent Zero est tombe.")

func heal_player(amount: int = 1) -> void:
	health = min(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)

# --- Objectif ---
func complete_objective() -> void:
	if objective_done:
		return
	objective_done = true
	add_score(1000)  # GDD 3.5 : objectif principal
	objective_changed.emit(true)

# --- Fin de mission ---
func end_mission(success: bool, reason: String) -> void:
	if mission_over:
		return
	mission_over = true
	if success:
		add_score(500)  # exfiltration reussie
		if not alarm_ever_triggered:
			add_score(500)  # bonus discretion totale
	# Bonus/malus temps applique au moment du calcul final via final_score()
	mission_ended.emit(success, reason)

func final_score() -> int:
	# Le temps est decompte ici pour ne le faire qu'une fois
	return score - int(mission_time)

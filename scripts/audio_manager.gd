extends Node
## AudioManager — Autoload singleton (Phase 3).
## SFX : pool de lecteurs (sons qui se chevauchent). Musique : boucle qui
## change selon l'etat d'alarme (calme / suspicion / alerte).

const SFX := {
	"shoot_silenced": preload("res://assets/audio/shoot_silenced.wav"),
	"shoot_guard": preload("res://assets/audio/shoot_guard.wav"),
	"reload": preload("res://assets/audio/reload.wav"),
	"vault": preload("res://assets/audio/vault.wav"),
	"exfil": preload("res://assets/audio/exfil.wav"),
	"hit": preload("res://assets/audio/hit.wav"),
	"guard_down": preload("res://assets/audio/guard_down.wav"),
	"alarm": preload("res://assets/audio/alarm.wav"),
	"ui_click": preload("res://assets/audio/ui_click.wav"),
}

const MUSIC := {
	GameState.Alarm.CALM: preload("res://assets/audio/music_calm.wav"),
	GameState.Alarm.SUSPICION: preload("res://assets/audio/music_suspicion.wav"),
	GameState.Alarm.ALERT: preload("res://assets/audio/music_alert.wav"),
}

const SFX_VOICES := 10

var _sfx: Array[AudioStreamPlayer] = []
var _sfx_idx := 0
var _music: AudioStreamPlayer
var _current_music := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # le son continue meme en pause
	# Boucler tous les morceaux de musique.
	for key in MUSIC:
		var s: AudioStreamWAV = MUSIC[key]
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2  # mono 16 bits -> 2 octets/echantillon

	for i in range(SFX_VOICES):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx.append(p)

	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	_music.volume_db = -24.0  # musique d'ambiance discrete (ne couvre pas les SFX)
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)

	GameState.alarm_changed.connect(_on_alarm_changed)
	set_music_for_alarm(GameState.alarm_state)

func play_sfx(name: String) -> void:
	if not SFX.has(name):
		return
	var p := _sfx[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx.size()
	p.stream = SFX[name]
	p.play()

func set_music_for_alarm(state: int) -> void:
	if not MUSIC.has(state) or state == _current_music:
		return
	_current_music = state
	_music.stream = MUSIC[state]
	_music.play()

func _on_alarm_changed(state: int) -> void:
	if state == GameState.Alarm.ALERT and _current_music != GameState.Alarm.ALERT:
		play_sfx("alarm")
	set_music_for_alarm(state)

# Relance la musique calme au demarrage d'un niveau (apres reset).
func restart_music() -> void:
	_current_music = -1
	set_music_for_alarm(GameState.alarm_state)

extends Node
## Outil TEMPORAIRE de capture d'ecran (non inclus dans le build final).
## Autoload lance via project.godot ; capture la scene courante puis quitte.
## Usage : Godot --path . res://scenes/<Scene>.tscn -- --shot=nom.png [--level=N]

func _ready() -> void:
	var out := "shot.png"
	for a in OS.get_cmdline_user_args():
		if (a as String).begins_with("--shot="):
			out = (a as String).substr(7)
	_run.call_deferred(out)

func _run(out: String) -> void:
	# Laisse la scene se construire, l'IA bouger un peu et la banniere de niveau disparaitre.
	await get_tree().create_timer(2.6).timeout
	# Assure-toi qu'au moins une frame est dessinee avant la capture.
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := "res://docs/screenshots/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var err := img.save_png(dir + out)
	print("[shot_capture] save '", out, "' -> err=", err, " size=", img.get_size())
	get_tree().quit()

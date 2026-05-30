extends RefCounted
class_name LevelCatalog
## Catalogue data-driven de la campagne RUNAWAY (monde ouvert continu).
## La sortie d'un niveau devient l'entree du suivant :
##   0 Centre de recherche (interieur)  -> voler les donnees puis sortir
##   1 Foret (traversee)                -> franchir la riviere, rejoindre l'exfil
##   2 Ville (finale)                   -> atteindre l'helipad au-dela du fleuve
##
## Chaque niveau : { name, subtitle, theme, ambiance, needs_objective,
##                   map, guards, medkits, terminals }
## Legende des cartes ASCII (cf. level.gd) :
##   #  obstacle plein (mur / lisiere d'arbres / immeuble)
##   o  couverture basse (caisse / rocher / voiture)
##   W  eau (infranchissable, bloque aussi la vue)
##   .  sol praticable        P  entree joueur
##   C  coffre (objectif)     X  sortie / exfiltration

static func count() -> int:
	return 3

static func get_level(idx: int) -> Dictionary:
	match clampi(idx, 0, count() - 1):
		0: return _research()
		1: return _forest()
		2: return _city()
	return _research()

# ---------------------------------------------------------------------------
# NIVEAU 0 — Centre de recherche (interieur, design existant)
# ---------------------------------------------------------------------------
static func _research() -> Dictionary:
	return {
		"name": "Centre de recherche",
		"subtitle": "Volez les donnees et exfiltrez-vous",
		"theme": "research",
		"ambiance": Color(0.34, 0.34, 0.42),
		"needs_objective": true,
		"map": [
			"##############################################",
			"#XX............################..............#",
			"#..............################..............#",
			"#..............################..............#",
			"#..............######..########..............#",
			"######..#############..#############..########",
			"#..............#..............#..............#",
			"#...o..........#..............#..............#",
			"#...........o..#...........o..#...........o..#",
			"#....#.........#....#.........#....#.........#",
			"#............................................#",
			"#.....................C......................#",
			"#..............#..............#..............#",
			"#..............#..o...........#..o...........#",
			"#.........#....#.........#....#.........#....#",
			"#..............#..............#..............#",
			"#..............#..............#..............#",
			"#..............#..............#..............#",
			"######..##############..##############..######",
			"#............................................#",
			"#............................................#",
			"#.......o.............#...............o......#",
			"#............................................#",
			"#............................................#",
			"##########..######################..##########",
			"#............................................#",
			"#............................................#",
			"#...........#.......o....o.......#...........#",
			"#.....o...............P.................o....#",
			"#............................................#",
			"#............................................#",
			"##############################################",
		],
		"guards": [
			{ "type": Guard.Type.BASIC, "cell": Vector2i(5, 28),  "patrol": [Vector2i(5, 28), Vector2i(41, 28)] },
			{ "type": Guard.Type.BASIC, "cell": Vector2i(40, 26), "patrol": [Vector2i(40, 26), Vector2i(5, 26)] },
			{ "type": Guard.Type.ALERT, "cell": Vector2i(6, 20),  "patrol": [Vector2i(6, 20), Vector2i(40, 20)] },
			{ "type": Guard.Type.BASIC, "cell": Vector2i(6, 10),  "patrol": [Vector2i(6, 10), Vector2i(12, 16), Vector2i(6, 16), Vector2i(6, 9)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(22, 8),  "patrol": [Vector2i(22, 8), Vector2i(22, 16)] },
			{ "type": Guard.Type.ALERT, "cell": Vector2i(40, 10), "patrol": [Vector2i(40, 10), Vector2i(33, 16), Vector2i(40, 16), Vector2i(40, 7)] },
			{ "type": Guard.Type.BASIC, "cell": Vector2i(8, 2),   "patrol": [Vector2i(8, 2), Vector2i(13, 2)] },
			{ "type": Guard.Type.ALERT, "cell": Vector2i(38, 2),  "patrol": [Vector2i(38, 2), Vector2i(35, 2)] },
		],
		"medkits": [Vector2i(6, 16), Vector2i(38, 16)],
		"terminals": [Vector2i(38, 3)],
	}

# ---------------------------------------------------------------------------
# NIVEAU 1 — Foret (traversee bas -> haut, riviere + pont central)
# ---------------------------------------------------------------------------
static func _forest() -> Dictionary:
	return {
		"name": "La Foret",
		"subtitle": "Franchissez le pont, rejoignez l'exfiltration",
		"theme": "forest",
		"ambiance": Color(0.40, 0.46, 0.40),
		"needs_objective": false,
		"map": [
			"##############################################",
			"######..........XXXX..........################",
			"####....oo..................oo......##########",
			"###........####.......####.........###########",
			"##....oo...####...oo..####....oo......########",
			"##.........##..........##............oo....###",
			"#....###.........................###.......###",
			"#...####....oo.......oo.........oo...##.....##",
			"#.........#####.....................oo.....###",
			"#..oo.....#####.........####.......###.....###",
			"#.................oo....####....oo.........###",
			"#....####..................................###",
			"#...####....oo........oo.......oo....####...##",
			"#...........#####.............####.........###",
			"#....oo.....#####....oo.......####....oo....##",
			"WWWWWWWWWWWWWWWWWWW....WWWWWWWWWWWWWWWWWWWWW##",
			"WWWWWWWWWWWWWWWWWWW....WWWWWWWWWWWWWWWWWWWWW##",
			"#..........####.....oo........####.........###",
			"#...oo.....####..............####....oo....###",
			"#..............oo.......oo.................###",
			"#....####.................oo.......####....###",
			"#...####....oo.......####...........###....###",
			"#...........####....####....oo.............###",
			"#....oo.....####............####....oo.....###",
			"#.......................####...............###",
			"#..####....oo.......oo.......oo....####.....##",
			"#..####.................###........####....###",
			"#..........oo.......oo...###...oo..........###",
			"##....###...............###...........###..###",
			"###........................................###",
			"#####...........P..............###############",
			"##############################################",
		],
		"guards": [
			{ "type": Guard.Type.BASIC, "cell": Vector2i(8, 29),  "patrol": [Vector2i(4, 29), Vector2i(20, 29)] },
			{ "type": Guard.Type.BASIC, "cell": Vector2i(36, 29), "patrol": [Vector2i(40, 29), Vector2i(24, 29)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(3, 24),  "patrol": [Vector2i(3, 24), Vector2i(18, 24)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(40, 24), "patrol": [Vector2i(40, 24), Vector2i(30, 24)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(21, 18), "patrol": [Vector2i(21, 13), Vector2i(21, 20)] },
			{ "type": Guard.Type.BASIC, "cell": Vector2i(10, 11), "patrol": [Vector2i(10, 11), Vector2i(20, 11)] },
			{ "type": Guard.Type.ALERT, "cell": Vector2i(38, 11), "patrol": [Vector2i(38, 11), Vector2i(28, 11)] },
			{ "type": Guard.Type.ALERT, "cell": Vector2i(10, 4),  "patrol": [Vector2i(10, 6), Vector2i(10, 2)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(29, 4),  "patrol": [Vector2i(29, 4), Vector2i(30, 2)] },
			{ "type": Guard.Type.BASIC, "cell": Vector2i(20, 6),  "patrol": [Vector2i(16, 6), Vector2i(28, 6)] },
		],
		"medkits": [Vector2i(2, 19), Vector2i(42, 19)],
		"terminals": [],
	}

# ---------------------------------------------------------------------------
# NIVEAU 2 — Ville (rejoindre l'helipad, fleuve + pont au nord)
# ---------------------------------------------------------------------------
static func _city() -> Dictionary:
	return {
		"name": "La Ville",
		"subtitle": "Traversez le pont vers l'helipad d'extraction",
		"theme": "city",
		"ambiance": Color(0.36, 0.38, 0.46),
		"needs_objective": false,
		"map": [
			"##############################################",
			"##############XXXX############################",
			"##############....############################",
			"WWWWWWWWWWWWWW....WWWWWWWWWWWWWWWWWWWWWWWWWW##",
			"WWWWWWWWWWWWWW....WWWWWWWWWWWWWWWWWWWWWWWWWW##",
			"#.....o.........o..................o........o#",
			"#............................................#",
			"#..######....######....######....######......#",
			"#..######....######....######....######......#",
			"#..######....######....######....######......#",
			"#.o......o..........o...........o.........o..#",
			"#............................................#",
			"#....########....######....########..........#",
			"#....########....######....########....oo....#",
			"#....########....######....########..........#",
			"#.o.......o............o.........o.........o.#",
			"#............................................#",
			"#..######....##########....######....######..#",
			"#..######....##########....######....######..#",
			"#.o....o..........o.............o........o...#",
			"#............................................#",
			"#....######....######....######....########..#",
			"#....######....######....######....########..#",
			"#....######....######....######....########..#",
			"#.o......o.........o..........o..........o...#",
			"#............................................#",
			"#..########....######....######....######....#",
			"#..########....######....######....######....#",
			"#.o.....o.........o...........o.........o....#",
			"#............................................#",
			"########............P............#############",
			"##############################################",
		],
		"guards": [
			{ "type": Guard.Type.BASIC, "cell": Vector2i(12, 30), "patrol": [Vector2i(8, 30), Vector2i(30, 30)] },
			{ "type": Guard.Type.BASIC, "cell": Vector2i(33, 29), "patrol": [Vector2i(38, 29), Vector2i(14, 29)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(6, 24),  "patrol": [Vector2i(6, 24), Vector2i(20, 24)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(40, 24), "patrol": [Vector2i(40, 24), Vector2i(26, 24)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(21, 19), "patrol": [Vector2i(8, 19), Vector2i(38, 19)] },
			{ "type": Guard.Type.ALERT, "cell": Vector2i(8, 15),  "patrol": [Vector2i(8, 15), Vector2i(22, 15)] },
			{ "type": Guard.Type.ALERT, "cell": Vector2i(38, 11), "patrol": [Vector2i(38, 11), Vector2i(24, 11)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(6, 10),  "patrol": [Vector2i(6, 10), Vector2i(19, 10)] },
			{ "type": Guard.Type.BASIC, "cell": Vector2i(17, 5),  "patrol": [Vector2i(12, 5), Vector2i(30, 5)] },
			{ "type": Guard.Type.ARMED, "cell": Vector2i(28, 6),  "patrol": [Vector2i(34, 6), Vector2i(16, 6)] },
		],
		"medkits": [Vector2i(4, 16), Vector2i(40, 16)],
		"terminals": [],
	}

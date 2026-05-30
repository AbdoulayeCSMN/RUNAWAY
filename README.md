# RUNAWAY — Operation Eclipse

Jeu d'infiltration top-down developpe avec **Godot 4.6.2** (GDScript). Vous incarnez
l'Agent Zero, charge d'infiltrer le complexe Eclipse a travers une campagne de trois
niveaux : voler les donnees classifiees, eviter les gardes et rejoindre la zone
d'exfiltration. La discretion est recompensee, mais le jeu reste jouable en force.

![Menu principal](docs/screenshots/01_menu.png)

---

## A propos

RUNAWAY combine furtivite et action dans un environnement vu de dessus. Le coeur du jeu
repose sur une IA de gardes avancee et une progression de campagne ou le score, les
points de vie et le temps sont cumules d'un niveau a l'autre.

- **Plateformes** : Windows, Linux et Android (preparation Google Play).
- **Moteur** : Godot 4.6.2, rendu compatibilite mobile (GL Compatibility).
- **Langue** : francais ; jouable au clavier/souris et entierement au tactile.

## Fonctionnalites

- **Campagne en 3 niveaux** enchaines automatiquement (Centre de recherche, Foret, Ville).
- **IA de gardes intelligente** :
  - vision en cone avec attenuation peripherique (detection plus fiable au centre) ;
  - tir predictif (anticipation du deplacement du joueur) ;
  - encerclement coordonne via une sequence de Weyl (repartition autour de la cible) ;
  - evitement du tir ami (ne tire pas a travers un allie) ;
  - propagation du bruit (les coups de feu alertent les gardes alentour) ;
  - fouille coordonnee de la derniere position connue.
- **Systeme d'alarme** a trois etats : Calme, Suspicion, Alerte.
- **Furtivite** : mise a couvert, gestion du bruit (sprint), cones de vision a eviter.
- **Niveaux data-driven** (catalogue ASCII, themes recherche / foret / ville).
- **Interface adaptative** clavier/souris et tactile (sticks virtuels, boutons E/R).
- **Pret pour le deploiement Android** : presets APK/AAB, signature release, icones adaptatives.

## Captures d'ecran

| Niveau 1 — Centre de recherche | Niveau 2 — La Foret |
| :----------------------------: | :-----------------: |
| ![Niveau 1](docs/screenshots/03_level1_research.png) | ![Niveau 2](docs/screenshots/04_level2_forest.png) |

| Niveau 3 — La Ville | Briefing de mission |
| :-----------------: | :-----------------: |
| ![Niveau 3](docs/screenshots/05_level3_city.png) | ![Briefing](docs/screenshots/02_briefing.png) |

## Commandes

### Clavier et souris

| Action                       | Touche                         |
| ---------------------------- | ------------------------------ |
| Se deplacer                  | `W` `A` `S` `D` ou fleches     |
| Sprinter                     | `Maj` (maintenu)               |
| Viser / tirer                | Clic gauche                    |
| Recharger                    | `R`                            |
| Interagir (coffre, terminal) | `E` (maintenu)                 |
| Pause                        | `Echap`                        |

### Tactile (Android)

| Action          | Geste                                          |
| --------------- | ---------------------------------------------- |
| Se deplacer     | Stick gauche (pousse a fond = sprint)          |
| Viser / tirer   | Stick droit                                    |
| Recharger       | Bouton `R` a l'ecran                           |
| Interagir       | Bouton `E` a l'ecran (maintenu)                |
| Pause           | Bouton Retour du telephone                     |

## Lancer le jeu

1. Installer **Godot 4.6.2** (version standard, .NET non requis).
2. Ouvrir le dossier du projet depuis Godot (le fichier `project.godot`).
3. Lancer la scene principale (`scenes/Main.tscn`) avec **F5**.

En ligne de commande :

```bash
godot --path . res://scenes/Main.tscn
```

## Build Android et Play Store

Les presets d'export (APK de test et AAB pour le Store) sont definis dans
`export_presets.cfg`. La procedure complete (modele de build, generation du keystore,
export, etapes Google Play Console) est detaillee dans le guide de deploiement.

```bash
godot --headless --export-release "Android AAB (Play Store)" build/runaway.aab
```

## Documentation

| Document                          | Description                                            |
| --------------------------------- | ------------------------------------------------------ |
| `docs/RUNAWAY_GDD_v4.pdf`         | Game Design Document complet (mecaniques, IA, formules). |
| `docs/RUNAWAY_GUIDE.pdf`          | Guide du joueur + guide de build et de deploiement.    |

Les sources LaTeX correspondantes (`.tex`) sont fournies dans le meme dossier.

## Structure du projet

```
RUNAWAY/
  scenes/            Scenes Godot (menu, briefing, niveaux, joueur, gardes, HUD)
  scripts/           Logique GDScript (etat de jeu, IA, niveaux, interface)
  assets/            Sprites et sons utilises par le jeu
  kenney_top-down-shooter/  Tuiles et sprites (Kenney, CC0) charges par les niveaux
  mobile_icons/      Icones de lanceur Android (adaptatives)
  docs/              GDD, guide et captures d'ecran
  tools/             Scripts utilitaires (icones, keystore, captures)
  export_presets.cfg Presets d'export Android (APK / AAB)
```

## Technologies

- **Godot Engine 4.6.2** — moteur de jeu, GDScript.
- **AStarGrid2D** — navigation et pathfinding des gardes.
- **LaTeX** — documentation (GDD et guide).
- **Python (Pillow)** — generation des icones de lanceur.

## Licence et credits

- Assets graphiques et sonores : **Kenney** (kenney.nl), licence **CC0**.
- Code du jeu : voir le proprietaire du depot.

---

Bonne infiltration, Agent Zero.

# -*- coding: utf-8 -*-
"""Apercus (vue de dessus) des 2 nouveaux environnements de la campagne :
foret (Niveau 2) et ville (Niveau 3). Plus un schema du flux open-world.
Ne touche pas au jeu : sort des PNG dans tools/mockups/.

Legende des cartes ASCII (memes semantiques que level.gd) :
  #  obstacle plein (mur batiment / lisiere d'arbres / facade)
  o  couverture basse (rocher / buisson / voiture)
  .  sol praticable (herbe / asphalte / dalle)
  P  entree du joueur (raccord avec la sortie du niveau precedent)
  X  sortie / exfiltration vers le niveau suivant
  C  objectif optionnel (cache / colis) — facultatif selon le niveau
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle, FancyArrow
import matplotlib.patches as mpatches

# ---------------------------------------------------------------------------
# NIVEAU 2 — FORET : traversee verticale, entree en bas, exfil en haut.
# L'espion sort du batiment (Niveau 1) et debouche dans les bois.
# Arbres = lisieres pleines (#), rochers/buissons = couverture (o).
# ---------------------------------------------------------------------------
FOREST = [
    "##############################################",
    "######..........XXXX..........###############",
    "####....oo..................oo......##########",
    "###........####.......####.........##########",
    "##....oo...####...oo..####....oo......#######",
    "##.........##..........##............oo....##",
    "#....###.........................###.......##",
    "#...####....oo.......oo.........oo...##.....##",
    "#.........#####.....................oo.....##",
    "#..oo.....#####.........####.......###.....##",
    "#.................oo....####....oo.........##",
    "#....####..................................##",
    "#...####....oo........oo.......oo....####...##",
    "#...........#####.............####.........##",
    "#....oo.....#####....oo.......####....oo....##",
    "WWWWWWWWWWWWWWWWWWW....WWWWWWWWWWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWWWWWWW....WWWWWWWWWWWWWWWWWWWWWWWW",
    "#..........####.....oo........####.........##",
    "#...oo.....####..............####....oo....##",
    "#..............oo.......oo.................##",
    "#....####.................oo.......####....##",
    "#...####....oo.......####...........###....##",
    "#...........####....####....oo.............##",
    "#....oo.....####............####....oo.....##",
    "#.......................####...............##",
    "#..####....oo.......oo.......oo....####.....##",
    "#..####.................###........####....##",
    "#..........oo.......oo...###...oo..........##",
    "##....###...............###...........###..##",
    "###........................................##",
    "#####...........P..............#############",
    "##############################################",
]

# ---------------------------------------------------------------------------
# NIVEAU 3 — VILLE : reseau de rues, blocs d'immeubles (#), voitures (o).
# Entree en bas (sortie de la foret), exfil = helipad au nord.
# Les avenues forment une grille ; les immeubles bloquent ; les voitures
# offrent de la couverture le long des rues.
# ---------------------------------------------------------------------------
CITY = [
    "##############################################",
    "##############XXXX############################",
    "##############....############################",
    "WWWWWWWWWWWWWW....WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWW....WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
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
    "########............P............############",
    "##############################################",
]

COL = {
    "wall_b": "#15171c", "floor_b": "#2b2f38",       # batiment (rappel niv.1)
    "tree":   "#1f3d22", "grass":  "#2f5a32", "rock": "#5c5247",   # foret
    "build":  "#3a3f4a", "asph":   "#22252b", "car":  "#b6863f",   # ville
    "water_f": "#2d5a7a", "water_c": "#27506e",       # eau (riviere / fleuve)
    "exit":   "#3fb36b", "player": "#e8e8e8", "obj": "#caa23a",
    "guard":  "#d23f3f", "patrol": "#e07a30",
}

# Gardes par niveau : (col, row, type)  type: 'A' arme, 'B' basique, 'R' renfort
FOREST_GUARDS = [
    (9, 29, "B"), (36, 29, "B"),       # entree des bois (bas)
    (6, 24, "A"), (40, 24, "A"),       # clairieres laterales
    (21, 19, "R"),                     # patrouille mobile, garde le pont
    (8, 11, "B"), (38, 11, "A"),       # rive nord apres le pont
    (6, 6, "A"), (38, 6, "A"),         # approche de l'exfil
    (20, 4, "B"),                      # zone d'extraction
]
CITY_GUARDS = [
    (12, 30, "B"), (33, 30, "B"),      # rue d'arrivee (bas)
    (6, 24, "A"), (40, 24, "A"),       # carrefours sud
    (21, 19, "R"),                     # patrouille avenue centrale
    (8, 15, "A"), (38, 15, "A"),       # avenue mediane
    (6, 10, "A"), (40, 10, "A"),       # waterfront
    (16, 5, "B"), (28, 5, "A"),        # checkpoint du pont vers l'helipad
]


def _norm(amap, w=46):
    """Aligne chaque ligne sur w colonnes (bord = mur)."""
    out = []
    for row in amap:
        if len(row) < w:
            row = row + "#" * (w - len(row))
        elif len(row) > w:
            row = row[:w - 1] + "#"
        out.append(row)
    return out


def connectivity_ok(amap):
    """BFS 4-connexe de P vers X ; # et W sont solides. Renvoie (ok, atteints)."""
    amap = _norm(amap)
    H = len(amap); W = len(amap[0])
    start = None; goals = set()
    for r in range(H):
        for c in range(W):
            if amap[r][c] == "P":
                start = (c, r)
            elif amap[r][c] == "X":
                goals.add((c, r))
    if start is None or not goals:
        return False, set()
    seen = {start}; queue = [start]
    while queue:
        c, r = queue.pop()
        for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (c + dc, r + dr)
            if 0 <= n[0] < W and 0 <= n[1] < H and n not in seen \
                    and amap[n[1]][n[0]] not in "#W":
                seen.add(n); queue.append(n)
    return bool(goals & seen), seen


def draw_map(ax, amap, title, theme, guards, helipad=False):
    amap = _norm(amap)
    H = len(amap); W = len(amap[0])
    if theme == "forest":
        wall_c, floor_c, cover_c, water_c = COL["tree"], COL["grass"], COL["rock"], COL["water_f"]
    else:
        wall_c, floor_c, cover_c, water_c = COL["build"], COL["asph"], COL["car"], COL["water_c"]
    ax.set_xlim(0, W); ax.set_ylim(0, H); ax.invert_yaxis()
    ax.set_aspect("equal"); ax.axis("off")
    ax.set_title(title, color="white", fontsize=15, fontweight="bold", pad=10)
    for r in range(H):
        for c in range(W):
            ch = amap[r][c]
            color = floor_c
            if ch == "#":
                color = wall_c
            elif ch == "W":
                color = water_c
            ax.add_patch(Rectangle((c, r), 1, 1, facecolor=color,
                         edgecolor="#1a1c20", linewidth=0.2))
    # couvertures + marqueurs
    for r in range(H):
        for c in range(W):
            ch = amap[r][c]
            if ch == "o":
                if theme == "forest":
                    ax.add_patch(Circle((c+0.5, r+0.5), 0.42, facecolor=cover_c,
                                 edgecolor="#2a2018", linewidth=0.5, zorder=4))
                else:
                    ax.add_patch(Rectangle((c+0.1, r+0.2), 0.8, 0.6, facecolor=cover_c,
                                 edgecolor="#5a3f18", linewidth=0.5, zorder=4))
            elif ch == "C":
                ax.add_patch(Rectangle((c-0.2, r-0.2), 1.4, 1.4, facecolor=COL["obj"],
                             edgecolor="#fff2c0", linewidth=1.2, zorder=5))
                ax.text(c+0.5, r+0.5, "COLIS", ha="center", va="center",
                        fontsize=5, color="#1a1a1a", fontweight="bold", zorder=6)
            elif ch == "X":
                ax.add_patch(Rectangle((c, r), 1, 1, facecolor=COL["exit"],
                             edgecolor="white", linewidth=0.8, zorder=5))
            elif ch == "P":
                ax.add_patch(Circle((c+0.5, r+0.5), 0.7, facecolor=COL["player"],
                             edgecolor="#2b6cd4", linewidth=1.6, zorder=6))
                ax.text(c+0.5, r+1.7, "ENTREE", ha="center", va="center",
                        fontsize=6, color="white", zorder=6)
    # libelle exfil
    xs = [(c, r) for r in range(H) for c in range(W) if amap[r][c] == "X"]
    if xs:
        cx = sum(c for c, r in xs) / len(xs) + 0.5
        cy = min(r for c, r in xs)
        ax.text(cx, cy - 0.8, "EXFIL ↑" if not helipad else "HELIPAD ↑",
                ha="center", va="center", fontsize=7, color="#9af0bb",
                fontweight="bold", zorder=6)
    # gardes
    for (c, r, t) in guards:
        col = {"A": COL["guard"], "B": COL["patrol"], "R": "#c03fd2"}[t]
        ax.add_patch(Circle((c+0.5, r+0.5), 0.6, facecolor=col,
                     edgecolor="black", linewidth=0.8, zorder=5))
        ax.text(c+0.5, r+0.5, t, ha="center", va="center", fontsize=5,
                color="white", fontweight="bold", zorder=6)


def render_level(fn, amap, title, theme, guards, helipad=False):
    ok, _ = connectivity_ok(amap)
    print("  connectivite P->X:", "OK" if ok else "*** BLOQUEE ***")
    fig, ax = plt.subplots(figsize=(11, 7.8), dpi=120)
    fig.patch.set_facecolor("#0c0d10")
    draw_map(ax, amap, title, theme, guards, helipad)
    items = [("Entree joueur", COL["player"]), ("Exfil/Helipad", COL["exit"]),
             ("Garde arme (A)", COL["guard"]), ("Patrouille (B)", COL["patrol"]),
             ("Renfort mobile (R)", "#c03fd2"),
             ("Eau", COL["water_c"] if theme == "city" else COL["water_f"]),
             ("Couverture", COL["car"] if theme == "city" else COL["rock"])]
    handles = [mpatches.Patch(facecolor=c, edgecolor="black", label=l) for l, c in items]
    leg = ax.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, -0.02),
                    ncol=7, fontsize=7, frameon=False)
    for t in leg.get_texts():
        t.set_color("white")
    plt.tight_layout()
    fig.savefig(fn, facecolor="#0c0d10", bbox_inches="tight")
    plt.close(fig)
    print("ecrit", fn)


def render_flow(fn):
    fig, ax = plt.subplots(figsize=(12, 3.4), dpi=120)
    fig.patch.set_facecolor("#0c0d10")
    ax.set_xlim(0, 12); ax.set_ylim(0, 3); ax.axis("off")
    blocks = [
        (0.4, "NIVEAU 1\nCentre de recherche", "#3a3f4a",
         "Voler les donnees\n(coffre) -> sortir"),
        (4.2, "NIVEAU 2\nForet", "#2f5a32",
         "Traverser les bois\nsans se faire prendre"),
        (8.0, "NIVEAU 3\nVille", "#22252b",
         "Rejoindre l'helipad\nd'exfiltration"),
    ]
    for x, label, color, sub in blocks:
        ax.add_patch(FancyArrow(0, 0, 0, 0))  # noop garde l'axe
        ax.add_patch(Rectangle((x, 1.0), 3.2, 1.4, facecolor=color,
                     edgecolor="white", linewidth=1.4))
        ax.text(x + 1.6, 1.95, label, ha="center", va="center", color="white",
                fontsize=11, fontweight="bold")
        ax.text(x + 1.6, 1.35, sub, ha="center", va="center", color="#cfd3da",
                fontsize=8)
    for x in [3.7, 7.5]:
        ax.annotate("", xy=(x + 0.45, 1.7), xytext=(x, 1.7),
                    arrowprops=dict(arrowstyle="-|>", color="#9af0bb", lw=2.5))
        ax.text(x + 0.22, 2.15, "sortie\n=entree", ha="center", va="center",
                color="#9af0bb", fontsize=6.5)
    ax.set_title("RUNAWAY — Campagne continue (monde ouvert) : la sortie d'un niveau "
                 "devient l'entree du suivant", color="white", fontsize=12,
                 fontweight="bold", pad=14)
    plt.tight_layout()
    fig.savefig(fn, facecolor="#0c0d10", bbox_inches="tight")
    plt.close(fig)
    print("ecrit", fn)


if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "mockups")
    os.makedirs(out, exist_ok=True)
    render_flow(os.path.join(out, "campaign_flow.png"))
    render_level(os.path.join(out, "level2_foret.png"), FOREST,
                 "Niveau 2 — Foret (traversee, entree bas -> exfil haut)",
                 "forest", FOREST_GUARDS)
    render_level(os.path.join(out, "level3_ville.png"), CITY,
                 "Niveau 3 — Ville (rejoindre l'helipad au nord)",
                 "city", CITY_GUARDS, helipad=True)
    print("OK")

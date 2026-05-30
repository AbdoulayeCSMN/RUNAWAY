# -*- coding: utf-8 -*-
"""Genere des apercus (vue de dessus) d'amenagements de salle pour validation.
Ne touche pas au jeu : sort des PNG dans tools/mockups/.
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle, FancyBboxPatch, Polygon
import matplotlib.patches as mpatches

MAP = [
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
]
H = len(MAP); W = len(MAP[0])

COL = {
    "floor": "#2b2f38", "wall": "#15171c", "grout": "#23262e",
    "desk": "#6b4a2b", "wood": "#7a5230", "metal": "#5a6470",
    "server": "#2f6f8f", "screen": "#34c0e0", "locker": "#3a4754",
    "crate": "#b6863f", "pallet": "#8a6a3a", "barrel": "#b8442e",
    "plant": "#3f8a3a", "tree": "#2e6e34", "rug": "#6d3b52",
    "sofa": "#445a78", "vehicle": "#c25b3a", "shelf": "#5b6470",
    "vault": "#caa23a", "table": "#7d6a52", "light": "#ffd98a",
    "laser": "#e0405e", "reception": "#7a8aa0", "pillar": "#3a3d45",
}

def base_ax(ax, title):
    ax.set_xlim(0, W); ax.set_ylim(0, H); ax.invert_yaxis()
    ax.set_aspect("equal"); ax.axis("off")
    ax.set_title(title, color="white", fontsize=15, fontweight="bold", pad=10)
    for r in range(H):
        for c in range(W):
            ch = MAP[r][c]
            color = COL["wall"] if ch == "#" else COL["floor"]
            ax.add_patch(Rectangle((c, r), 1, 1, facecolor=color,
                         edgecolor=COL["grout"], linewidth=0.3))
    # marqueurs jeu
    for r in range(H):
        for c in range(W):
            ch = MAP[r][c]
            if ch == "C":
                ax.add_patch(Rectangle((c-0.4, r-0.4), 1.8, 1.8, facecolor=COL["vault"],
                             edgecolor="#fff2c0", linewidth=1.4, zorder=5))
                ax.text(c+0.5, r+0.5, "COFFRE", ha="center", va="center",
                        fontsize=6, color="#1a1a1a", fontweight="bold", zorder=6)
            elif ch == "X":
                ax.add_patch(Rectangle((c, r), 2, 1, facecolor="#3fb36b",
                             edgecolor="white", linewidth=1, zorder=5))
                ax.text(c+1, r+0.5, "EXFIL", ha="center", va="center",
                        fontsize=6, color="white", fontweight="bold", zorder=6)
            elif ch == "P":
                ax.add_patch(Circle((c+0.5, r+0.5), 0.7, facecolor="#e8e8e8",
                             edgecolor="#2b6cd4", linewidth=1.6, zorder=5))
                ax.text(c+0.5, r+1.6, "JOUEUR", ha="center", va="center",
                        fontsize=6, color="white", zorder=6)

# --- primitives de mobilier (col,row = coin haut-gauche en cellules) ---
def rect(ax, c, r, w, h, kind, label=None, lw=0.6):
    ax.add_patch(FancyBboxPatch((c+0.08, r+0.08), w-0.16, h-0.16,
                 boxstyle="round,pad=0.02,rounding_size=0.12",
                 facecolor=COL[kind], edgecolor="#0d0f12", linewidth=lw, zorder=4))
    if label:
        ax.text(c+w/2, r+h/2, label, ha="center", va="center", fontsize=5.2,
                color="white", zorder=6)

def disk(ax, c, r, rad, kind, edge="#0d0f12"):
    ax.add_patch(Circle((c, r), rad, facecolor=COL[kind], edgecolor=edge,
                 linewidth=0.6, zorder=4))

def desk_with_pc(ax, c, r, horiz=True):
    if horiz:
        rect(ax, c, r, 3, 1.1, "desk")
        ax.add_patch(Rectangle((c+1.1, r+0.15), 0.8, 0.5, facecolor=COL["screen"],
                     edgecolor="#0d0f12", lw=0.5, zorder=5))
    else:
        rect(ax, c, r, 1.1, 3, "desk")
        ax.add_patch(Rectangle((c+0.15, r+1.1), 0.5, 0.8, facecolor=COL["screen"],
                     edgecolor="#0d0f12", lw=0.5, zorder=5))

def server_rack(ax, c, r):
    rect(ax, c, r, 1.6, 2.4, "server")
    for i in range(4):
        ax.add_patch(Rectangle((c+0.3, r+0.3+i*0.5), 1.0, 0.18,
                     facecolor=COL["screen"], lw=0, zorder=6))

def plant(ax, c, r, big=False):
    disk(ax, c+0.5, r+0.5, 0.6 if big else 0.42, "tree" if big else "plant",
         edge="#173a18")

def light_ring(ax, c, r, rad=2.2):
    ax.add_patch(Circle((c, r), rad, facecolor="#ffd98a", edgecolor="none",
                 alpha=0.10, zorder=2))

def crate(ax, c, r, n=1):
    for i in range(n):
        rect(ax, c+i*0.5, r+i*0.4, 1.1, 1.1, "crate")

def laser_pedestal(ax, c, r):
    disk(ax, c+0.5, r+0.5, 0.45, "laser", edge="#7a1020")

# =================== CONCEPT A : Centre de recherche / labo ==================
def concept_A(ax):
    base_ax(ax, "A — Centre de recherche high-tech")
    # Salle coffre (centre) : labo securise autour du coffre
    for (c, r) in [(20,8),(24,8),(20,14),(24,14)]:
        laser_pedestal(ax, c, r)
    light_ring(ax, 22.5, 11.5, 3.0)
    server_rack(ax, 17, 9); server_rack(ax, 27, 9)
    desk_with_pc(ax, 18, 15); desk_with_pc(ax, 26, 15)
    # Salle gauche-milieu : bureaux open-space
    desk_with_pc(ax, 3, 6); desk_with_pc(ax, 8, 6)
    desk_with_pc(ax, 3, 10, horiz=True); desk_with_pc(ax, 8, 10)
    rect(ax, 3, 13, 1.2, 3, "locker"); rect(ax, 5, 13, 1.2, 3, "locker")
    plant(ax, 12, 7); plant(ax, 2, 16)
    # Salle droite-milieu : salle serveurs
    server_rack(ax, 33, 7); server_rack(ax, 35, 7); server_rack(ax, 37, 7)
    server_rack(ax, 33, 13); server_rack(ax, 35, 13)
    plant(ax, 42, 7, big=True)
    # Hall milieu : salle de reunion
    rect(ax, 18, 19.5, 8, 2, "table", "Table reunion")
    for c in [17,19,21,23,25,27]:
        disk(ax, c+0.5, 19, 0.35, "metal"); disk(ax, c+0.5, 22, 0.35, "metal")
    plant(ax, 3, 20, big=True); plant(ax, 41, 20, big=True)
    # Entree : accueil + sieges
    rect(ax, 18, 25, 8, 1.4, "reception", "Accueil")
    rect(ax, 4, 25, 3, 1.6, "sofa"); rect(ax, 39, 25, 3, 1.6, "sofa")
    plant(ax, 2, 29, big=True); plant(ax, 43, 29, big=True)

# =================== CONCEPT B : Entrepot / hangar logistique ================
def concept_B(ax):
    base_ax(ax, "B — Entrepot / hangar logistique")
    # Salle coffre : zone de stockage de valeur, le coffre au milieu de palettes
    for c in [17,18,19]: crate(ax, c, 8)
    for c in [25,26,27]: crate(ax, c, 8)
    rect(ax, 17, 14, 2.4, 1.6, "pallet"); rect(ax, 26, 14, 2.4, 1.6, "pallet")
    light_ring(ax, 22.5, 11.5, 2.6)
    # Rayonnages gauche
    for r in [6,9,13,16]:
        rect(ax, 2, r, 11, 0.8, "shelf")
    crate(ax, 4, 7, 2); crate(ax, 9, 10, 2)
    # Rayonnages droite
    for r in [6,9,13,16]:
        rect(ax, 32, r, 11, 0.8, "shelf")
    crate(ax, 35, 10, 3)
    # Hall milieu : zone de tri + chariot
    rect(ax, 16, 19.5, 6, 2, "pallet"); crate(ax, 24, 19, 2)
    rect(ax, 30, 20, 2.4, 1.4, "vehicle", "Charriot")
    # Entree : quai de chargement, fourgon gare
    rect(ax, 16, 25.5, 6, 3, "vehicle", "Fourgon")
    rect(ax, 4, 25, 2.4, 2.4, "crate"); rect(ax, 40, 25, 2.4, 2.4, "crate")
    disk(ax, 8, 29, 0.5, "barrel"); disk(ax, 9.2, 29, 0.5, "barrel")
    disk(ax, 37, 29, 0.5, "barrel"); disk(ax, 38.2, 29, 0.5, "barrel")

# =================== CONCEPT C : Atrium d'entreprise luxueux =================
def concept_C(ax):
    base_ax(ax, "C — Atrium d'entreprise luxueux")
    # Salle coffre : showroom, coffre expose sur estrade + palmiers + spots
    ax.add_patch(Circle((22.5, 11.5), 3.4, facecolor=COL["rug"], alpha=0.5, zorder=2))
    light_ring(ax, 22.5, 11.5, 3.6)
    for (c,r) in [(18,8),(26,8),(18,15),(26,15)]:
        plant(ax, c, r, big=True)
    laser_pedestal(ax, 20, 11); laser_pedestal(ax, 24, 11)
    # Salle gauche : lounge avec canapes et tapis
    ax.add_patch(Rectangle((2.5, 6.5), 10, 9, facecolor=COL["rug"], alpha=0.35, zorder=2))
    rect(ax, 3, 7, 4, 1.4, "sofa"); rect(ax, 8, 7, 4, 1.4, "sofa")
    rect(ax, 3, 13, 4, 1.4, "sofa"); rect(ax, 5.5, 10, 4, 2, "table", "Table basse")
    plant(ax, 2, 16, big=True); plant(ax, 12, 6, big=True)
    # Salle droite : galerie d'exposition (piedestals)
    for (c,r) in [(33,7),(37,7),(41,7),(33,12),(37,12),(41,12),(35,15)]:
        disk(ax, c+0.5, r+0.5, 0.5, "reception", edge="#2a3340")
    plant(ax, 42, 16, big=True)
    # Hall : fontaine centrale + bancs + grandes plantes
    disk(ax, 22.5, 20.5, 1.6, "server", edge="#0d3a4a")
    disk(ax, 22.5, 20.5, 0.9, "screen")
    for c in [16,18,26,28]:
        rect(ax, c, 19, 1.6, 0.8, "sofa")
    plant(ax, 3, 20, big=True); plant(ax, 41, 20, big=True)
    # Entree : reception monumentale + alignement de palmiers
    rect(ax, 17, 25, 10, 1.6, "reception", "Reception")
    for c in [4, 8, 36, 40]:
        plant(ax, c, 28, big=True)
    rect(ax, 13, 28, 3, 1.6, "sofa"); rect(ax, 30, 28, 3, 1.6, "sofa")

def render(fn, concept_fn, name):
    fig, ax = plt.subplots(figsize=(11, 7.6), dpi=120)
    fig.patch.set_facecolor("#0c0d10")
    concept_fn(ax)
    # legende
    items = [("Coffre/Vault","vault"),("Bureau/PC","desk"),("Serveurs","server"),
             ("Casiers","locker"),("Caisses","crate"),("Etageres","shelf"),
             ("Canape","sofa"),("Plante/Arbre","tree"),("Vehicule","vehicle"),
             ("Reception","reception"),("Laser/secu","laser")]
    handles = [mpatches.Patch(facecolor=COL[k], edgecolor="black", label=l) for l,k in items]
    leg = ax.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, -0.02),
                    ncol=6, fontsize=7, frameon=False)
    for t in leg.get_texts(): t.set_color("white")
    plt.tight_layout()
    fig.savefig(fn, facecolor="#0c0d10", bbox_inches="tight")
    plt.close(fig)
    print("ecrit", fn)

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "mockups")
    os.makedirs(out, exist_ok=True)
    render(os.path.join(out, "concept_A_recherche.png"), concept_A, "A")
    render(os.path.join(out, "concept_B_entrepot.png"), concept_B, "B")
    render(os.path.join(out, "concept_C_atrium.png"), concept_C, "C")
    print("OK")

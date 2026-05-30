# -*- coding: utf-8 -*-
"""Apercu du niveau (Concept A) avec les VRAIES tuiles Kenney top-down-shooter.
Sort tools/mockups/conceptA_real.png. Ne touche pas au jeu.
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(__file__))
TILES = os.path.join(ROOT, "kenney_top-down-shooter", "PNG", "Tiles")
OUT = os.path.join(ROOT, "tools", "mockups")
os.makedirs(OUT, exist_ok=True)

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
CELL = 26  # px par cellule dans l'apercu

_cache = {}
def tile(n):
    if n not in _cache:
        _cache[n] = Image.open(os.path.join(TILES, f"tile_{n:02d}.png")).convert("RGBA")
    return _cache[n]

img = Image.new("RGBA", (W*CELL, H*CELL), (10, 11, 14, 255))

def paste(im, col, row, wc=1, hc=1, rot=0):
    t = im.resize((int(wc*CELL), int(hc*CELL)), Image.LANCZOS)
    if rot:
        t = t.rotate(rot, expand=True, resample=Image.BICUBIC)
    img.alpha_composite(t, (int(col*CELL), int(row*CELL)))

def place(n, col, row, wc=1, hc=1, rot=0):
    paste(tile(n), col, row, wc, hc, rot)

# --- sol + murs ---
FLOOR = 7    # carrelage gris
WALL_C = (24, 26, 31, 255)
for r in range(H):
    for c in range(W):
        ch = MAP[r][c]
        if ch == "#":
            ImageDraw.Draw(img).rectangle([c*CELL, r*CELL, c*CELL+CELL, r*CELL+CELL],
                                          fill=WALL_C)
        else:
            paste(tile(FLOOR), c, r)

# ============ MOBILIER CONCEPT A (cellules = col,row coin haut-gauche) ============
d0 = ImageDraw.Draw(img)
def server(col, row):
    x = col*CELL + int(CELL*0.18); y = row*CELL + int(CELL*0.10)
    w = int(CELL*0.64); h = int(CELL*1.8)
    d0.rectangle([x, y, x+w, y+h], fill=(23, 26, 33, 255))
    for i in range(7):
        ly = y + 5 + int(i*(h-10)/6)
        col_led = (51, 255, 153, 255) if i % 3 == 0 else (51, 204, 255, 255)
        d0.rectangle([x+4, ly, x+w-4, ly+2], fill=col_led)
def screen(col, row):
    cx = col*CELL + CELL//2; cy = row*CELL + CELL//2 - 3
    d0.rectangle([cx-7, cy-5, cx+7, cy+5], fill=(20, 23, 28, 255))
    d0.rectangle([cx-5, cy-3, cx+5, cy+3], fill=(64, 217, 255, 255))
def laser(col, row):
    cx = col*CELL + CELL//2; cy = row*CELL + CELL//2
    d0.ellipse([cx-4, cy-4, cx+4, cy+4], fill=(230, 51, 64, 255))

def workstation(col, row):
    place(453, col, row); screen(col, row); place(528, col, row+1)

# --- Salle coffre (centre) : tapis + serveurs aux coins + lasers ---
place(511, 20, 9, 4, 4)                 # grand tapis sous le coffre
for (c, r) in [(16, 8), (28, 8), (16, 15), (28, 15)]:
    server(c, r)
for (c, r) in [(19, 9), (25, 9), (19, 14), (25, 14)]:
    laser(c, r)

# --- Salle gauche : open-space bureaux + casiers ---
for (c, r) in [(3, 7), (6, 7), (9, 7), (3, 11), (6, 11), (9, 11)]:
    workstation(c, r)
for r in (14, 15, 16):
    place(503, 2, r)                    # casiers le long du mur

# --- Salle droite : salle serveurs (rangees) ---
for c in (33, 35, 37, 39):
    server(c, 7); server(c, 13)
workstation(41, 15)

# --- Hall milieu : salle de reunion ---
for c in range(18, 26):
    place(454, c, 20)                   # longue table
for c in range(18, 26, 2):
    place(528, c, 19); place(528, c, 21)
place(511, 30, 19, 3, 3)               # petit tapis

# --- Entree (bas) : reception + lounge ---
place(511, 17, 25, 10, 2)              # tapis d'accueil
for c in range(18, 26):
    place(538, c, 25)                   # comptoir reception
# canapes oranges (gauche)
place(474, 4, 26); place(475, 5, 26); place(476, 6, 26)
# canapes verts (droite)
place(447, 38, 26); place(448, 39, 26); place(449, 40, 26)

# --- Salle haut-droite : petit bureau ---
workstation(33, 2); workstation(36, 2)
for r in (1, 2, 3):
    place(503, 43, r)

# ============ marqueurs gameplay ============
d = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype("arialbd.ttf", 13)
    fsm = ImageFont.truetype("arial.ttf", 11)
except Exception:
    font = ImageFont.load_default(); fsm = font

for r in range(H):
    for c in range(W):
        ch = MAP[r][c]
        if ch == "C":
            d.rectangle([c*CELL-6, r*CELL-6, c*CELL+CELL+6, r*CELL+CELL+6],
                        fill=(202, 162, 58, 255), outline=(255, 242, 192, 255), width=2)
            d.text((c*CELL-4, r*CELL+4), "COFFRE", fill=(20, 20, 20, 255), font=fsm)
        elif ch == "X":
            d.rectangle([c*CELL, r*CELL, c*CELL+2*CELL, r*CELL+CELL],
                        fill=(63, 179, 107, 255), outline=(255, 255, 255, 255))
            d.text((c*CELL+4, r*CELL+5), "EXFIL", fill=(255, 255, 255, 255), font=fsm)
        elif ch == "P":
            cx, cy = c*CELL+CELL//2, r*CELL+CELL//2
            d.ellipse([cx-9, cy-9, cx+9, cy+9], fill=(232, 232, 232, 255),
                      outline=(43, 108, 212, 255), width=2)

# ambiance sombre + halos de lampes (comme en jeu)
dark = Image.new("RGBA", img.size, (12, 12, 28, 150))
img = Image.alpha_composite(img, dark)
glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
lamps = [(22, 11), (7, 11), (37, 11), (22, 20), (10, 27), (35, 27), (8, 2), (37, 2), (22, 3)]
for (c, r) in lamps:
    cx, cy = c*CELL, r*CELL
    for rad, a in [(150, 26), (100, 34), (55, 46)]:
        gd.ellipse([cx-rad, cy-rad, cx+rad, cy+rad], fill=(255, 217, 138, a))
img = Image.alpha_composite(img, glow)

d = ImageDraw.Draw(img)
d.text((10, 6), "Concept A — vrais assets Kenney (apercu)", fill=(255, 255, 255, 255), font=font)

img.convert("RGB").save(os.path.join(OUT, "conceptA_real.png"))
print("ecrit", os.path.join(OUT, "conceptA_real.png"))

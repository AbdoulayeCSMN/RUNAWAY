# -*- coding: utf-8 -*-
"""Genere les icones de lanceur Android a partir de l'identite visuelle du jeu
(cible rouge sur fond sombre, comme icon.svg). Sortie dans res://mobile_icons/.
Tailles : 192 (legacy), 512 (Play Store listing), 432 fg/bg (adaptive)."""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "mobile_icons")
os.makedirs(OUT, exist_ok=True)

BG = (13, 13, 18, 255)      # #0d0d12
RED = (192, 57, 43, 255)    # #c0392b


def draw_target(size, with_bg=True, transparent=False):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size / 128.0  # echelle depuis le viewBox 128 d'origine
    if with_bg:
        r = int(16 * s)
        d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=BG)
    cx = cy = size / 2.0
    sw = max(2, int(6 * s))        # epaisseur des traits
    ring_r = 34 * s
    # anneau exterieur
    d.ellipse([cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r],
              outline=RED, width=sw)
    # point central
    dot = 10 * s
    d.ellipse([cx - dot, cy - dot, cx + dot, cy + dot], fill=RED)
    # quatre graduations (haut/bas/gauche/droite)
    marks = [((cx, 14 * s), (cx, 34 * s)),
             ((cx, 94 * s), (cx, 114 * s)),
             ((14 * s, cy), (34 * s, cy)),
             ((94 * s, cy), (114 * s, cy))]
    for a, b in marks:
        d.line([a, b], fill=RED, width=sw)
    return img


def save(img, name):
    p = os.path.join(OUT, name)
    img.save(p)
    print("ecrit", os.path.normpath(p), img.size)


# Icone legacy carree (lanceur) + listing Play Store
save(draw_target(192, with_bg=True), "icon_192.png")
save(draw_target(512, with_bg=True), "icon_512.png")
# Adaptive : background plein + foreground transparent (la cible, recentree
# dans la zone de securite -> on dessine plus petit sur un canevas 432).
bg = Image.new("RGBA", (432, 432), BG)
save(bg, "icon_bg_432.png")
# foreground : cible centree a ~60% pour rester dans la safe-zone adaptive
fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
inner = draw_target(int(432 * 0.62), with_bg=False)
off = (432 - inner.size[0]) // 2
fg.paste(inner, (off, off), inner)
save(fg, "icon_fg_432.png")
print("OK")

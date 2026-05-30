#!/usr/bin/env python
"""Generate and validate the RUNAWAY level ASCII map.
Legend: # wall  . floor  o crate(cover)  P player  C coffre  X exit
Outputs GDScript-ready rows and runs a BFS reachability check.
"""
from collections import deque

W, H = 46, 32

# Start everything as wall, carve rooms/corridors.
grid = [['#' for _ in range(W)] for _ in range(H)]


def carve_rect(c0, r0, c1, r1):
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            if 0 <= r < H and 0 <= c < W:
                grid[r][c] = '.'


# --- Rooms ---
# Exfil room (top-left)  rows 1-4
carve_rect(1, 1, 14, 4)
# Top-right room rows 1-4
carve_rect(31, 1, 44, 4)
# Middle band: three rooms rows 6-17
carve_rect(1, 6, 14, 17)     # left room
carve_rect(16, 6, 29, 17)    # center room (coffre)
carve_rect(31, 6, 44, 17)    # right room
# Hall rows 19-23
carve_rect(1, 19, 44, 23)
# Entry room rows 25-30
carve_rect(1, 25, 44, 30)

# --- Corridors (width 2) ---
# vertical connectors between top rooms and middle rooms
carve_rect(6, 4, 7, 6)       # left exfil <-> left mid
carve_rect(36, 4, 37, 6)     # top-right <-> right mid
# top-center room access (center mid up to a small alcove) - connect center to top via col 22
carve_rect(21, 4, 22, 6)
# horizontal connectors between mid rooms
carve_rect(14, 10, 16, 11)   # left mid <-> center mid
carve_rect(29, 10, 31, 11)   # center mid <-> right mid
# mid rooms down to hall
carve_rect(6, 17, 7, 19)     # left mid -> hall
carve_rect(22, 17, 23, 19)   # center mid -> hall
carve_rect(38, 17, 39, 19)   # right mid -> hall
# hall down to entry
carve_rect(10, 23, 11, 25)
carve_rect(34, 23, 35, 25)

# --- Cover: pillars and crates ---
# pillars (walls) in big rooms
for (c, r) in [(5, 9), (10, 14), (20, 9), (25, 14), (35, 9), (40, 14),
               (22, 21), (12, 27), (33, 27)]:
    grid[r][c] = '#'
# crates (cover, destructible-ish blockers)
for (c, r) in [(4, 7), (12, 8), (18, 13), (27, 8), (33, 13), (42, 8),
               (8, 21), (38, 21), (20, 27), (25, 27), (6, 28), (40, 28)]:
    if grid[r][c] == '.':
        grid[r][c] = 'o'

# --- Markers ---
grid[1][1] = 'X'
grid[1][2] = 'X'
grid[11][22] = 'C'   # coffre center room
grid[28][22] = 'P'   # player entry


def neighbors(c, r):
    for dc, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        yield c + dc, r + dr


def find(ch):
    for r in range(H):
        for c in range(W):
            if grid[r][c] == ch:
                return c, r
    return None


# BFS from player over walkable (non-#) cells
pc = find('P')
seen = set([pc])
q = deque([pc])
while q:
    c, r = q.popleft()
    for nc, nr in neighbors(c, r):
        if 0 <= nc < W and 0 <= nr < H and (nc, nr) not in seen and grid[nr][nc] != '#':
            seen.add((nc, nr))
            q.append((nc, nr))

coffre = find('C')
exit1 = find('X')
print("Coffre reachable:", coffre in seen)
print("Exit reachable:", exit1 in seen)
print("Walkable cells reached:", len(seen))

# Emit GDScript rows
print("\nconst MAP := [")
for r in range(H):
    print('\t"' + ''.join(grid[r]) + '",')
print("]")

# --- Validate guard cells/patrol points are walkable ---
print("\n# Guard validation")
guards = [
    ("BASIC", (5,28), [(5,28),(40,28)]),
    ("BASIC", (40,26), [(40,26),(5,26)]),
    ("ALERT", (6,20), [(6,20),(40,20)]),
    ("BASIC", (6,10), [(6,10),(12,16),(6,16),(6,7)]),
    ("ARMED", (22,8),  [(22,8),(22,16)]),
    ("ALERT", (40,10), [(40,10),(33,16),(40,16),(40,7)]),
    ("BASIC", (8,2),   [(8,2),(13,2)]),
    ("ALERT", (38,2),  [(38,2),(33,2)]),
]
for typ, cell, pts in guards:
    c, r = cell
    ok = grid[r][c] != '#'
    pok = all(grid[pr][pc] != '#' for pc, pr in pts)
    reach = cell in seen
    print(f"{typ} cell={cell} floor={ok} reachable={reach} patrol_ok={pok} -> cells={[grid[pr][pc] for pc,pr in pts]}")

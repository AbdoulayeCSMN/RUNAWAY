# -*- coding: utf-8 -*-
import sys, docx
d = docx.Document(r"C:\Users\pc\Downloads\RUNAWAY_GDD_v3.docx")
for p in d.paragraphs:
    s = (p.style.name if p.style else "")
    t = p.text
    if t.strip() == "" and not s.startswith("Heading"):
        continue
    print(f"[{s}] {t}")
for i, tbl in enumerate(d.tables):
    print(f"--- TABLE {i} ---")
    for row in tbl.rows:
        print(" | ".join(c.text for c in row.cells))

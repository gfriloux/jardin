#!/usr/bin/env python3
"""Fabrique un fond de plan à partir du cadastre, en repère local métrique.

Pourquoi pas une capture d'écran : le cadastre est disponible en **vecteur**
via l'API carto de l'IGN. Pas de limite de zoom, pas de pixels, et surtout on
peut le faire pivoter — le nord en haut n'a aucune raison d'être le repère d'un
jardin.

Le SVG produit ne contient que des **mètres relatifs**. Les coordonnées réelles
n'y figurent pas : le plan est donc anonyme, et peut être publié sans révéler
où se trouve le terrain.

    ./tools/plan-parcelle.py --insee <insee> --section <section> --numero <numero> \
        --out docs/src/assets/plan/parcelle.svg
"""

import argparse
import json
import math
import urllib.request
from pathlib import Path

API = "https://apicarto.ign.fr/api/cadastre/parcelle"


def fetch(insee: str, section: str, numero: str) -> dict:
    url = f"{API}?code_insee={insee}&section={section}&numero={numero}"
    with urllib.request.urlopen(url, timeout=30) as r:
        data = json.load(r)
    if not data.get("features"):
        raise SystemExit(f"Parcelle introuvable : {section} {numero} sur {insee}")
    return data["features"][0]


def to_metres(ring):
    """Équirectangulaire autour du centroïde. À l'échelle d'une parcelle,
    l'erreur est inférieure au centimètre — bien en deçà de la précision du
    cadastre lui-même."""
    lat0 = sum(p[1] for p in ring) / len(ring)
    lon0 = sum(p[0] for p in ring) / len(ring)
    mx = 111320.0 * math.cos(math.radians(lat0))
    return [((p[0] - lon0) * mx, (p[1] - lat0) * 110540.0) for p in ring]


def longest_edge(pts):
    best, bi = 0.0, 0
    for i in range(len(pts)):
        a, b = pts[i], pts[(i + 1) % len(pts)]
        d = math.hypot(b[0] - a[0], b[1] - a[1])
        if d > best:
            best, bi = d, i
    return bi, best


def area(pts):
    n = len(pts)
    return abs(sum(pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1]
                   for i in range(n))) / 2


def build(feature, rotate: bool):
    geom = feature["geometry"]
    ring = geom["coordinates"][0][0] if geom["type"] == "MultiPolygon" else geom["coordinates"][0]
    pts = to_metres(ring)
    if pts and pts[0] == pts[-1]:
        pts = pts[:-1]

    theta = 0.0
    if rotate:
        i, _ = longest_edge(pts)
        a, b = pts[i], pts[(i + 1) % len(pts)]
        theta = -math.atan2(b[1] - a[1], b[0] - a[0])
        c, s = math.cos(theta), math.sin(theta)
        pts = [(x * c - y * s, x * s + y * c) for x, y in pts]

    ox, oy = min(p[0] for p in pts), min(p[1] for p in pts)
    pts = [(round(x - ox, 2), round(y - oy, 2)) for x, y in pts]
    return pts, math.degrees(theta) % 360


def svg(pts, rot_deg, label, margin=3.0, px=14.0):
    w = max(p[0] for p in pts) + 2 * margin
    h = max(p[1] for p in pts) + 2 * margin
    W, H = w * px, h * px

    def X(x): return (x + margin) * px
    def Y(y): return H - (y + margin) * px  # y vers le haut

    grid = []
    for gx in range(0, int(w) + 1):
        cls = "grid grid--major" if gx % 5 == 0 else "grid"
        grid.append(f'<line class="{cls}" x1="{X(gx-margin):.1f}" y1="0" '
                    f'x2="{X(gx-margin):.1f}" y2="{H:.1f}"/>')
    for gy in range(0, int(h) + 1):
        cls = "grid grid--major" if gy % 5 == 0 else "grid"
        grid.append(f'<line class="{cls}" x1="0" y1="{Y(gy-margin):.1f}" '
                    f'x2="{W:.1f}" y2="{Y(gy-margin):.1f}"/>')

    ticks = []
    for gx in range(0, int(max(p[0] for p in pts)) + 1, 5):
        ticks.append(f'<text class="tick" x="{X(gx):.1f}" y="{H-4:.1f}" '
                     f'text-anchor="middle">{gx}</text>')
    for gy in range(0, int(max(p[1] for p in pts)) + 1, 5):
        ticks.append(f'<text class="tick" x="6" y="{Y(gy)+4:.1f}">{gy}</text>')

    poly = " ".join(f"{X(x):.1f},{Y(y):.1f}" for x, y in pts)

    # Flèche du nord : il a tourné de rot_deg dans le repère local.
    nx, ny = W - 42, 42
    a = math.radians(rot_deg)
    dx, dy = 22 * math.sin(a), -22 * math.cos(a)

    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W:.0f} {H:.0f}"
     role="img" aria-label="{label}">
  <g class="grille">{''.join(grid)}</g>
  <polygon class="parcelle" points="{poly}"/>
  <g class="reperes">{''.join(ticks)}</g>
  <g class="nord" transform="translate({nx:.0f},{ny:.0f})">
    <line x1="0" y1="0" x2="{dx:.1f}" y2="{dy:.1f}"/>
    <circle cx="0" cy="0" r="2.5"/>
    <text x="{dx*1.5:.1f}" y="{dy*1.5+4:.1f}" text-anchor="middle">N</text>
  </g>
  <text class="echelle" x="8" y="16">graduations en mètres · repère local</text>
</svg>
'''


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--insee", required=True)
    ap.add_argument("--section", required=True)
    ap.add_argument("--numero", required=True, help="sur 4 chiffres, ex. 0175")
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--nord-en-haut", action="store_true",
                    help="ne pas aligner le repère sur la plus longue limite")
    args = ap.parse_args()

    feature = fetch(args.insee, args.section, args.numero)
    pts, rot = build(feature, rotate=not args.nord_en_haut)

    cadastre = feature["properties"].get("contenance")
    calc = area(pts)
    print(f"Parcelle {args.section} {args.numero} — {len(pts)} sommets")
    print(f"  emprise  {max(p[0] for p in pts):.1f} x {max(p[1] for p in pts):.1f} m")
    print(f"  surface  {calc:.0f} m2 calcules / {cadastre} m2 au cadastre")
    print(f"  rotation {rot:.1f} deg — le nord pointe dans cette direction")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(svg(pts, rot, f"Parcelle {args.section} {args.numero}"),
                        encoding="utf-8")
    print(f"  ecrit    {args.out}")


if __name__ == "__main__":
    main()

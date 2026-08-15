#!/usr/bin/env python3
"""Analyse un journal de mesure enregistré par `just fw-log`.

Comprend les deux formats produits par le firmware :

  04-sonde            soil-01  raw=2695  (~2.17 V)
  05-caracterisation  moy= 2681.1  ecart-type=  2.3  min=2663  max=2687 ...

Sur les séries de 05-caracterisation, l'écart-type est souvent **bimodal** :
des séries calmes à 1–5 points alternent avec des séries agitées à 9–18. Ce
n'est pas du bruit de capteur mais une perturbation périodique captée par le
câble. L'outil sépare les deux régimes plutôt que d'en faire une moyenne, qui
ne décrirait ni l'un ni l'autre.

Usage :
    tools/analyse-mesures.py mesures/20260815-173800-05-caracterisation-air.log
"""

import re
import statistics as st
import sys

RE_BRUT = re.compile(r"raw=\s*(\d+)")
RE_SERIE = re.compile(
    r"moy=\s*([\d.]+)\s+ecart-type=\s*([\d.]+)\s+min=\s*(\d+)\s+max=\s*(\d+)"
)

# Frontière entre série calme et série agitée, en points d'ADC. Choisie dans le
# creux du histogramme observé : les séries se répartissent nettement de part
# et d'autre, sans population intermédiaire.
SEUIL_AGITEE = 8.0


def bilan(nom, v, unite=""):
    if not v:
        return
    ligne = f"  {nom:22s} n={len(v):4d}  moy={st.mean(v):8.1f}{unite}"
    if len(v) > 1:
        ligne += f"  ecart-type={st.stdev(v):6.1f}"
    ligne += f"  min={min(v):7.1f}  max={max(v):7.1f}"
    print(ligne)


def analyse_brut(valeurs):
    print(f"\n=== {len(valeurs)} lectures brutes (04-sonde) ===\n")
    bilan("ensemble", valeurs)

    # Un saut de plus de 200 points sépare deux paliers : air, eau, sol.
    paliers, courant = [], [valeurs[0]]
    for a, b in zip(valeurs, valeurs[1:]):
        if abs(b - a) > 200:
            paliers.append(courant)
            courant = []
        courant.append(b)
    paliers.append(courant)

    retenus = [p for p in paliers if len(p) >= 10]
    if len(retenus) > 1:
        print(f"\n  {len(retenus)} paliers d'au moins 10 lectures :\n")
        for i, p in enumerate(retenus, 1):
            bilan(f"palier {i}", p)
        moyennes = [st.mean(p) for p in retenus]
        print(f"\n  amplitude entre paliers = {max(moyennes) - min(moyennes):.0f} points")


def analyse_series(series):
    moyennes = [s[0] for s in series]
    ecarts = [s[1] for s in series]
    print(f"\n=== {len(series)} séries de 100 mesures (05-caracterisation) ===\n")

    bilan("moyennes des séries", moyennes)
    print(
        f"  -> la moyenne est stable à {max(moyennes) - min(moyennes):.1f} points près "
        f"({(max(moyennes) - min(moyennes)) / st.mean(moyennes) * 100:.2f} %)"
    )

    calmes = [e for e in ecarts if e < SEUIL_AGITEE]
    agitees = [e for e in ecarts if e >= SEUIL_AGITEE]

    print(f"\n  écart-type intra-série, séparé en deux régimes :\n")
    bilan("séries calmes", calmes)
    bilan("séries agitées", agitees)
    part = len(agitees) / len(ecarts) * 100
    print(f"\n  {len(agitees)}/{len(ecarts)} séries agitées, soit {part:.0f} %")

    # Une dérive lente ne se voit pas série par série : on compare les deux
    # bouts du journal.
    if len(moyennes) >= 20:
        n = len(moyennes) // 10
        debut, fin = st.mean(moyennes[:n]), st.mean(moyennes[-n:])
        print(f"\n  dérive début -> fin = {fin - debut:+.1f} points "
              f"({(fin - debut) / debut * 100:+.2f} %)")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 1

    with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
        texte = f.read()

    series = [
        (float(m[0]), float(m[1]), int(m[2]), int(m[3]))
        for m in RE_SERIE.findall(texte)
    ]
    if series:
        analyse_series(series)

    # Les lignes de série contiennent min=/max= mais pas raw= : pas de collision.
    valeurs = [int(v) for v in RE_BRUT.findall(texte)]
    if valeurs:
        analyse_brut(valeurs)

    if not series and not valeurs:
        print("Aucune mesure reconnue dans ce fichier.")
        return 1
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())

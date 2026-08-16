#!/usr/bin/env python3
"""Volume d'un maillage STL, en mm³.

Le banc d'essai de la coque (`just coque-test`) intersecte des pièces et
demande que le résultat soit vide. « Le fichier existe » ne suffit pas comme
critère : quand on soustrait deux solides aux frontières confondues, CGAL rend
un maillage bavard — des milliers de triangles — dont le volume est nul. Un
test qui compte les facettes déclare alors un défaut là où il n'y en a pas.

C'est ce qui est arrivé au contrôle de retournement de la coquille arrière :
6472 triangles, 0,000000 mm³.

Lit l'ASCII comme le binaire, parce qu'OpenSCAD choisit selon sa version.
"""

import struct
import sys


def _triangles_ascii(data: bytes):
    sommets = []
    for ligne in data.decode("utf-8", "replace").splitlines():
        ligne = ligne.strip()
        if ligne.startswith("vertex"):
            _, x, y, z = ligne.split()
            sommets.append((float(x), float(y), float(z)))
            if len(sommets) == 3:
                yield tuple(sommets)
                sommets = []


def _triangles_binaire(data: bytes):
    (n,) = struct.unpack_from("<I", data, 80)
    for i in range(n):
        base = 84 + i * 50 + 12          # 12 : on saute la normale
        p = struct.unpack_from("<9f", data, base)
        yield (p[0:3], p[3:6], p[6:9])


def volume(chemin: str) -> float:
    with open(chemin, "rb") as f:
        data = f.read()
    if not data:
        return 0.0
    # Un STL binaire annonce son nombre de triangles à l'octet 80 ; si la
    # taille du fichier colle, c'est du binaire — l'en-tête peut commencer par
    # « solid » comme un fichier ASCII, donc on ne se fie pas au mot-clé.
    binaire = False
    if len(data) >= 84:
        (n,) = struct.unpack_from("<I", data, 80)
        binaire = len(data) == 84 + n * 50
    tris = _triangles_binaire(data) if binaire else _triangles_ascii(data)

    # Somme des volumes signés des tétraèdres (origine, a, b, c). Les faces
    # tournées vers l'intérieur comptent en négatif : le total est le volume
    # enfermé, quelle que soit la position de l'origine.
    v = 0.0
    for a, b, c in tris:
        v += (a[0] * (b[1] * c[2] - b[2] * c[1])
              - a[1] * (b[0] * c[2] - b[2] * c[0])
              + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
    return abs(v)


if __name__ == "__main__":
    # Le seuil est optionnel, et c'est lui qui porte le verdict : la
    # comparaison se fait ici plutôt que dans le justfile, faute de calcul
    # flottant en bash — et pour n'avoir qu'un seul endroit qui décide.
    if len(sys.argv) not in (2, 3):
        print("usage: volume-stl.py <fichier.stl> [seuil-mm3]", file=sys.stderr)
        sys.exit(2)
    v = volume(sys.argv[1])
    print("%.6f" % v)
    if len(sys.argv) == 3 and v > float(sys.argv[2]):
        sys.exit(1)

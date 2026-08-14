#!/usr/bin/env python3
"""Simule un ou plusieurs nœuds LoRa, pour éprouver la chaîne serveur sans matériel.

Le but n'est pas de jouer : c'est de **découpler les pannes**. Si toute la chaîne
serveur est prouvée avec des données synthétiques, alors le jour où le matériel
arrive, ce qui casse est forcément le matériel ou le firmware — on ne débogue
plus deux inconnues à la fois.

Deux formats de sortie, correspondant à deux points de la chaîne :

  --format gateway   ce que GATEWAY-001 crache sur sa liaison série.
                     Pas d'horodatage : le nœud n'a pas d'horloge.
  --format archive   ce que le collecteur écrit dans l'archive NDJSON,
                     horodatage compris. Sert à fabriquer un historique.

Deux destinations :

  --out pty          un pseudo-terminal, que le collecteur ouvre comme un vrai
                     port série. Avec --link, on obtient un chemin stable.
  --out stdout       pour tuyauter ou regarder.

Exemples
--------
Un port série virtuel, en temps réel accéléré :

    ./tools/simulateur-noeud.py --out pty --link /tmp/jardin-gateway --speed 60

Trois semaines d'historique dans l'archive, instantanément :

    ./tools/simulateur-noeud.py --format archive --duration 21 \\
        --archive-dir stack/data
"""

import argparse
import json
import math
import os
import pty
import random
import sys
import tty
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

# --------------------------------------------------------------------------
# Le modèle de sol
#
# On ne tire pas des nombres au hasard : une courbe plausible est ce qui permet
# de vérifier que les graphes, les seuils et la calibration ont du sens. Trois
# phénomènes suffisent à reproduire ce qu'on cherchera à observer en O8.
# --------------------------------------------------------------------------


class Sonde:
    """Une sonde capacitive, avec sa dérive propre.

    Deux sondes du même lot ne donnent pas la même valeur dans la même terre —
    c'est exactement ce que l'expérience de O3 doit découvrir. On le reproduit
    en donnant à chacune ses propres points sec et saturé.
    """

    def __init__(self, canal, profondeur_cm, rng, tau_h=None):
        self.canal = canal
        self.profondeur_cm = profondeur_cm

        # Dispersion inter-sondes : +/- 8 % sur chaque borne.
        self.sec = rng.gauss(2850, 2850 * 0.08)
        self.sature = rng.gauss(1250, 1250 * 0.08)
        self.bruit = rng.uniform(3.0, 9.0)

        # Une couche profonde sèche plus lentement et reçoit moins d'eau.
        profond = profondeur_cm >= 15
        self.tau_h = tau_h if tau_h else (rng.uniform(48, 72) if profond else rng.uniform(20, 32))
        self.part_arrosage = rng.uniform(0.25, 0.45) if profond else rng.uniform(0.75, 0.95)

        self.humidite = rng.uniform(0.35, 0.55)  # 0 = sec, 1 = saturé

    def secher(self, heures):
        """Décroissance exponentielle vers un plancher — le sol ne sèche jamais
        complètement à l'ombre des plants."""
        plancher = 0.08
        self.humidite = plancher + (self.humidite - plancher) * math.exp(-heures / self.tau_h)

    def arroser(self, quantite):
        self.humidite = min(1.0, self.humidite + quantite * self.part_arrosage)

    def lire(self, instant, rng):
        """Valeur brute d'ADC. Elle DESCEND quand l'humidité monte."""
        brut = self.sec - self.humidite * (self.sec - self.sature)

        # Effet thermique : une sonde capacitive est sensible à la température,
        # et l'écart jour/nuit peut atteindre l'ordre de grandeur du signal
        # qu'on cherche. C'est la raison d'être de la sonde de température.
        heure = instant.hour + instant.minute / 60
        brut += 12.0 * math.sin((heure - 9) / 24 * 2 * math.pi)

        return max(0, min(4095, int(round(brut + rng.gauss(0, self.bruit)))))


class Noeud:
    def __init__(self, uid, sondes, rng):
        self.uid = uid
        self.sondes = sondes
        self.seq = rng.randint(0, 50)
        self.batterie = rng.uniform(4.7, 4.95)
        self.rng = rng

    def avancer(self, heures, instant):
        for s in self.sondes:
            s.secher(heures)
        # Décharge lente, avec un léger creux nocturne.
        self.batterie -= 0.0012 * heures
        self.seq += 1

    def arroser(self, quantite):
        for s in self.sondes:
            s.arroser(quantite)

    def trame(self, instant):
        return {
            "node": self.uid,
            "seq": self.seq,
            "battery": round(self.batterie + self.rng.gauss(0, 0.01), 2),
            "sensors": {s.canal: s.lire(instant, self.rng) for s in self.sondes},
        }


# --------------------------------------------------------------------------
# Scénario par défaut : celui du POC.
# --------------------------------------------------------------------------


def scenario_defaut(rng):
    return [
        Noeud(
            "NODE-001",
            [
                Sonde("soil-01", 10, rng),
                Sonde("soil-02", 10, rng),
                Sonde("soil-03", 20, rng),
            ],
            rng,
        )
    ]


def parse_noeuds(spec, rng):
    """`NODE-001:soil-01@10,soil-02@10,soil-03@20`"""
    noeuds = []
    for bloc in spec.split(";"):
        uid, _, canaux = bloc.partition(":")
        sondes = []
        for c in canaux.split(","):
            nom, _, prof = c.partition("@")
            sondes.append(Sonde(nom.strip(), int(prof) if prof else 10, rng))
        noeuds.append(Noeud(uid.strip(), sondes, rng))
    return noeuds


# --------------------------------------------------------------------------
# Émission
# --------------------------------------------------------------------------

# Bruit de démarrage d'une vraie carte : le collecteur doit le traverser sans
# broncher. C'est le genre de ligne qui fait planter un parseur naïf.
PARASITES = [
    "ets Jul 29 2019 12:21:46",
    "rst:0x1 (POWERON_RESET),boot:0x8 (SPI_FAST_FLASH_BOOT)",
    "SPIWP:0xee",
    "=== GATEWAY-001 ready ===",
    "E (412) SX1262: timeout waiting for BUSY",
    "",
]


def ligne_gateway(trame, rng):
    """Ce que la passerelle écrit : la trame du nœud, plus la qualité du lien.

    rssi et snr sont produits par la PASSERELLE, pas par le nœud : ce sont des
    propriétés de la réception. D'où l'imbrication — elle survivra au jour où la
    trame deviendra binaire ou signée.
    """
    return {
        "rssi": int(round(rng.gauss(-92, 6))),
        "snr": round(rng.gauss(8.0, 2.5), 1),
        "frame": trame,
    }


def main():
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--out", choices=["pty", "stdout"], default="stdout")
    p.add_argument("--link", type=Path, help="lien symbolique stable vers le pty")
    p.add_argument("--format", choices=["gateway", "archive"], default="gateway")
    p.add_argument("--archive-dir", type=Path,
                   help="écrit dans <dir>/AAAA-MM/NODE-XXX.ndjson (implique --format archive)")
    p.add_argument("--nodes", help="NODE-001:soil-01@10,soil-02@20;NODE-002:soil-01@10")
    p.add_argument("--interval", type=float, default=300, help="secondes simulées entre trames")
    p.add_argument("--speed", type=float, default=1.0,
                   help="facteur d'accélération. 0 = aussi vite que possible")
    p.add_argument("--duration", type=float, default=0, help="jours simulés, 0 = sans fin")
    p.add_argument("--start", help="instant simulé de départ, ISO 8601")
    p.add_argument("--loss", type=float, default=0.03, help="fraction de trames perdues")
    p.add_argument("--garbage", type=float, default=0.01, help="fraction de lignes parasites")
    p.add_argument("--reboot-every", type=int, default=0,
                   help="redémarre le nœud toutes les N trames (seq repart à 0)")
    p.add_argument("--seed", type=int, default=None)
    args = p.parse_args()

    rng = random.Random(args.seed)
    noeuds = parse_noeuds(args.nodes, rng) if args.nodes else scenario_defaut(rng)

    if args.archive_dir:
        args.format = "archive"

    # ---- destination ----
    fichiers = {}
    maitre = None
    if args.archive_dir:
        def ecrire(noeud_uid, texte, instant):
            rep = args.archive_dir / instant.strftime("%Y-%m")
            rep.mkdir(parents=True, exist_ok=True)
            f = fichiers.get((rep, noeud_uid))
            if f is None:
                f = open(rep / f"{noeud_uid}.ndjson", "a", encoding="utf-8")
                fichiers[(rep, noeud_uid)] = f
            f.write(texte + "\n")
    elif args.out == "pty":
        maitre, esclave = pty.openpty()
        # Mode brut : sans ça, le pty retraduit les fins de ligne et double les
        # retours chariot. Un vrai port série ne fait pas ce traitement, et on
        # veut que le collecteur voie exactement ce que la carte enverrait.
        tty.setraw(esclave)
        chemin = os.ttyname(esclave)
        if args.link:
            if args.link.is_symlink() or args.link.exists():
                args.link.unlink()
            args.link.symlink_to(chemin)
            chemin = f"{args.link} -> {chemin}"
        print(f"port série simulé : {chemin}", file=sys.stderr, flush=True)

        def ecrire(noeud_uid, texte, instant):
            os.write(maitre, (texte + "\r\n").encode())
    else:
        def ecrire(noeud_uid, texte, instant):
            sys.stdout.write(texte + "\n")
            sys.stdout.flush()

    # ---- horloge simulée ----
    if args.start:
        instant = datetime.fromisoformat(args.start)
        if instant.tzinfo is None:
            instant = instant.replace(tzinfo=timezone.utc)
    elif args.duration:
        instant = datetime.now(timezone.utc) - timedelta(days=args.duration)
    else:
        instant = datetime.now(timezone.utc)

    fin = instant + timedelta(days=args.duration) if args.duration else None
    pas_h = args.interval / 3600.0
    prochain_arrosage = instant + timedelta(hours=rng.uniform(24, 72))
    emises = 0

    try:
        while fin is None or instant < fin:
            for n in noeuds:
                n.avancer(pas_h, instant)

            if instant >= prochain_arrosage:
                quantite = rng.uniform(0.45, 0.85)
                for n in noeuds:
                    n.arroser(quantite)
                print(f"  arrosage a {instant:%Y-%m-%d %H:%M} (+{quantite:.2f})",
                      file=sys.stderr, flush=True)
                prochain_arrosage = instant + timedelta(hours=rng.uniform(48, 96))

            for n in noeuds:
                if args.reboot_every and n.seq and n.seq % args.reboot_every == 0:
                    n.seq = 0
                    print(f"  redemarrage de {n.uid} a {instant:%Y-%m-%d %H:%M}",
                          file=sys.stderr, flush=True)

                # Les parasites n'existent que sur la liaison série. Le
                # collecteur ne les recopie pas dans l'archive : celle-ci ne
                # contient que des trames valides, une par ligne.
                if args.format == "gateway" and rng.random() < args.garbage:
                    ecrire(n.uid, rng.choice(PARASITES), instant)

                if rng.random() < args.loss:
                    continue  # trame perdue : un trou dans seq

                ligne = ligne_gateway(n.trame(instant), rng)
                if args.format == "archive":
                    ligne = {"received_at": instant.isoformat().replace("+00:00", "Z"),
                             **ligne}
                ecrire(n.uid, json.dumps(ligne, ensure_ascii=False), instant)
                emises += 1

            instant += timedelta(seconds=args.interval)
            if args.speed and args.out == "pty":
                time.sleep(args.interval / args.speed)
            elif args.speed and not args.archive_dir:
                time.sleep(args.interval / args.speed)
    except KeyboardInterrupt:
        pass
    finally:
        for f in fichiers.values():
            f.close()
        if maitre is not None:
            os.close(maitre)
        if args.link and args.link.is_symlink():
            args.link.unlink()

    print(f"{emises} trames emises jusqu'a {instant:%Y-%m-%d %H:%M}",
          file=sys.stderr, flush=True)


if __name__ == "__main__":
    main()

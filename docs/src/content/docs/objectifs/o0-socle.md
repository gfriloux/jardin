---
title: O0 — Socle projet
description: Dépôt, environnement de développement reproductible, documentation.
sidebar:
  order: 0
  badge:
    text: Tenu
    variant: success
---

**La question.** Où vit le code, comment on le construit, et où on documente ?

**Critère de sortie.** `nix develop` donne un shell contenant tout l'outillage,
et `npm run build` dans `docs/` produit un site.

## Ce qui a été fait

### Le dépôt

```text
jardin/
├── flake.nix          environnement de développement
├── justfile           tâches courantes
├── docs/              cette documentation (Astro + Starlight)
├── firmware/          PlatformIO, ESP32-S3 — les croquis de O1
├── stack/             compose.yaml — MariaDB, Grafana, collecteur
└── collector/         Rust — série → archive → MariaDB
```

### Le devshell

Un `flake.nix` unique fournit les trois chaînes d'outils du projet, pour
qu'aucune reprise ne commence par une demi-journée d'installation :

| Outil | Pour quoi |
|---|---|
| `just` | les tâches courantes, décrites dans le `justfile` |
| `nodejs_22` | la documentation Astro |
| `platformio`, `esptool`, `picocom` | le firmware ESP32-S3 |
| `cargo`, `rustc`, `clippy`, `rustfmt`, `rust-analyzer`, `pkg-config`, `udev` | le collecteur Rust |
| `openscad` | la [coque des sondes](/materiel/coque-des-sondes/) |
| `python3` | les outils de `tools/` — fond de plan, simulateur |
| `mosquitto`, `jq` | outillage d'appoint |

```console
$ nix develop
jardin — devshell. Tâches disponibles : just --list
```

`udev` est là parce que la crate `serialport` s'y lie via `pkg-config` — c'est
le genre de détail qui coûte vingt minutes quand on le découvre au mauvais
moment.

Deux subtilités NixOS méritent d'être notées, parce qu'elles bloquent net :

- **`platformio` et non `platformio-core`.** PlatformIO télécharge ses propres
  compilateurs, liés dynamiquement pour une distribution classique ; sous NixOS
  ils refusent de démarrer. Le paquet `platformio` de nixpkgs est un
  environnement FHS (bwrap) dans lequel ils fonctionnent. C'est aussi ce que
  recommande le [wiki NixOS](https://wiki.nixos.org/wiki/Platformio), qui
  renvoie vers un flake tiers — inutile ici, nixpkgs suffit.
- **L'accès aux ports série demande une modification système**, la seule du
  projet : `services.udev.packages = [ pkgs.platformio-core.udev ];` et
  l'utilisateur dans le groupe `dialout`. Le flake réexporte ces règles en
  `packages.<system>.udev-rules`. **Fait le 13 août 2026.** Ces règles mettent
  le port en `0666` et surtout empêchent ModemManager de le sonder — détail dans
  [O1](/objectifs/o1-une-sonde/#la-seule-chose-qui-demande-sudo).

### Tout est épinglé

Une reprise dans six mois doit reconstruire à l'identique, sinon le devshell ne
sert à rien. Chaque chaîne d'outils a donc son verrou :

| Quoi | Verrou |
|---|---|
| nixpkgs | `flake.lock` |
| documentation | `docs/package-lock.json` |
| collecteur | `collector/Cargo.lock` |
| images de la stack | tags explicites dans `compose.yaml` |
| **firmware** | `firmware/platformio.ini` lui-même |

Le dernier est le piège : **PlatformIO n'a pas de fichier de verrouillage**. Un
`platform = espressif32` sans version saute silencieusement à la suivante dès
qu'Espressif publie, emportant le cœur Arduino et toute la chaîne de
compilation. Sur une carte qui est déjà un clone au brochage incertain, un
croquis qui cesse de fonctionner après une montée de version invisible
enverrait soupçonner le matériel.

### Les tâches

Un `justfile` à la racine porte les commandes courantes, pour qu'aucune ne soit
à retrouver dans un historique de shell :

| Tâche | Effet |
|---|---|
| `just dev` | serveur de développement de la doc |
| `just build` | site statique dans `docs/dist` |
| `just preview` | sert le site construit |
| `just check` | typage et références de contenu Astro |
| `just links` | liens internes et ancres du site construit |
| `just ci` | les trois précédentes, à passer avant de committer |
| `just clean` | supprime `dist/` et les caches Astro |
| `just flake-check`, `just flake-update`, `just fmt` | côté Nix |

Côté stack serveur :

| Tâche | Effet |
|---|---|
| `just stack-up` | MariaDB + Grafana, sur `http://localhost:3000` |
| `just stack-up-collector` | idem, plus le collecteur et l'importeur |
| `just db` | un shell SQL sur la base |
| `just db-wiring` | quelle sonde est branchée où, en ce moment |
| `just db-reset` | recrée l'index — **jamais** l'archive |
| `just coque-stl` | régénère les STL de la coque depuis le `.scad` |
| `just sim-serie` | un port série virtuel, sans matériel |
| `just sim-archive 21` | trois semaines d'historique synthétique |
| `just col-check` | tests et clippy du collecteur |
| `just col-import` | importe l'archive dans la base |

Et côté firmware :

| Tâche | Effet |
|---|---|
| `just fw-list` | les croquis disponibles, dans l'ordre où les faire |
| `just fw-ports` | les cartes détectées sur les ports USB |
| `just fw 01-blink` | compile, téléverse et ouvre le moniteur série |
| `just fw-build 03-radio` | compile seulement |
| `just fw-monitor 04-sonde` | moniteur série seul |
| `just fw-check` | compile tous les croquis, sans carte branchée |
| `just fw-clean` | supprime les objets de compilation |

`just links` mérite un mot : Starlight ne vérifie pas les liens internes, et une
page renommée casse silencieusement tout ce qui pointait dessus. Le script
`docs/scripts/check-links.mjs` relit le site construit et valide à la fois les
chemins et les ancres.

Les tâches `collector/` s'ajouteront quand ce répertoire existera.

### La documentation

Astro + Starlight, en français, avec rendu Mermaid côté client (un petit plugin
remark transforme les blocs ` ```mermaid ` en `<pre class="mermaid">`, et un
script rend les diagrammes en suivant le thème clair/sombre).

## Le principe qui en découle

Un objectif n'est pas tenu tant que sa page n'est pas écrite. La documentation
n'est pas le compte rendu du travail, elle en fait partie — sur un projet
saisonnier, avec des interruptions de plusieurs semaines, c'est la seule chose
qui empêche de tout reperdre.

## Ce qui reste ouvert

- **Publication du site.** Pas encore décidé : GitHub Pages demanderait de
  configurer `site` et `base` dans `astro.config.mjs`. Tant que la doc n'est
  lue que localement, ça n'a pas d'intérêt.
- **Publication de la doc** et **dépôt distant** restent à décider.

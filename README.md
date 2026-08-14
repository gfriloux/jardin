# jardin

Réseau de télémétrie du terrain : sondes d'humidité du sol, LoRa, et à terme
irrigation automatisée.

La documentation complète — contexte, feuille de route, inventaire matériel,
décisions d'architecture — vit dans `docs/`.

## Démarrer

```console
$ nix develop
$ just dev          # la doc sur http://localhost:4321
```

`just` seul liste les tâches disponibles : `build`, `preview`, `check`,
`links` (liens et ancres internes), `ci` (les trois), `clean`, plus les
tâches Nix `flake-check`, `flake-update` et `fmt`.

## Structure

```text
jardin/
├── flake.nix          environnement de développement (Node, PlatformIO, Rust, mosquitto)
├── justfile           tâches courantes
├── docs/              documentation (Astro + Starlight)
├── firmware/          ESP32-S3 + SX1262 — les croquis de l'objectif O1
├── stack/             compose.yaml — broker MQTT, Home Assistant, collecteur
└── collector/         à venir — daemon Rust, GATEWAY série → MQTT
```

## État

`O0` tenu : dépôt, devshell, documentation. Le matériel du POC arrive les
15 et 16 août 2026. Voir la feuille de route dans la documentation.

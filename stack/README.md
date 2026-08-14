# Stack serveur

`mosquitto` + `home-assistant` + le collecteur, en conteneurs. Le but est
qu'elle tourne à l'identique sur le poste de développement, sur un Raspberry Pi
ou sur une machine NixOS — voir la décision ADR-011 dans la documentation.

```console
$ just stack-up                # mosquitto + Home Assistant
$ just mqtt-watch              # regarder passer les mesures
$ just stack-down
```

Home Assistant écoute ensuite sur http://localhost:8123.

## Le port série, dans un conteneur

Le collecteur lit la passerelle LoRa branchée en USB. Deux précautions.

**1. Un nom de périphérique stable.** `/dev/ttyUSB0` devient `/dev/ttyUSB1` au
premier rebranchement, et le conteneur refuse alors de démarrer. Une règle udev
donne à la carte un nom fixe :

```nix
# configuration.nix
services.udev.extraRules = ''
  SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", \
    SYMLINK+="jardin-gateway"
'';
```

Si les deux cartes sont branchées en même temps, elles partagent le même couple
VID/PID : il faut alors discriminer sur le numéro de série, visible avec

```console
$ udevadm info -a -n /dev/ttyUSB0 | grep -i serial
```

**2. `devices:` et non `privileged:`.** Le `compose.yaml` monte uniquement le
périphérique nécessaire. Donner `privileged: true` à un conteneur pour un accès
série est inutile et donne au conteneur bien plus que ce qu'il demande.

## Où vivent les données

| Quoi | Où |
|---|---|
| Configuration et historique Home Assistant | volume `homeassistant-config` |
| Persistance du broker | volume `mosquitto-data` |
| **Archive brute des mesures** | `stack/data/`, en clair sur l'hôte |

L'archive NDJSON est délibérément **hors volume Docker** : c'est la source de
vérité pour l'analyse de calibration, et elle doit rester lisible, sauvegardable
et survivable à un `docker compose down -v`.

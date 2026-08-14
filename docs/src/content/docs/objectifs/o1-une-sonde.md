---
title: O1 — Une sonde, une valeur
description: Tutoriel pas à pas — de la carte dans son sachet à une valeur d'humidité qui défile à l'écran.
sidebar:
  order: 1
  badge:
    text: Matériel attendu
    variant: caution
---

**La question.** Est-ce qu'une sonde donne une valeur stable et plausible ?

**Critère de sortie.** Une sonde branchée sur la carte, un nombre qui défile
sur l'ordinateur, et une variation nette et reproductible entre l'air libre et
un verre d'eau.

**Dépend de.** [O0](/objectifs/o0-socle/) · **Débloque.**
[O2](/objectifs/o2-multiplexage/) et [O4](/objectifs/o4-lien-radio/)

Cette page est un **tutoriel**. Elle se suit dans l'ordre, du sachet non ouvert
jusqu'à la première mesure. Chaque étape a un résultat visible : si tu ne le
vois pas, ne passe pas à la suivante.

## Le vocabulaire, une fois pour toutes

Sept mots reviennent partout. Ils ne sont pas difficiles, ils sont juste
jamais expliqués.

| Mot | Ce que c'est |
|---|---|
| **La carte** | Le rectangle de circuit imprimé, ici le Heemol / Heltec V3. Il porte le microcontrôleur, la radio, un écran et une prise USB. |
| **OLED** | Le petit écran noir de 1,5 cm collé sur la carte, celui qui affiche du texte blanc. OLED est juste la technologie d'affichage. Il n'a aucun rôle dans le projet final — il sert à voir si la carte va bien sans avoir à la brancher à l'ordinateur. |
| **GPIO** | Une des pattes métalliques sur les bords de la carte, numérotée. « GPIO 7 » = la patte n° 7. C'est là qu'on branche les fils. |
| **ADC** | Le circuit qui transforme une tension électrique en nombre. Chez nous : 0 V devient 0, et 3,3 V devient 4095. C'est lui qui « lit » la sonde. |
| **Un croquis** (*sketch*) | Un petit programme qu'on met dans la carte. Elle n'en exécute qu'un seul à la fois, et il redémarre à chaque mise sous tension. |
| **Téléverser** (*flash*) | Envoyer un croquis dans la carte par le câble USB. Ça remplace le précédent. |
| **Le moniteur série** | Une fenêtre de texte sur l'ordinateur, qui affiche ce que la carte raconte par le câble USB. C'est le seul moyen de savoir ce qu'elle fait. |

Un dernier, propre à cette carte : **`Vext`** est la patte qui met l'écran sous
tension. Particularité déroutante, elle est **active à l'état bas** : il faut
lui écrire `LOW` (0) pour *allumer*. C'est courant en électronique, et c'est la
cause n° 1 des « mon écran reste noir ».

## Ce qu'il te faut sur la table

- 1 carte Heemol / Heltec V3 **avec son antenne**
- 1 câble USB-C
- 1 sonde capacitive
- 1 breadboard
- 3 straps Dupont mâle-femelle

Le multiplexeur, la deuxième carte et la powerbank ne servent **pas** ici.

## Étape 0 — Préparer l'ordinateur

Tu n'as rien à installer à la main : tout est déjà déclaré dans le `flake.nix`.

```console
$ cd ~/Apps/github/gfriloux/jardin
$ nix develop
jardin — devshell. Tâches disponibles : just --list
```

Cette commande te donne **PlatformIO** (qui compile et téléverse les croquis),
`esptool` et `picocom`. Tu peux vérifier :

```console
$ pio --version
PlatformIO Core, version 6.1.19
```

:::caution[Pourquoi `platformio` et pas `platformio-core`]
PlatformIO télécharge lui-même ses compilateurs (`xtensa-esp32s3-elf-g++`),
qui sont des binaires liés dynamiquement pour une distribution classique. Sous
NixOS, ils refusent de démarrer :

```text
Could not start dynamically linked executable: xtensa-esp32s3-elf-g++
NixOS cannot run dynamically linked executables intended for generic
linux environments out of the box.
```

Le flake utilise donc `pkgs.platformio`, qui est un environnement FHS (bwrap)
dans lequel ces binaires fonctionnent, et non `pkgs.platformio-core`. Rien à
faire de ton côté, mais c'est bon à savoir le jour où tu voudras compiler
depuis un autre dossier.
:::

### La seule chose qui demande sudo

C'est la seule modification système du projet. **Faite le 13 août 2026.**

```nix
{
  # Règles d'accès aux cartes de développement
  services.udev.packages = [ pkgs.platformio-core.udev ];

  # Accès aux ports série
  users.users.kuri.extraGroups = [ "dialout" ];
}
```

puis `nixos-rebuild switch`.

Ce que fait réellement la règle installée, pour une carte à puce CP210x comme
la nôtre (`10c4:ea60`) :

```text
ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea[67][013]", MODE:="0666",
  ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_PORT_IGNORE}="1"
```

Deux effets, et le second est le plus important :

- **`MODE:="0666"`** rend le port accessible à tout le monde. L'appartenance au
  groupe `dialout` n'est donc pas nécessaire pour cette carte — elle reste utile
  comme filet pour du matériel non couvert par les règles, et devient active à
  la prochaine connexion de session.
- **`ID_MM_DEVICE_IGNORE`** interdit à **ModemManager** de sonder le port. Sans
  ça, il l'ouvre au branchement de l'ESP32 et fait échouer un téléversement sur
  deux, avec un message d'erreur qui n'évoque jamais ModemManager. C'est un
  grand classique, et une cause de perte de temps considérable.

:::tip
Le flake réexporte ces règles, si tu préfères les tirer du projet plutôt que
de nixpkgs :

```nix
services.udev.packages = [ inputs.jardin.packages.x86_64-linux.udev-rules ];
```
:::

Contournement à chaud, si jamais un port reste inaccessible :
`sudo chmod 666 /dev/ttyUSB0`. Ça marche, ça ne survit pas au débranchement.

## Étape 1 — Sortir la carte et visser l'antenne

:::danger[À faire avant toute mise sous tension]
**Visse l'antenne sur le connecteur de la carte avant de brancher l'USB.**

La puce radio SX1262, si elle émet sans antenne, renvoie sa puissance dans son
propre étage de sortie et se détruit. C'est le moyen le plus rapide de perdre
une carte neuve, et ça vaut même pour un simple test d'écran : tu ne contrôles
pas ce que fait le firmware d'usine au démarrage.

Prends l'habitude sur les deux cartes, tout de suite.
:::

Branche ensuite le câble USB-C entre la carte et l'ordinateur. L'écran affiche
probablement quelque chose (le firmware d'usine), et une petite LED s'allume.

Vérifie que l'ordinateur voit la carte :

```console
$ just fw-ports
/dev/ttyUSB0
----------
Hardware ID: USB VID:PID=10C4:EA60 ...
Description: CP2102N USB to UART Bridge Controller
```

Le nom peut être `/dev/ttyUSB0` ou `/dev/ttyACM0`. La puce d'interface de cette
carte est une CP210x, gérée nativement par le noyau Linux — aucun pilote à
installer.

**Si rien n'apparaît :** essaie un autre câble USB. Beaucoup de câbles vendus
avec des téléphones ne transportent que le courant, pas les données. C'est de
loin la cause la plus fréquente.

## Étape 2 — Faire clignoter la LED

On ne cherche pas à faire clignoter une LED. On cherche à prouver que la chaîne
complète fonctionne : PlatformIO compile, le téléversement passe, la carte
démarre, et elle nous parle. Tant que ça ne marche pas, rien d'autre ne peut
marcher.

```console
$ just fw 01-blink
```

Cette commande compile le croquis, l'envoie dans la carte, puis ouvre le
moniteur série. **La première fois, elle télécharge le compilateur ESP32 : compte
plusieurs minutes et quelques centaines de Mo.** Les fois suivantes, c'est
quinze secondes.

Ce que tu dois voir :

```text
=== 01-blink ===
Si tu lis cette ligne, la chaine compilation -> televersement
-> moniteur serie fonctionne. La LED doit clignoter.
LED allumee
LED eteinte
LED allumee
```

et la LED blanche de la carte qui clignote une fois par seconde.

Pour quitter le moniteur série : `Ctrl-C`.

:::note[Si le téléversement échoue]
Certaines cartes ESP32-S3 demandent d'entrer manuellement en mode
téléversement : maintiens le bouton **`PRG`** (ou `BOOT`) enfoncé, appuie
brièvement sur **`RST`**, puis relâche `PRG`. Relance ensuite la commande.
:::

## Étape 3 — L'écran

Premier vrai test du brochage. Ce croquis vérifie que `Vext` (GPIO 36) et le bus
de l'écran (SDA 17, SCL 18, RST 21) sont bien là où la documentation Heltec V3
les annonce — ce qui n'est pas garanti sur un clone.

```console
$ just fw 02-oled
```

Tu dois lire sur le petit écran :

```text
JARDIN
O1 - ecran OK
brochage Heltec V3
confirme
```

**Si l'écran reste noir**, le clone ne suit pas le brochage Heltec V3. Ce n'est
pas grave, mais il faut le découvrir maintenant et pas dans trois semaines :
cherche la fiche du vendeur, corrige `firmware/include/board.h` — **tout le
brochage est centralisé là, et nulle part ailleurs** — et note l'écart dans
[les risques](/materiel/risques/#les-cartes-sont-des-clones-pas-des-heltec).

## Étape 4 — La radio

Même logique, pour le bus SPI qui relie le microcontrôleur à la puce radio.
Ce croquis appelle `begin()` et s'arrête là : **il n'émet rien**. L'émission a
ses propres contraintes et c'est le sujet de [O4](/objectifs/o4-lien-radio/).

```console
$ just fw 03-radio
```

Résultat attendu :

```text
=== 03-radio ===
SX1262 OK : le bus SPI repond et la radio s'initialise.
Frequence : 868.10 MHz
Aucune emission : c'est le sujet de O4.
```

Un code d'erreur `-1` signifie que la puce ne répond pas du tout, ce qui trahit
presque toujours un brochage SPI faux. Même correctif : `board.h`.

:::tip[À ce stade, la carte est validée]
Écran et radio répondent : le brochage de `board.h` est confirmé, et les
objectifs suivants peuvent s'appuyer dessus. C'est le vrai livrable des étapes
2 à 4.
:::

## Étape 5 — Brancher la sonde

Débranche l'USB avant de câbler.

La sonde a trois fils. Les couleurs varient, mais les inscriptions sur la
petite carte de la sonde sont fiables :

| Fil de la sonde | Va sur | Rôle |
|---|---|---|
| `VCC` (ou `+`) | broche **3V3** de la carte | alimentation |
| `GND` (ou `-`) | broche **GND** de la carte | masse |
| `AOUT` (ou `A0`, `SIG`) | **GPIO 7** | la mesure |

<figure class="schema">
<svg viewBox="0 0 640 300" role="img" aria-labelledby="cablage-o1-titre">
  <title id="cablage-o1-titre">Câblage de la sonde d'humidité sur la carte ESP32-S3 : VCC vers 3V3, GND vers GND, AOUT vers GPIO 7</title>

  <!-- Sonde -->
  <rect x="20" y="40" width="120" height="70" rx="6" class="boitier"/>
  <text x="80" y="30" class="titre" text-anchor="middle">sonde</text>
  <circle cx="140" cy="60" r="4" class="pastille"/>
  <circle cx="140" cy="80" r="4" class="pastille"/>
  <circle cx="140" cy="100" r="4" class="pastille"/>
  <text x="128" y="64" class="etiq" text-anchor="end">VCC</text>
  <text x="128" y="84" class="etiq" text-anchor="end">GND</text>
  <text x="128" y="104" class="etiq" text-anchor="end">AOUT</text>

  <!-- Lame -->
  <path d="M60 110 L60 260 Q80 275 100 260 L100 110 Z" class="lame"/>
  <line x1="60" y1="185" x2="100" y2="185" class="trait-grad"/>
  <text x="110" y="189" class="note">trait de graduation</text>
  <text x="110" y="205" class="note">— ne jamais immerger au-delà</text>
  <text x="80" y="292" class="note" text-anchor="middle">partie plantée dans la terre</text>

  <!-- Carte -->
  <rect x="470" y="40" width="150" height="180" rx="6" class="boitier"/>
  <text x="545" y="30" class="titre" text-anchor="middle">carte ESP32-S3</text>
  <rect x="490" y="55" width="70" height="30" rx="3" class="ecran"/>
  <text x="525" y="75" class="mini" text-anchor="middle">OLED</text>
  <circle cx="600" cy="60" r="7" class="antenne"/>
  <text x="600" y="82" class="mini" text-anchor="middle">ant.</text>
  <circle cx="470" cy="120" r="4" class="pastille"/>
  <circle cx="470" cy="150" r="4" class="pastille"/>
  <circle cx="470" cy="180" r="4" class="pastille"/>
  <text x="482" y="124" class="etiq">3V3</text>
  <text x="482" y="154" class="etiq">GND</text>
  <text x="482" y="184" class="etiq">GPIO 7</text>

  <!-- Breadboard -->
  <rect x="230" y="70" width="170" height="120" rx="4" class="breadboard"/>
  <text x="315" y="60" class="titre" text-anchor="middle">breadboard</text>
  <g class="trous">
    <line x1="245" y1="85" x2="385" y2="85"/>
    <line x1="245" y1="105" x2="385" y2="105"/>
    <line x1="245" y1="125" x2="385" y2="125"/>
    <line x1="245" y1="155" x2="385" y2="155"/>
    <line x1="245" y1="175" x2="385" y2="175"/>
  </g>

  <!-- Fils -->
  <path d="M140 60 C 190 60, 190 85, 245 85 L385 85 C 430 85, 430 120, 470 120" class="fil rouge"/>
  <path d="M140 80 C 195 80, 195 105, 245 105 L385 105 C 432 105, 432 150, 470 150" class="fil noir"/>
  <path d="M140 100 C 200 100, 200 125, 245 125 L385 125 C 434 125, 434 180, 470 180" class="fil jaune"/>

  <text x="315" y="215" class="note" text-anchor="middle">rouge = 3V3 · noir = GND · jaune = mesure</text>
</svg>
</figure>

Pourquoi GPIO 7 et pas un autre. Heltec documente les broches utilisables pour
du matériel externe sur la V3 :

```text
GPIO 1  2  4  5  6  7        →  ADC1
GPIO 19 20                   →  ADC2
GPIO 47 48                   →  pas d'ADC
```

La lecture doit se faire sur **ADC1**, parce qu'ADC2 est réquisitionné dès que
le Wi-Fi s'active. Dans cette liste, GPIO 1 sert déjà à la mesure de batterie.
Restent 2, 4, 5, 6 et 7 — on prend 7 pour la mesure et 6 pour l'alimentation de
l'étape 8.

À ne surtout pas utiliser : les broches de strapping (la carte ne démarre plus),
GPIO 21 (reset de l'écran), GPIO 43 et 44 (USB série), GPIO 39 à 42 (JTAG).

La breadboard sert simplement à ne pas enficher les straps directement dans les
trous de la carte. Les deux longues rangées latérales sont reliées entre elles
sur toute leur longueur : c'est là qu'on distribue le 3V3 et le GND.

## Étape 6 — Lire la valeur

```console
$ just fw 04-sonde
```

```text
=== 04-sonde ===
valeur brute de l'ADC, de 0 a 4095
soil-01  raw=2847  (~2.29 V)
soil-01  raw=2851  (~2.30 V)
soil-01  raw=2845  (~2.29 V)
```

C'est la première mesure du projet.

Ce nombre n'est **pas** une humidité, et on ne le convertira pas en
pourcentage — c'est la [décision ADR-002](/decisions/#adr-002--on-stocke-la-valeur-adc-brute),
et c'est ce qui permettra de recalculer tout l'historique le jour où la
calibration changera.

Sens de variation attendu : la valeur **descend quand l'humidité monte**. Sonde
en l'air = valeur haute. Sonde dans l'eau = valeur basse.

## Étape 7 — Caractériser la sonde

Trois états, quelques minutes chacun, tout noté.

```console
$ just fw 05-caracterisation
```

Ce croquis prend 100 mesures d'affilée et en sort la moyenne, l'écart-type et
l'étendue :

```text
moy= 2846.3  ecart-type=  4.2  min=2838  max=2857  etendue=  19
```

| État | Comment | Ce qu'on note |
|---|---|---|
| Air libre | sonde posée, sèche | la valeur haute de référence |
| Chiffon humide | enroulé autour de la lame | la réactivité |
| Verre d'eau | jusqu'au **trait de graduation**, pas au-delà | la valeur basse de référence |

:::caution
Ne plonge jamais la sonde au-delà du trait imprimé sur la lame. La partie haute
porte l'électronique et n'est pas étanche.
:::

**L'écart entre air et eau est la dynamique utile de la sonde.** S'il est
faible — disons moins de 500 points sur 4095 — la sonde ne distinguera jamais
deux états de sol, dont les variations sont bien plus subtiles que « air »
contre « eau ». Ce serait une conclusion importante, et une raison de changer
de sonde avant d'aller plus loin.

**L'écart-type, sonde immobile,** dit combien de mesures il faudra moyenner par
la suite. À 4 points d'écart-type, une seule lecture suffit. À 80, il faudra en
moyenner plusieurs dizaines.

## Étape 8 — N'alimenter la sonde que pendant la mesure

Dernier croquis. Le câblage change sur un seul point :

| Fil de la sonde | Va maintenant sur |
|---|---|
| `VCC` | **GPIO 6** (et non plus 3V3) |

La carte alimente donc elle-même la sonde, et peut la couper. Une sonde
capacitive tire environ 5 mA, très en dessous des 40 mA qu'un GPIO d'ESP32 peut
fournir : pas besoin de transistor à ce stade.

```console
$ just fw 06-alim-a-la-demande
```

```text
--- alimentation ON ---
t=   312 us  raw= 512
t= 20489 us  raw=2103
t= 40712 us  raw=2790
t= 60902 us  raw=2841
t= 81120 us  raw=2846
t=101338 us  raw=2846
```

Ce qu'on cherche : **à partir de quel instant la valeur cesse de bouger**. Dans
l'exemple ci-dessus, environ 60 ms. C'est ce délai qui sera inscrit dans le
firmware du nœud.

Deux raisons de faire ça, et aucune n'est le confort : la consommation, qui
décidera de l'autonomie ([O6](/objectifs/o6-autonomie/)), et le fait de ne pas
laisser une sonde électriquement active en permanence dans la terre.

## Ce qu'on note avant de clore O1

À reporter dans la section « Résultats » ci-dessous :

- [ ] Le brochage `board.h` est-il confirmé, ou corrigé — et où ?
- [ ] Valeur moyenne dans l'air
- [ ] Valeur moyenne dans l'eau
- [ ] Dynamique utile (l'écart entre les deux)
- [ ] Écart-type sonde immobile
- [ ] Délai de stabilisation après mise sous tension
- [ ] La sortie reste-t-elle sous 3,1 V, ou sature-t-elle l'ADC ?

## Questions ouvertes

- Quelle est la dynamique réelle air ↔ eau de ces sondes à 2 € ?
- Combien d'échantillons faut-il moyenner pour un bruit acceptable ?
- Quel délai de stabilisation après mise sous tension ?
- La sortie est-elle vraiment dans 0–3 V, ou dépasse-t-elle la plage de l'ADC ?

## Résultats

*À remplir une fois le matériel reçu.*

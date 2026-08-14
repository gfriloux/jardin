---
title: O4 — Le lien radio
description: Une trame LoRa qui part du fond du jardin et arrive sur le PC.
sidebar:
  order: 4
---

**La question.** Est-ce que LoRa porte correctement depuis le jardin, et avec
quelle fiabilité ?

**Critère de sortie.** Cent trames émises depuis le point le plus éloigné du
terrain, un taux de réception mesuré, et un RSSI/SNR relevé à chaque position
testée.

**Dépend de.** [O1](/objectifs/o1-une-sonde/) seulement — pas besoin du
multiplexeur ni de la calibration. C'est la branche qui peut avancer si le
CD74HC4067 tarde.

**Débloque.** [O5](/objectifs/o5-chaine-de-donnees/)

## Le montage

```text
                       LoRa 868 MHz
┌────────────────┐                ┌──────────────────┐
│    NODE-001    │  ────────────> │   GATEWAY-001    │
│                │                │                  │
│ ESP32-S3       │                │ ESP32-S3         │
│ SX1262         │                │ SX1262           │
│                │                │ USB              │
│ S1 (S2 S3)     │                └────────┬─────────┘
└────────────────┘                         │
                                           │ USB série
                                           ▼
                                          PC
```

Deux cartes identiques, deux firmwares différents. `GATEWAY-001` ne fait qu'une
chose : recevoir une trame et l'écrire sur la liaison série, en y ajoutant le
RSSI et le SNR.

## Les paramètres à figer

Ces valeurs deviennent des constantes du firmware, pas des réglages :

| Paramètre | Valeur de départ | Pourquoi |
|---|---|---|
| Fréquence | **868,1 MHz** | La carte est vendue 863–928 MHz : le défaut du module peut être hors bande européenne, il faut l'imposer |
| Bande passante | 125 kHz | Compromis standard |
| Facteur d'étalement | SF7 pour commencer | On monte vers SF9/SF12 **seulement si** la portée ne suffit pas |
| Coding rate | 4/5 | |
| Puissance | 14 dBm | Maximum légal courant en EU868 |
| Période minimale d'émission | ≥ 60 s | Garde-fou logiciel |

:::caution[Rapport cyclique]
La bande 863–870 MHz impose environ **1 %** de rapport cyclique sur la plupart
des sous-bandes : une trame de 100 ms interdit de réémettre pendant 10 s. Une
boucle de test qui émet en continu est illégale — et donnera en plus des
résultats de portée non représentatifs, la radio chauffant.

Le garde-fou logiciel qui refuse d'émettre trop tôt fait partie du livrable de
cet objectif, pas d'un « durcissement plus tard ».
:::

Le facteur d'étalement est le levier principal : monter de SF7 à SF12 multiplie
la portée, mais aussi le temps d'antenne (donc la consommation, et le délai
imposé par le rapport cyclique). On commence bas et on ne monte que sur preuve.

## La campagne de portée

Le test qui compte ne se fait pas sur la table.

```text
maison ────── 10 m ────── 30 m ────── fond du jardin ────── au-delà
   │            │            │              │                  │
 RSSI ?       RSSI ?       RSSI ?         RSSI ?             RSSI ?
```

À chaque position : cent trames à intervalle régulier, et on note le nombre
reçues, le RSSI moyen et le SNR moyen. Il faut tester **avec les obstacles
réels** — murs, végétation dense, dénivelé — parce que c'est là que ça se joue,
pas en ligne de vue dégagée.

Un chiffre à garder en tête : le SNR est plus informatif que le RSSI. LoRa
décode sous le plancher de bruit, et un SNR qui s'effondre annonce la perte de
lien bien avant que le RSSI ne semble mauvais.

## La trame

Format lisible pour le POC — voir
[le modèle de données](/projet/modele-de-donnees/#la-trame-radio) :

```json
{ "node": "NODE-001", "seq": 182, "battery": 4.87,
  "sensors": { "soil-01": 623 } }
```

Le champ `seq` est ce qui rend la campagne de portée mesurable : c'est en
comptant les trous dans la séquence qu'on obtient le taux de perte réel.

## Questions ouvertes

- Quelle portée réelle à SF7, avec les obstacles du terrain ?
- Faut-il monter en facteur d'étalement, et à quel coût en temps d'antenne ?
- L'antenne fournie avec la carte est-elle utilisable, ou faut-il en acheter
  une correcte ?
- La trame JSON tient-elle dans la charge utile maximale à SF12 (51 octets) ?
- Le lien est-il stable dans le temps, ou dégradé par la végétation qui pousse
  et par la pluie ?

## Résultats

*À remplir.*

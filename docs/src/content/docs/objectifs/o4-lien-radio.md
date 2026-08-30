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

:::note[Critère ramené au besoin réel]
Il a été tenu à **15 m**, distance qui couvre l'ensemble des plants à surveiller
aujourd'hui — et non au point le plus éloigné du terrain, qui n'intéresse
personne tant que rien n'y pousse. La marge mesurée est telle que la question ne
se reposera qu'en cas d'extension de la zone : voir les [résultats](#résultats).
:::

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

## Les deux croquis

`08-node-emission` et `09-gateway-reception`. Ils s'écrivent et se compilent
sans carte branchée — `just fw-check` les couvre comme les huit autres.

**Le nœud** lit la sonde, lit sa batterie, compose la trame et l'émet. Il
affiche aussi sur la liaison série ce qu'il vient d'émettre : le croquis se
teste donc seul, sans la passerelle, en regardant défiler le moniteur.

**La passerelle** reçoit, ajoute le RSSI et le SNR, écrit une ligne. Elle
n'interprète pas la charge utile — elle l'insère telle quelle dans son
enveloppe, exactement comme le collecteur recopie sans comprendre. Le jour où
le nœud ajoute un champ, il traverse intact.

:::tip[Toute la chaîne aval existe déjà, et a déjà tourné]
La ligne que la passerelle produit n'est pas inventée pour l'occasion :

```json
{"rssi":-90,"snr":5.4,"frame":{"node":"NODE-001","seq":48,"battery":4.81,"sensors":{"soil-01":2121}}}
```

C'est le format que `tools/simulateur-noeud.py` produit depuis
[O0](/objectifs/o0-socle/) et que `collector/` consomme. Archive NDJSON, base,
Grafana : tout a déjà tourné dessus. La passerelle n'a qu'à parler la même
langue, et rien en dessous ne bouge.

Un test du collecteur vérifie **octet pour octet** la ligne que produit le
`Serial.printf` de la passerelle. Si quelqu'un touche à l'un des deux formats,
ça casse là, et pas au fond du jardin.
:::

### Le garde-fou de rapport cyclique

Il est **calculé, pas deviné**. RadioLib sait dire le temps d'antenne exact
d'une charge utile donnée ; le nœud attend cent fois ça, pour le 1 % de la
bande. Le plancher de 60 s s'applique par-dessus, parce qu'à SF7 une petite
trame autoriserait de réémettre toutes les douze secondes — légal, mais inutile
pour un sol qui bouge à l'échelle de l'heure.

Le nœud affiche les trois chiffres à chaque tour, ce qui rend le garde-fou
vérifiable au lieu d'être promis :

```text
temps d'antenne 140 ms -> attente legale 14000 ms, retenue 14000 ms
```

L'ordre de grandeur est confirmé par la campagne, dont l'intervalle constaté
tourne autour de 14 s. Le chiffre exact est celui qu'affiche le nœud, sur sa
propre liaison série — la passerelle ne le voit pas.

:::caution[Le plancher est abaissé pendant la campagne, et doit être remis]
Mesurer un taux de perte demande cent trames par position. À 60 s l'une, cela
fait **1 h 40 par position** — une journée entière pour cinq positions, ce qui
condamne la campagne avant qu'elle commence.

`PERIODE_PLANCHER_MS` est donc passé de 60000 à **10000** le temps de la
campagne : le calcul légal reprend la main (~14 s constatés) et une position se
mesure en vingt minutes. Le plancher n'est pas mis à zéro pour autant — il reste
un filet contre un `getTimeOnAir()` qui renverrait 0, cas où le nœud émettrait
en continu, illégalement, sans que rien ne le signale.

**À remettre à 60000 une fois la campagne close.** Le commentaire du fichier le
rappelle.
:::

### La taille de trame, tranchée avant d'aller marcher

Une des questions ouvertes ci-dessous se règle à la calculette :

| Trame | Octets | SF7–SF9 | SF10–SF12 |
|---|---|---|---|
| 1 sonde | 70 | ✅ | ❌ (51 max) |
| 3 sondes | 100 | ✅ | ❌ |

La campagne démarre à SF7, donc rien ne bloque. Mais **si la portée oblige à
monter au-delà de SF9, le JSON en clair devra céder la place à un format
compact** — et il vaut mieux le savoir avant la campagne que pendant.

### Le premier essai, dans l'ordre qui isole les pannes

Trois étapes, chacune ne pouvant échouer que pour une raison :

```console
$ just fw 03-radio                # sur NODE-001 : le bus SPI répond-il ?
$ just fw 09-gateway-reception    # sur GATEWAY-001, qu'on laisse branchée
$ just fw 08-node-emission        # sur NODE-001
```

:::danger[Une seule carte branchée en USB à la fois]
C'est le premier objectif où deux cartes existent, et le premier où le port se
choisit tout seul. `_fw-port` fait `ls /dev/ttyUSB* /dev/ttyACM* | head -1` :
avec les deux cartes branchées, il prend **la première venue**, sans le dire.

Le téléversement réussit, annonce `SUCCESS`, et le firmware part sur la mauvaise
carte. On se retrouve avec deux passerelles, ou deux nœuds, et un lien
silencieux dont rien n'explique le silence.

Débrancher l'une avant de flasher l'autre. La séquence ci-dessus se lit donc :
flasher, débrancher, flasher, rebrancher.
:::

Une fois la passerelle validée, la lancer avec `just fw-log` et non `just fw` :
le moniteur simple n'écrit nulle part, et le tampon du terminal aura tronqué le
début de la campagne bien avant sa fin.

```console
$ just fw-log 09-gateway-reception campagne-portee
```

Un dernier essai à courte distance, nœud déjà sur batterie et dans une autre
pièce, avant de marcher : il coûte une minute et distingue « pas de portée » de
« deux cartes mal accordées », qui se ressemblent beaucoup vu du fond du jardin.

Une ligne JSON doit alors apparaître sur le moniteur de la passerelle. Si rien
n'arrive, **comparer les six paramètres radio en tête des deux croquis avant de
soupçonner la portée ou l'antenne** : deux cartes mal accordées restent muettes
l'une pour l'autre sans qu'aucune ne signale d'erreur, et c'est le mode de panne
le plus coûteux à diagnostiquer.

:::danger[Antenne clipsée sur les deux cartes, avant toute mise sous tension]
`08-node-emission` est le premier croquis du projet qui **émet vraiment** —
`03-radio` s'arrêtait volontairement au réveil de la puce. Un SX1262 qui émet
sans antenne se détruit.
:::

:::caution[La tension de batterie est du conditionnel]
GPIO 37 pour le pont diviseur, GPIO 1 pour lire, rapport 4,9 : trois valeurs
venues de la documentation Heltec, jamais vérifiées sur notre clone. Si le
chiffre émis est absurde, le premier suspect est la **polarité** de
`PIN_BAT_CTRL`, le second le rapport du pont.

C'est [O6](/objectifs/o6-autonomie/) qui tranchera, l'autonomie étant son
sujet. Ici la valeur ne sert qu'à remplir le champ `battery` de la trame.
:::

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

:::note[…mais seulement près de la limite]
Cette règle ne vaut que dans le régime où elle a un sens. **Le SX1262 ne
rapporte guère de SNR au-delà de +13 dB** : au-dessus, il sature et la valeur
cesse de dire autre chose que « très au-dessus du bruit ».

Les relevés de la première campagne sont tous entre +11,2 et +13,5 dB, collés à
ce plafond. C'est donc le **RSSI** qui y porte l'information, et le SNR qui ne
dit rien — l'inverse exact de la règle ci-dessus. Elle reprend ses droits quand
le lien commence à décrocher, pas avant.
:::

Le dépouillement compte les **`seq` distincts**, pas les lignes du journal :
compter les lignes gonflerait le taux de réception, éventuellement au-delà de
100 %.

Ce n'est pas une précaution théorique. **`seq:0` est arrivé en double dans les
deux journaux du 30 août**, à chaque mise sous tension du nœud — donc
systématiquement, pas par accident. Le mécanisme n'est pas établi ; l'hypothèse
la plus simple est que le premier `transmit()` rend un code d'erreur alors que
la trame est bien partie : `seq` n'est alors pas incrémenté et la trame suivante
repart avec le même numéro. Le nœud imprime `echec d'emission` dans ce cas, ce
qui trancherait — mais sa liaison série n'était pas enregistrée.

À vérifier en branchant les deux cartes sur deux terminaux, avant de compter sur
`seq` pour un taux de perte fin.

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

- ✅ **Quelle portée réelle à SF7, avec les obstacles du terrain ?** 15 m sans
  aucune perte, avec 60 dB de marge.
- ✅ **Faut-il monter en facteur d'étalement ?** Non. La marge rend la question
  sans objet, et le coût en temps d'antenne serait payé pour rien.
- ✅ **L'antenne fournie est-elle utilisable ?** Oui, telle quelle.
- ✅ **La trame JSON tient-elle à SF12 (51 octets) ?** Sans objet : on reste à
  SF7, où les 71 octets passent. La question ne se reposerait qu'en cas de
  montée en SF, elle-même écartée.
- ⬜ **Le nœud au ras du sol porte-t-il aussi bien ?** La campagne a été menée
  avec le nœud à portée de main, pas dans sa coque au sol comme le prévoit
  [O7](/objectifs/o7-mise-au-jardin/). La proximité du sol coûte facilement 10 à
  20 dB — que la marge absorbe *a priori*, mais ça se mesure.
- ⬜ **Le lien est-il stable dans le temps**, ou dégradé par la végétation qui
  pousse et par la pluie ? Une campagne d'un jour ne peut pas y répondre ; c'est
  un sujet de [O7](/objectifs/o7-mise-au-jardin/).

## Résultats

**Campagne du 30 août 2026**, une position à environ **15 m**, obstacles réels,
nœud sur batterie. Journal brut :
`mesures/20260830-115420-09-gateway-reception-campagne-portee.log`.

L'essai de table qui l'a précédée
(`mesures/20260830-115020-…`) sert de point de comparaison, et il est ce qui
rend le reste lisible : **−17 à −20 dBm à un mètre**. Un signal de table et un
signal de jardin sont séparés de plus de 40 dB, et c'est cet écart qui permet de
dire, en lisant un journal seul, d'où une trame est partie.

| | |
|---|---|
| Trames émises (`seq` 0 → 169) | 170 |
| Trames reçues, `seq` distincts | 170 |
| **Taux de perte** | **0 %** |
| RSSI moyen | **−64,4 dBm** — min −73, max −62, écart-type 1,2 |
| SNR moyen | **+12,5 dB** — min +11,2, max +13,5 (saturé) |
| Intervalle constaté | ~14 s |

### La marge, qui est le vrai résultat

Le taux de perte nul ne dit pas grand-chose seul — il dit seulement qu'on n'a
pas atteint la limite. C'est la distance à cette limite qui compte :

| | Mesuré | Seuil SF7 | Marge |
|---|---|---|---|
| RSSI | −64,4 dBm | ~−124 dBm | **60 dB** |
| SNR | +12,5 dB | −7,5 dB | **20 dB au moins** |

Soixante décibels, c'est un facteur mille en puissance. Le lien n'est pas
« suffisant », il est surdimensionné pour l'usage — ce qui laisse de quoi payer
la coque, le sol, la végétation d'été et la pluie sans rien changer aux six
paramètres radio.

La marge SNR est un plancher, pas une mesure : le SX1262 sature vers +13 dB.

### Ce qui a aussi été appris

**Le champ `battery` vaut 0.00 sur les 170 trames.** L'avertissement plus haut
n'était donc pas théorique : le pont diviseur ne renvoie rien d'exploitable sur
ce clone. Ça ne gêne en rien la portée, mais deux conséquences valent d'être
notées — le journal ne permet pas de vérifier *a posteriori* que le nœud était
bien sur batterie, et [O6](/objectifs/o6-autonomie/) hérite d'un symptôme franc
plutôt que d'un doute.

**La sonde a erré entre 2307 et 2277 points** pendant les quarante minutes, en
oscillant plutôt qu'en décroissant franchement. Trente points d'amplitude, sans
qu'on sache ici ce qui bouge — le sol, la température, ou l'électronique. Ce
n'est pas le sujet de cet objectif, mais c'est exactement le genre de mouvement
lent que [O3](/objectifs/o3-calibration/) et
[O8](/objectifs/o8-exploitation/) devront savoir distinguer d'un vrai
assèchement.

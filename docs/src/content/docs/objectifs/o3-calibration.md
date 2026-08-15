---
title: O3 — Calibration
description: Savoir ce que vaut réellement un nombre d'ADC, et de combien les sondes divergent.
sidebar:
  order: 3
  badge:
    text: Tenu
    variant: success
---

**La question.** Que vaut réellement un nombre d'ADC, et de combien deux sondes
censées être identiques divergent-elles ?

**Critère de sortie.** Un chiffre : l'écart maximal entre les trois sondes
placées dans des conditions identiques, et la réponse à la question qui en
découle — les sondes sont-elles interchangeables, oui ou non ?

Le critère demandait initialement « une courbe de référence par sonde ».
[L'ADR-015](/decisions/#adr-015--on-détecte-un-seuil-on-ne-mesure-pas-une-humidité)
l'a retiré : le système détecte un seuil, il ne mesure pas une humidité.

**Dépend de.** [O1](/objectifs/o1-une-sonde/) · **Débloque.**
[O5](/objectifs/o5-chaine-de-donnees/), et fournit à
[O2](/objectifs/o2-multiplexage/) ses valeurs de référence

:::tip[C'est l'objectif le plus important du POC]
Plus important que le choix de la carte, plus important que la portée radio. Un
système qui transmet parfaitement des valeurs incomparables entre elles ne sert
à rien.
:::

## Le montage : trois sondes en direct, sans multiplexeur

```text
S1 AOUT ── GPIO 7 ┐
S2 AOUT ── GPIO 2 ├── NODE-001     alimentation commune : GPIO 6
S3 AOUT ── GPIO 4 ┘                (3 x 5 mA = 15 mA, sous les 40 mA du GPIO)
```

ADC1 laisse quatre broches libres une fois la mesure de batterie (GPIO 1) et
l'alimentation des sondes (GPIO 6) câblées : 7, 2, 4 et 5. Les trois sondes du
POC y tiennent sans multiplexeur, et GPIO 5 reste disponible pour une
quatrième.

:::tip[Pourquoi surtout pas le multiplexeur ici]
Mesurer la divergence *à travers* le CD74HC4067 rendrait le résultat
ininterprétable : on ne saurait plus distinguer la dispersion des **sondes** de
celle des **canaux** du multiplexeur, qui a sa propre résistance à l'état
passant.

Le câblage direct isole ce qu'on cherche à mesurer. Et il produit exactement les
valeurs de référence dont [O2](/objectifs/o2-multiplexage/) a besoin pour son
critère de sortie — « identiques à celles obtenues quand chaque sonde est
branchée seule sur l'ADC ».
:::

### Sur la breadboard

`GND` et `VCC` sont **communs aux trois sondes** : ils vont donc dans les rails,
qui sont faits pour ça. `AOUT` ne l'est pas — les trois doivent rester sur trois
lignes distinctes, sans quoi les sondes sont court-circuitées entre elles et
renvoient toutes la même valeur.

| Où | Ce qui s'y branche |
|---|---|
| Rail `−` | `GND` de la carte + les **trois** `GND` des sondes |
| Rail `+` | **GPIO 6** de la carte + les **trois** `VCC` des sondes |
| Ligne 5 | `AOUT` de S1 + strap vers **GPIO 7** |
| Ligne 10 | `AOUT` de S2 + strap vers **GPIO 2** |
| Ligne 15 | `AOUT` de S3 + strap vers **GPIO 4** |

Les numéros de ligne sont libres, pourvu que les trois `AOUT` soient sur des
lignes différentes et que, dans chaque ligne, les deux fils tombent du même côté
de la rainure — voir
[le fonctionnement d'une breadboard](/objectifs/o1-une-sonde/#si-tu-nas-jamais-utilisé-de-breadboard).

:::danger[Le rail `+` ne porte pas du 3V3]
Il porte **GPIO 6**, que la carte allume et éteint. Un fil 3V3 qui atterrirait
dans ce rail mettrait une broche du microcontrôleur en court-circuit avec
l'alimentation.

Les rails sérigraphiés en rouge et bleu mentent donc ici. Un bout de ruban
adhésif avec « GPIO 6 » écrit dessus coûte dix secondes et évite l'erreur dans
trois semaines.
:::

Deux détails qui se paient cher :

- **Les rails sont souvent coupés au milieu** sur les modèles 830 points, ce
  qu'une interruption du trait imprimé signale. Si les trois sondes ne tiennent
  pas sur une moitié, il faut un strap pour ponter les deux tronçons — sinon les
  sondes du fond ne sont alimentées par rien.
- **15 mA au total** sur GPIO 6, pour 40 mA disponibles. Confortable à trois.
  C'est à la huitième sonde que le transistor de [O2](/objectifs/o2-multiplexage/)
  devient obligatoire.

```console
$ just fw-log 07-trois-sondes trois-sondes-meme-pot
```

Le croquis alimente les trois sondes ensemble, attend les 200 ms de
stabilisation mesurées en [O1](/objectifs/o1-une-sonde/#le-délai-de-stabilisation-après-mise-sous-tension),
puis lit les trois dans la même fenêtre de temps :

```text
S1 (GPIO  7)  moy= 1832.4  ecart-type=  3.1  min=1825  max=1841
S2 (GPIO  2)  moy= 1517.9  ecart-type=  2.8  min=1509  max=1526
S3 (GPIO  4)  moy= 1790.2  ecart-type=  3.4  min=1781  max=1799
divergence = 314.5 points, soit 21.2 % de la dynamique utile
```

:::caution[Les trois lectures doivent être simultanées]
La reproductibilité entre séances vaut environ **37 points**, soit dix fois le
bruit instantané — c'est le résultat le plus contraignant de
[O1](/objectifs/o1-une-sonde/#la-vraie-limite--la-reproductibilité-entre-séances).

Lire les sondes à un quart d'heure d'écart laisserait la dérive de séance se
mélanger à la divergence recherchée. C'est pour ça que le croquis les lit dans
la même fenêtre, sur une seule mise sous tension.
:::

## L'expérience de divergence

Les trois sondes, **dans le même pot de terre**, à la même profondeur, lues par
le même nœud.

Le scénario qu'on redoutait :

```text
S1 = 1832
S2 = 1517
S3 = 1798
```

`S2` ne serait pas mal placée, elle serait **différente** — et une fois les
sondes enterrées à cinq mètres les unes des autres, on aurait conclu que le sol
est plus humide à cet endroit. C'est le genre de piège qu'un POC existe pour
découvrir sur une table.

**Ce n'est pas ce qui s'est produit.** L'écart mesuré est de 7,8 points, pas de
315 — voir les [résultats](#15-août-2026--les-sondes-sont-interchangeables). Le
piège existait, il était réel, et il s'est refermé sur du vide.

## Les points de calibration

:::note[Largement réduit par l'ADR-015]
Cette section décrivait une calibration en trois points par sonde. Depuis que le
système
[détecte un seuil plutôt qu'il ne mesure une humidité](/decisions/#adr-015--on-détecte-un-seuil-on-ne-mesure-pas-une-humidité),
il n'y a plus de courbe à construire.

Ce qui reste utile ici, ce sont les **repères agronomiques** ci-dessous : c'est
d'eux que sortira le seuil d'arrosage, et ils s'établiront en
[O8](/objectifs/o8-exploitation/) en regardant sécher le sol réel.
:::

Trois états de sol, dans le même pot, avec le temps de laisser l'eau se
répartir entre chaque :

```text
raw
 │
 ├── sol complètement sec      (terre passée à l'étuve, ou plusieurs jours sans eau)
 ├── sol humide                (arrosé, ressuyé 24 h)
 └── sol saturé                (arrosé jusqu'à ruissellement)
       │
       ▼
   calibration
       │
       ▼
 valeur exploitable
```

Deux repères plus rigoureux, si on veut aller au-delà du relatif :

- **le point de flétrissement**, en dessous duquel la plante ne peut plus
  extraire l'eau ;
- **la capacité au champ**, l'état d'un sol ressuyé après saturation.

Pour des fraisiers, l'échelle relative entre ces deux repères est
suffisante — et c'est même tout ce dont on a besoin — c'est la question ouverte du
[contexte](/projet/contexte/#la-question-ouverte-de-fond), et cet objectif est
le moment de la trancher avec des chiffres.

## L'influence de la température

Une sonde capacitive est sensible à la température, celle du sol comme celle de
son électronique. Au soleil d'août, l'écart jour/nuit peut produire une
variation du même ordre que la variation d'humidité qu'on cherche à mesurer.

C'est la principale raison d'ajouter à terme une sonde de température de sol :
non pas pour elle-même, mais pour **corriger** les mesures d'humidité. À
documenter ici si l'effet est visible.

## La forme de la calibration

Pas de formule figée d'avance. Selon ce que montrent les données :

- interpolation linéaire entre deux points (le plus simple, souvent suffisant) ;
- interpolation par morceaux sur les trois points ;
- ajustement d'une courbe si la réponse est franchement non linéaire.

La calibration vit **côté collecteur**, jamais côté nœud, et s'applique à la
lecture — de sorte qu'en la corrigeant, tout l'historique se recalcule.
Voir [ADR-002](/decisions/#adr-002--on-stocke-la-valeur-adc-brute).

## Questions ouvertes

- ~~Quel est l'écart maximal entre les trois sondes en conditions identiques ?~~
  **7,8 points au plus**, et probablement moins.
- ~~Cet écart est-il un simple décalage constant, ou un facteur d'échelle ?~~ Ni
  l'un ni l'autre : le classement des sondes s'inverse selon le milieu.
- ~~La réponse est-elle assez linéaire pour une interpolation à deux points ?~~
  Sans objet depuis
  [l'ADR-015](/decisions/#adr-015--on-détecte-un-seuil-on-ne-mesure-pas-une-humidité).
Deux questions restaient posées ici. Aucune ne se tranche sur une table, et
elles ont donc rejoint les objectifs où elles deviennent mesurables :

- l'effet de la température sur un cycle jour/nuit → [O8](/objectifs/o8-exploitation/#questions-ouvertes),
  où il se lira dans les premières données continues ;
- l'opportunité d'un second lot de sondes → [O7](/objectifs/o7-mise-au-jardin/#questions-ouvertes),
  puisque c'est une question de couverture du terrain, pas de calibration.

## Résultats

### 15 août 2026 — les sondes sont interchangeables

:::note[Le critère de sortie a été révisé après la mesure]
Il demandait « une courbe de référence par sonde ». La divergence s'est révélée
négligeable, puis
[l'ADR-015](/decisions/#adr-015--on-détecte-un-seuil-on-ne-mesure-pas-une-humidité)
a retiré l'exigence — dans cet ordre.

Le raisonnement de l'ADR tient indépendamment du résultat : on ne calibre pas
finement un système qui prend une décision binaire, et ce serait vrai même si
les sondes avaient divergé de 300 points. Mais la chronologie est celle-là, et
elle est écrite ici pour qu'on puisse en juger.
:::

`07-trois-sondes`, trois sondes lues dans la même fenêtre de temps, deux milieux
successifs :

| | Même pot | Verre d'eau |
|---|---:|---:|
| S1 (GPIO 7) | 2180,9 | 875,4 |
| S2 (GPIO 2) | 2173,4 | 879,4 |
| S3 (GPIO 4) | 2173,1 | 871,7 |
| **Divergence max** | **7,8 pts** | **7,7 pts** |
| Classement | S1 > S2 > S3 | **S2 > S1 > S3** |

**7,8 points d'écart maximal**, soit 0,5 % de la dynamique utile et un
cinquième de l'incertitude entre séances. Les trois sondes sont
interchangeables : les traiter individuellement reviendrait à corriger un écart
plus petit que le bruit de la procédure de correction.

**Et cet écart n'est même pas attribuable aux sondes.** Le classement change
entre les deux milieux — S1 et S2 permutent. Un décalage de canal ADC serait
constant, un défaut de sonde aussi. Ni l'un ni l'autre ne peut expliquer une
inversion.

7,8 points est donc une **borne supérieure**, pas une mesure. La divergence
réelle est en dessous, noyée sous l'erreur de placement.

### Pourquoi on ne cherchera pas plus loin

Deux milieux ont été essayés, aucun ne permet de faire mieux :

- **Le pot** n'est pas homogène à l'échelle du centimètre — porosité, tassement,
  cheminements de l'eau. La mesure y additionne divergence des sondes et
  hétérogénéité du sol, sans moyen de les séparer.
- **Le verre d'eau** est homogène, mais impose une profondeur d'immersion. Or
  la profondeur est le paramètre dominant : **314 points séparent un petit verre
  d'un verre plein**, soit de l'ordre de dix points par millimètre de lame. Les
  7,8 points mesurés représentent donc moins d'un millimètre d'écart entre trois
  sondes tenues à la main — et elles glissent.

L'air libre lèverait les deux objections, étant homogène et sans profondeur.
Mais [l'ADR-015](/decisions/#adr-015--on-détecte-un-seuil-on-ne-mesure-pas-une-humidité)
rend la mesure sans objet : 8 points sur 1481 ne changent aucune décision
d'arrosage. La borne supérieure suffit.

### Ce que la sensibilité à la profondeur implique quand même

Dix points par millimètre, c'est **une centaine de points par centimètre** — 7 %
de la plage utile. Sans effet sur un seuil grossier, mais assez pour rendre
trompeuse toute comparaison fine entre deux sondes posées à des profondeurs
différentes.

À garder en tête au moment d'interpréter les écarts entre zones en
[O8](/objectifs/o8-exploitation/) : une sonde qui lit plus sec qu'une autre est
peut-être simplement moins enfoncée.

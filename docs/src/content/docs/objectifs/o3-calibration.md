---
title: O3 — Calibration
description: Savoir ce que vaut réellement un nombre d'ADC, et de combien les sondes divergent.
sidebar:
  order: 3
---

**La question.** Que vaut réellement un nombre d'ADC, et de combien deux sondes
censées être identiques divergent-elles ?

**Critère de sortie.** Une courbe de référence par sonde, et un chiffre : l'écart
maximal entre les trois sondes placées dans des conditions identiques.

**Dépend de.** [O2](/objectifs/o2-multiplexage/) · **Débloque.**
[O5](/objectifs/o5-chaine-de-donnees/)

:::tip[C'est l'objectif le plus important du POC]
Plus important que le choix de la carte, plus important que la portée radio. Un
système qui transmet parfaitement des valeurs incomparables entre elles ne sert
à rien.
:::

## L'expérience de divergence

Les trois sondes, **dans le même pot de terre**, à la même profondeur, lues par
le même nœud.

```text
3 sondes

S1 ─┐
S2 ─┤── NODE-001
S3 ─┘
```

Si on obtient :

```text
S1 = 1832
S2 = 1517
S3 = 1798
```

alors on vient de découvrir, sur une table, un problème qui aurait été
indétectable une fois les sondes enterrées à cinq mètres les unes des autres :
`S2` n'est pas mal placée, elle est **différente**. Sans cette expérience, on
aurait conclu que le sol est plus humide à cet endroit.

C'est exactement le genre d'information qu'un POC doit produire.

## Les points de calibration

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

Pour des fraisiers, l'échelle relative entre ces deux repères est probablement
largement suffisante — c'est la question ouverte du
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

- Quel est l'écart maximal entre les trois sondes en conditions identiques ?
- Cet écart est-il un simple décalage constant, ou un facteur d'échelle ?
- La réponse est-elle assez linéaire pour une interpolation à deux points ?
- L'effet de la température est-il visible sur une journée d'août ?
- Faut-il commander un second lot de sondes ?

## Résultats

*À remplir.*

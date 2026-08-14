---
title: O7 — Mise au jardin
description: "Sortir de la table : boîtier, câbles longs, sondes enterrées, portée réelle."
sidebar:
  order: 7
---

**La question.** Est-ce que ça survit dehors, avec des sondes au bout de
plusieurs mètres de câble ?

**Critère de sortie.** Un mois de fonctionnement continu sans intervention, sur
l'allée de fraisiers.

**Dépend de.** [O6](/objectifs/o6-autonomie/) · **Débloque.**
[O8](/objectifs/o8-exploitation/)

C'est l'objectif où le POC devient une V1, et où plusieurs décisions provisoires
arrivent à échéance :
[ADR-004](/decisions/#adr-004--deux-cartes-identiques-pas-de-passerelle-lorawan)
et [ADR-008](/decisions/#adr-008--le-poc-tourne-sur-le-pc-de-dev).

## L'implantation

Un nœud central, sondes réparties le long de l'allée :

```text
0m        5m        10m       15m
│---------│----------│---------│
    S1          S2        S3
             │
          NODE-001
```

Et, à terme, deux profondeurs par zone plutôt que trois positions en surface :

```text
zone A                 zone B
 ├── S1 à 10 cm         ├── S3 à 10 cm
 └── S2 à 20 cm         └── S4 à 20 cm
```

C'est cette configuration qui produit les observations réellement utiles :

> « Après l'arrosage, la couche superficielle monte immédiatement mais la
> couche à 20 cm reste sèche. »

Autrement dit : l'eau n'est pas allée là où on croyait.

## Le câblage

Le vrai sujet de cet objectif, et le risque principal du projet. Une sonde
analogique au bout de 15 m n'a rien à voir avec une sonde à 30 cm :

- bruit capté par le câble, qui se comporte comme une antenne ;
- chute de tension dans l'alimentation de la sonde ;
- interférences ;
- impédance de source vue par l'ADC.

Ce qui se décide **à partir des mesures**, pas avant :

- section des conducteurs (pour la chute de tension d'alimentation) ;
- blindage, et de quel côté le raccorder à la masse ;
- éventuel condensateur de découplage au plus près de chaque sonde.

Le protocole de test est simple : la même sonde, dans le même pot, lue d'abord
avec 20 cm de strap puis avec la longueur réelle de câble. L'écart de valeur
moyenne donne le décalage, l'écart-type donne le bruit ajouté.

## L'étanchéité

Deux sujets distincts.

**Le boîtier du nœud** : IP65, presse-étoupes pour les câbles de sonde,
passage d'antenne. Le piège classique est la condensation — un boîtier
parfaitement étanche qui enferme de l'air humide se remplit d'eau par cycles
thermiques. Une membrane de compensation, ou un sachet déshydratant, coûte
moins cher qu'une carte noyée.

**Les sondes** : les modules génériques ne sont pas conçus pour rester en
terre. Deux voies, à départager ici :

- basculer sur des sondes réellement étanches (DFRobot SEN0308, IP65), en
  tenant compte de leur mauvaise distribution en France — RS ~18 €, Farnell
  annonce septembre 2026, donc à anticiper de plusieurs semaines ;
- garder les sondes génériques en les protégeant : la
  [coque imprimée en 3D](/materiel/coque-des-sondes/) est conçue et versionnée,
  il reste à relever sept cotes et à l'imprimer.

Dans les deux cas, le **vernissage de l'électrode et des chants** est
indispensable : c'est par les tranches nues du PCB que l'humidité remonte.

## La portée en conditions réelles

La campagne de [O4](/objectifs/o4-lien-radio/) était ponctuelle. Ici on observe
le lien **dans la durée** : RSSI et SNR archivés à chaque trame, et on regarde
ce que font la végétation qui pousse, la pluie, l'humidité de l'air et les
saisons.

## Questions ouvertes

- Combien de bruit ajoute le câble long, et suffit-il de moyenner ?
- Blindé ou non blindé ?
- Le nœud reste-t-il au sol, ou en hauteur pour la portée radio ?
- Où héberger la partie serveur maintenant que la surveillance doit être
  continue ?
- Faut-il déjà une deuxième zone (potager, verger) ?

## Résultats

*À remplir.*

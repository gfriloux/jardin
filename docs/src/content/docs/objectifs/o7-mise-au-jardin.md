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

:::note[C'est ici que le modèle de données se juge pour de bon]
[O5](/objectifs/o5-chaine-de-donnees/) demandait initialement une semaine de
mesures. Elle en a été retirée : sur une table, avec une sonde dans un verre
d'eau, une semaine ne produit qu'une ligne plate — et on ne juge pas si une
architecture est agréable à exploiter sur une ligne plate.

Ce mois-ci l'absorbe entièrement, et sur des données qui disent enfin quelque
chose. C'est lui qui produira la première **courbe d'assèchement réelle**, dont
[O8](/objectifs/o8-exploitation/) a besoin pour poser des seuils défendables.
:::

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
  [coque imprimée en 3D](/materiel/coque-des-sondes/) est conçue, versionnée,
  imprimée et **montée** — la carte s'encastre et les deux coquilles
  s'emboîtent. Ce qui reste à prouver n'est plus la géométrie mais la tenue
  dans la durée.

**Une décision de conception attendait ici, elle a été prise en amont.** La
coque engageait 48 mm de carte, soit 22 mm sous la limite d'immersion, et
plafonnait l'enfoncement à 50 mm d'électrode là où la carte en autorise 72.
Elle descend maintenant à 30 mm et en laisse **68**.

Reste à vérifier au jardin ce qu'aucun calcul ne dira : 68 mm de sonde en terre
suffisent-ils à voir ce qu'on cherche, ou les valeurs suivent-elles encore trop
la surface qui sèche ?

Dans les deux cas, le **vernissage de l'électrode et des chants** est
indispensable : c'est par les tranches nues du PCB que l'humidité remonte.

## La portée en conditions réelles

La campagne de [O4](/objectifs/o4-lien-radio/#résultats) était ponctuelle. Ici
on observe le lien **dans la durée** : RSSI et SNR archivés à chaque trame, et
on regarde ce que font la végétation qui pousse, la pluie, l'humidité de l'air
et les saisons.

Elle laisse deux choses à vérifier ici, et une réserve confortable pour les
absorber :

**La hauteur.** O4 a mesuré −64,4 dBm avec le nœud à portée de main. Dans sa
coque, posé au sol, il perdra facilement 10 à 20 dB — la proximité du sol coûte
cher en propagation. Sur 60 dB de marge c'est absorbable sans discussion, mais
la mesure se refait au même endroit, coque fermée et posée, plutôt que de se
supposer.

**Le boîtier.** Une coque plastique n'atténue presque rien à 868 MHz, mais
l'antenne collée contre une paroi ou repliée dans le volume, si. C'est le
placement de l'antenne qu'on vérifie, pas la matière de la coque.

Avec 60 dB devant soi, aucune de ces deux questions n'est un risque pour le
projet — ce sont des mesures de contrôle, à faire une fois et à archiver.

## Questions ouvertes

- Combien de bruit ajoute le câble long, et suffit-il de moyenner ?
- Blindé ou non blindé ?
- Le nœud reste-t-il au sol, ou en hauteur pour la portée radio ?
- Où héberger la partie serveur maintenant que la surveillance doit être
  continue ?
- Faut-il déjà une deuxième zone (potager, verger) ?
- Faut-il un second lot de sondes ? *(venue de [O3](/objectifs/o3-calibration/) :
  leur divergence de 7,8 points ne le justifie pas, mais la couverture de quinze
  mètres d'allée peut-être.)*

## Résultats

*À remplir.*

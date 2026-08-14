---
title: Contexte et objectif
description: Pourquoi ce projet existe, ce qu'on cherche à mesurer, et ce qu'on refuse de construire tout de suite.
sidebar:
  order: 1
---

## Le point de départ

Les canicules à répétition mettent le jardin dans un état chaotique : ce qui
tenait sans arrosage ne tient plus, ce qu'on arrosait « au jugé » se retrouve
soit noyé soit grillé, et il est impossible de savoir après coup ce qui s'est
réellement passé dans le sol.

La demande initiale, formulée volontairement large pour ne fermer aucune porte :

> Un système low tech permettant d'avoir des sondes d'humidité du sol pour mes
> fraisiers. Toutes ces sondes reliées sur un boîtier sur batterie / panneau
> solaire, et être capable de lire ces valeurs pour les indexer en base.

La zone concernée aujourd'hui : **une allée de fraisiers de 15 m × 0,5 m**.
L'objectif à moyen terme : **couvrir progressivement tout le terrain**.

## Le glissement d'objectif qui structure tout

Cette différence de formulation change l'architecture en profondeur :

- ❌ « un système de sondes pour mes fraisiers »
- ✅ « un petit réseau de télémétrie pour mon terrain, dont la première
  application est les fraisiers »

La première formulation mène à un boîtier dédié qu'il faudra jeter à la
première extension. La seconde impose dès le départ des nœuds interchangeables,
un protocole qui ne sait pas ce qu'est une fraise, et un serveur qui ignore
quel matériel se trouve derrière.

C'est plus de travail sur les deux premières semaines. C'est beaucoup moins de
travail sur les deux prochaines années.

## Ce qu'on cherche à obtenir

Le premier livrable qui a de la valeur n'est pas une interface. C'est une
courbe :

```text
humidité
  │
80│          ╭──────╮
60│──────────╯      ╰─────╮
40│                       ╰────
20│
  └───────────────────────────── temps
       arrosage ↑
```

Et, très vite, des observations de ce type :

> « Après l'arrosage, la couche superficielle monte immédiatement mais la
> couche à 20 cm reste sèche. »

> « La zone A reste humide 36 h alors que la zone B sèche en 18 h. »

C'est ça qui permettra ensuite de décider d'un seuil d'arrosage. Automatiser
avant d'avoir ces courbes reviendrait à coder un seuil arbitraire.

## Ce qu'on ne construit pas maintenant

Explicitement hors périmètre du POC — tout ceci viendra, mais après :

- panneau solaire, batterie LiFePO₄, contrôleur de charge ;
- boîtier IP65 ;
- vraie passerelle LoRaWAN (SX1302/SX1303, ~100 € et plus) ;
- 20 sondes ;
- électrovannes ;
- PCB sur mesure ;
- interface utilisateur maison.

:::note[Le critère]
Le POC doit tenir **sur une table**, avec une breadboard et une powerbank. S'il
ne tient plus sur la table, c'est qu'on a commencé la V1 sans s'en rendre
compte.
:::

## La question ouverte de fond

Veut-on mesurer une humidité **relative**, utile pour déclencher un arrosage, ou
quelque chose qui s'approche d'une **mesure physique de teneur en eau du sol** ?

Pour des fraisiers, la première option est probablement largement suffisante et
beaucoup moins chère. Le choix n'a pas à être tranché maintenant : en
[conservant la valeur ADC brute](/decisions/#adr-002--on-stocke-la-valeur-adc-brute),
on garde les deux options ouvertes indéfiniment.

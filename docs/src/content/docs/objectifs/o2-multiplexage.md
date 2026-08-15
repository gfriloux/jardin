---
title: O2 — Passer à N sondes
description: Franchir la limite des quatre entrées analogiques, sans confondre les sondes.
sidebar:
  order: 2
---

**La question.** Est-ce qu'un nœud peut lire plus de quatre sondes sans les
confondre ni les contaminer entre elles ?

**Critère de sortie.** Trois sondes lues en séquence à travers le multiplexeur,
avec des valeurs identiques à celles relevées en direct pendant
[O3](/objectifs/o3-calibration/).

**Dépend de.** [O1](/objectifs/o1-une-sonde/), et de [O3](/objectifs/o3-calibration/)
pour les valeurs de référence · **Débloque.** rien dans le POC

**Matériel nécessaire.** Le CD74HC4067 — dont la livraison n'a pas de date
annoncée.

:::note[Cet objectif ne bloque plus rien]
Il l'a longtemps semblé, parce que O3 devait passer par lui. Ce n'est pas le
cas : ADC1 laisse quatre broches libres une fois la batterie et l'alimentation
des sondes câblées, donc les trois sondes du POC se lisent **en direct**.

O2 sert à franchir la limite de quatre, ce dont l'allée de 15 mètres aura
besoin — pas le POC sur la table. Le retard de livraison est un agacement, pas
un blocage.

Et l'ordre inversé rend O2 **vérifiable** : son critère de sortie exige des
valeurs de référence prises sans multiplexeur, que O3 produira. Attendre le
CD74HC4067 pour tout faire d'un coup aurait laissé O2 s'auto-attester.
:::

## Le montage

```text
             ┌── S1
ESP32 ─ MUX ─┼── S2
             ├── S3
             └── (13 canaux libres)
```

Le CD74HC4067 offre seize entrées analogiques sur un seul ADC. Trois seulement
serviront à la validation, mais l'architecture ne plafonne plus à quatre — c'est
tout l'intérêt de l'objectif.

**Prévoir un transistor sur l'alimentation des sondes.** Une sonde tire 5 mA :
sept suffisent à dépasser les 40 mA qu'un GPIO fournit. Or on voudra les
alimenter toutes ensemble, pour payer le délai de stabilisation de 200 ms une
fois et non seize — voir [O1](/objectifs/o1-une-sonde/#le-délai-de-stabilisation-après-mise-sous-tension).

Câblage : quatre broches d'adresse (`S0`–`S3`) pour choisir le canal, une broche
`EN` (active à l'état bas), et la sortie commune `SIG` vers une broche **ADC1**.

## Le point de vigilance principal

Un multiplexeur analogique a une **résistance à l'état passant** non nulle
(de l'ordre de quelques dizaines à quelques centaines d'ohms selon la tension
d'alimentation) et une **capacité parasite**. Deux conséquences :

1. **La diaphonie temporelle.** Après un changement de canal, la valeur lue peut
   encore porter la trace du canal précédent tant que la capacité d'entrée de
   l'ADC ne s'est pas rechargée. Le test qui le révèle : lire une sonde sèche
   juste après une sonde immergée, et vérifier que la valeur ne bouge pas selon
   l'ordre de lecture.
2. **Le décalage systématique.** La chute de tension dans le mux peut décaler
   toutes les valeurs. C'est pour ça que le critère de sortie compare aux
   valeurs obtenues **sans** mux.

Le remède, si le problème existe : un délai après le changement de canal, et
une lecture jetée avant la lecture retenue.

## La séquence de mesure

```text
          OFF la plupart du temps
                   │
                   ▼
             réveil du nœud
                   │
                   ▼
          alimentation sondes ON
                   │
             attendre ~100 ms
                   │
                   ▼
          S1 → sélection → délai → mesure
          S2 → sélection → délai → mesure
          S3 → sélection → délai → mesure
                   │
                   ▼
          alimentation sondes OFF
```

L'ordre de lecture doit être **fixe**, pour que toute diaphonie résiduelle soit
au moins reproductible.

## Questions ouvertes

- Faut-il un délai après changement de canal, et de combien ?
- Le mux décale-t-il les valeurs par rapport à une lecture directe ?
- Peut-on couper l'alimentation des sondes via `Vext` (GPIO 36), ou faut-il un
  transistor dédié ?
- Le mux lui-même doit-il être alimenté en permanence, ou coupé entre deux
  mesures ?

## Résultats

*À remplir.*

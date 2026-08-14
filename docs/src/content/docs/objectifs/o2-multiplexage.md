---
title: O2 — N sondes via multiplexeur
description: Lire trois sondes sur un seul ADC sans les confondre.
sidebar:
  order: 2
---

**La question.** Est-ce qu'un nœud peut lire plusieurs sondes sans les
confondre ni les contaminer entre elles ?

**Critère de sortie.** Trois sondes lues en séquence, avec des valeurs
identiques à celles obtenues quand chaque sonde est branchée seule sur l'ADC.

**Dépend de.** [O1](/objectifs/o1-une-sonde/) · **Débloque.**
[O3](/objectifs/o3-calibration/)

**Matériel nécessaire.** Le CD74HC4067 — dont la livraison n'a pas de date
annoncée. Cet objectif peut donc être doublé par
[O4](/objectifs/o4-lien-radio/), qui n'en dépend pas.

## Le montage

```text
             ┌── S1
ESP32 ─ MUX ─┼── S2
             ├── S3
             └── (13 canaux libres)
```

Le CD74HC4067 offre seize entrées analogiques sur un seul ADC. Trois seulement
seront utilisées, mais l'architecture ne plafonne pas à trois — c'est tout
l'intérêt de le poser maintenant.

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

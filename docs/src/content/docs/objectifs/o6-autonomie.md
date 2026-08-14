---
title: O6 — Autonomie
description: Faire dormir le nœud, mesurer ce qu'il consomme, et dimensionner son alimentation.
sidebar:
  order: 6
---

**La question.** Combien de temps le nœud tient-il, et sur quelle source ?

**Critère de sortie.** Un chiffre de consommation moyenne mesuré, pas estimé, et
un dimensionnement batterie + panneau qui en découle.

**Dépend de.** [O5](/objectifs/o5-chaine-de-donnees/) · **Débloque.**
[O7](/objectifs/o7-mise-au-jardin/)

## Le cycle

```text
             réveil
               │
      alimentation sondes ON
               │
         mesure S1..S3
               │
      alimentation sondes OFF
               │
         émission LoRa
               │
          deep sleep
```

Tout le travail consiste à rendre la dernière ligne aussi longue que possible et
les autres aussi courtes que possible.

## Le budget énergétique

Trois postes à mesurer séparément, au multimètre en série avec la carte :

| Poste | Ordre de grandeur attendu | Durée par cycle |
|---|---|---|
| Deep sleep | quelques dizaines de µA | ~99,9 % du temps |
| Mesure (sondes alimentées + ADC) | quelques dizaines de mA | ~1 s |
| Émission LoRa | ~100 mA en pointe | 50 ms à 1,5 s selon le facteur d'étalement |

C'est le premier poste qui domine le résultat, parce qu'il dure tout le temps.
Un courant de fuite de 500 µA au lieu de 20 µA change tout le dimensionnement —
et ce genre de fuite vient typiquement d'une LED d'alimentation ou d'un
régulateur laissé en circuit sur la carte.

:::caution[La couche Arduino peut coûter cher ici]
[ADR-005](/decisions/#adr-005--firmware-en-platformio--arduino--radiolib) prévoit
explicitement une migration vers ESP-IDF si la consommation en sommeil ne
descend pas assez bas. C'est à cet objectif que la question se tranche, avec
des chiffres.
:::

## Le problème de la powerbank

La powerbank INIU coupera sa sortie dès que le nœud entrera en deep sleep — voir
[les risques](/materiel/risques/#la-powerbank-va-se-couper-en-deep-sleep). C'est
donc à cet objectif qu'elle sort du montage.

La piste la plus propre : une batterie Li-ion directement sur le connecteur
dédié de la carte, qui embarque déjà un chargeur, puis un panneau solaire en
amont.

## Le compromis à arbitrer

```text
période de mesure ↑  →  autonomie ↑  mais résolution temporelle ↓
facteur d'étalement ↑ →  portée ↑     mais temps d'antenne ↑ donc conso ↑
```

Une mesure toutes les dix minutes n'est absolument pas un problème pour LoRa, et
c'est probablement bien plus fin que nécessaire : le sol ne sèche pas en dix
minutes. La bonne période sortira des courbes d'assèchement observées à
[O8](/objectifs/o8-exploitation/) — ce qui suggère de commencer serré, quitte à
espacer ensuite.

## Questions ouvertes

- Quelle consommation réelle en deep sleep sur cette carte précise ?
- Quelle capacité de batterie pour tenir une semaine sans soleil en décembre ?
- Quelle taille de panneau pour un bilan positif au solstice d'hiver ?
- Faut-il descendre à ESP-IDF ?
- Le nœud doit-il adapter sa période de mesure à sa tension de batterie ?

## Résultats

*À remplir.*

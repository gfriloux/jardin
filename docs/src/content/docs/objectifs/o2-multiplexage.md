---
title: O2 — Passer à N sondes
description: Franchir la limite des quatre entrées analogiques, sans confondre les sondes.
sidebar:
  order: 2
  badge:
    text: Prêt
    variant: note
---

**La question.** Est-ce qu'un nœud peut lire plus de quatre sondes sans les
confondre ni les contaminer entre elles ?

**Critère de sortie.** Trois sondes lues en séquence à travers le multiplexeur,
avec des valeurs identiques à celles relevées en direct pendant
[O3](/objectifs/o3-calibration/).

**Dépend de.** [O1](/objectifs/o1-une-sonde/), et de [O3](/objectifs/o3-calibration/)
pour les valeurs de référence · **Débloque.** rien dans le POC

**Matériel nécessaire.** Le CD74HC4067, **arrivé**, barrettes soudées. Plus
rien n'attend.

:::note[Cet objectif ne bloque plus rien]
Il l'a longtemps semblé, parce que O3 devait passer par lui. Ce n'est pas le
cas : ADC1 laisse quatre broches libres une fois la batterie et l'alimentation
des sondes câblées, donc les trois sondes du POC se lisent **en direct**.

O2 sert à franchir la limite de quatre, ce dont l'allée de 15 mètres aura
besoin — pas le POC sur la table. Le retard de livraison a donc été un agacement
et jamais un blocage : O4 a été tenu pendant ce temps, avec une sonde unique.

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

### Ce qu'est un multiplexeur, en une phrase

C'est un **aiguillage**. Seize entrées, une seule sortie, et quatre fils
d'adresse qui disent laquelle des seize est reliée à la sortie à cet instant.

Quatre fils donnent seize combinaisons — `0000` choisit l'entrée `C0`, `0001`
l'entrée `C1`, `0010` l'entrée `C2`, et ainsi de suite. C'est du binaire, et
c'est le croquis qui l'écrit ; toi tu ne câbles que les quatre fils.

## Étape 1 — Le module vers la carte

**Débranche l'USB avant de câbler.**

Huit fils, et le schéma est volontairement plat : **chaque broche du module va
en face, à la même hauteur, sur la carte.** Aucun croisement.

| Broche du module | Va sur | Rôle |
|---|---|---|
| `SIG` (ou `COM`, `Z`) | **GPIO 7** | la mesure qui ressort de l'aiguillage |
| `S0` | **GPIO 47** | adresse, bit 1 |
| `S1` | **GPIO 48** | adresse, bit 2 |
| `S2` | **GPIO 19** | adresse, bit 4 |
| `S3` | **GPIO 20** | adresse, bit 8 |
| `EN` (ou `E`) | **GPIO 5** | actif à l'état **bas** : `LOW` = aiguillage en service |
| `VCC` | **3V3** | alimentation |
| `GND` | **GND** | masse |

<figure class="schema">
<svg viewBox="0 0 640 350" role="img" aria-labelledby="cablage-o2-bus-titre">
  <title id="cablage-o2-bus-titre">Câblage du module CD74HC4067 vers la carte ESP32-S3. SIG vers GPIO 7, S0 vers GPIO 47, S1 vers GPIO 48, S2 vers GPIO 19, S3 vers GPIO 20, EN vers GPIO 5, VCC vers 3V3, GND vers GND. Les huit liaisons sont horizontales et sans croisement.</title>

  <rect x="40" y="45" width="170" height="270" rx="6" class="boitier"/>
  <text x="125" y="35" class="titre" text-anchor="middle">module CD74HC4067</text>

  <rect x="450" y="45" width="150" height="270" rx="6" class="boitier"/>
  <text x="525" y="35" class="titre" text-anchor="middle">carte ESP32-S3</text>

  <g class="pastilles">
    <circle cx="210" cy="75"  r="4" class="pastille"/>
    <circle cx="210" cy="110" r="4" class="pastille"/>
    <circle cx="210" cy="145" r="4" class="pastille"/>
    <circle cx="210" cy="180" r="4" class="pastille"/>
    <circle cx="210" cy="215" r="4" class="pastille"/>
    <circle cx="210" cy="250" r="4" class="pastille"/>
    <circle cx="210" cy="285" r="4" class="pastille"/>
    <circle cx="210" cy="308" r="4" class="pastille"/>
  </g>
  <text x="198" y="79"  class="etiq" text-anchor="end">SIG</text>
  <text x="198" y="114" class="etiq" text-anchor="end">S0</text>
  <text x="198" y="149" class="etiq" text-anchor="end">S1</text>
  <text x="198" y="184" class="etiq" text-anchor="end">S2</text>
  <text x="198" y="219" class="etiq" text-anchor="end">S3</text>
  <text x="198" y="254" class="etiq" text-anchor="end">EN</text>
  <text x="198" y="289" class="etiq" text-anchor="end">VCC</text>
  <text x="198" y="312" class="etiq" text-anchor="end">GND</text>

  <g class="pastilles">
    <circle cx="450" cy="75"  r="4" class="pastille"/>
    <circle cx="450" cy="110" r="4" class="pastille"/>
    <circle cx="450" cy="145" r="4" class="pastille"/>
    <circle cx="450" cy="180" r="4" class="pastille"/>
    <circle cx="450" cy="215" r="4" class="pastille"/>
    <circle cx="450" cy="250" r="4" class="pastille"/>
    <circle cx="450" cy="285" r="4" class="pastille"/>
    <circle cx="450" cy="308" r="4" class="pastille"/>
  </g>
  <text x="462" y="79"  class="etiq">GPIO 7</text>
  <text x="462" y="114" class="etiq">GPIO 47</text>
  <text x="462" y="149" class="etiq">GPIO 48</text>
  <text x="462" y="184" class="etiq">GPIO 19</text>
  <text x="462" y="219" class="etiq">GPIO 20</text>
  <text x="462" y="254" class="etiq">GPIO 5</text>
  <text x="462" y="289" class="etiq">3V3</text>
  <text x="462" y="312" class="etiq">GND</text>

  <line x1="210" y1="75"  x2="450" y2="75"  class="fil jaune"/>
  <line x1="210" y1="110" x2="450" y2="110" class="fil bleu"/>
  <line x1="210" y1="145" x2="450" y2="145" class="fil bleu"/>
  <line x1="210" y1="180" x2="450" y2="180" class="fil bleu"/>
  <line x1="210" y1="215" x2="450" y2="215" class="fil bleu"/>
  <line x1="210" y1="250" x2="450" y2="250" class="fil vert"/>
  <line x1="210" y1="285" x2="450" y2="285" class="fil rouge"/>
  <line x1="210" y1="308" x2="450" y2="308" class="fil noir"/>

  <text x="330" y="338" class="note" text-anchor="middle">jaune = mesure · bleu = adresse · vert = mise en service · rouge = 3V3 · noir = GND</text>
</svg>
</figure>

## Étape 2 — Les sondes vers le module

Les trois sondes s'alimentent **en commun**, exactement comme dans le montage à
trois sondes de O3 : tous les `VCC` ensemble sur GPIO 6, tous les `GND` ensemble
sur GND. Seules les sorties `AOUT` se séparent.

| Fil | Va sur |
|---|---|
| Sonde 1 `AOUT` | entrée **`C0`** du module — **et aussi GPIO 2**, voir ci-dessous |
| Sonde 2 `AOUT` | entrée **`C1`** du module |
| Sonde 3 `AOUT` | entrée **`C2`** du module |
| Les trois `VCC` | **GPIO 6**, tous sur le même nœud de breadboard |
| Les trois `GND` | **GND**, tous sur le même nœud |

<figure class="schema">
<svg viewBox="0 0 640 330" role="img" aria-labelledby="cablage-o2-sondes-titre">
  <title id="cablage-o2-sondes-titre">Câblage des trois sondes vers le module CD74HC4067. La sortie AOUT de la sonde 1 va sur l'entrée C0 et en même temps sur GPIO 2 pour la lecture directe de comparaison ; la sonde 2 va sur C1, la sonde 3 sur C2.</title>

  <rect x="20" y="40"  width="105" height="52" rx="6" class="boitier"/>
  <rect x="20" y="120" width="105" height="52" rx="6" class="boitier"/>
  <rect x="20" y="200" width="105" height="52" rx="6" class="boitier"/>
  <text x="72" y="70"  class="etiq" text-anchor="middle">sonde 1</text>
  <text x="72" y="150" class="etiq" text-anchor="middle">sonde 2</text>
  <text x="72" y="230" class="etiq" text-anchor="middle">sonde 3</text>
  <text x="72" y="30"  class="mini" text-anchor="middle">AOUT de chaque sonde</text>

  <circle cx="125" cy="66"  r="4" class="pastille"/>
  <circle cx="125" cy="146" r="4" class="pastille"/>
  <circle cx="125" cy="226" r="4" class="pastille"/>

  <rect x="300" y="40" width="150" height="215" rx="6" class="boitier"/>
  <text x="375" y="30" class="titre" text-anchor="middle">module CD74HC4067</text>
  <circle cx="300" cy="66"  r="4" class="pastille"/>
  <circle cx="300" cy="146" r="4" class="pastille"/>
  <circle cx="300" cy="226" r="4" class="pastille"/>
  <text x="312" y="70"  class="etiq">C0</text>
  <text x="312" y="150" class="etiq">C1</text>
  <text x="312" y="230" class="etiq">C2</text>
  <text x="375" y="180" class="mini" text-anchor="middle">C3 à C15 libres</text>

  <rect x="545" y="40" width="75" height="80" rx="6" class="boitier"/>
  <text x="582" y="30" class="titre" text-anchor="middle">carte</text>
  <circle cx="545" cy="100" r="4" class="pastille"/>
  <text x="557" y="104" class="etiq">GPIO 2</text>

  <path d="M125 66  L300 66"  class="fil jaune"/>
  <path d="M125 146 L300 146" class="fil jaune"/>
  <path d="M125 226 L300 226" class="fil jaune"/>
  <path d="M180 66 C 180 100, 480 60, 545 100" class="fil vert"/>

  <text x="360" y="290" class="note" text-anchor="middle">le fil vert double la sonde 1 : elle est lue en direct ET à travers le module</text>
  <text x="360" y="310" class="note" text-anchor="middle">les VCC et les GND des trois sondes ne sont pas dessinés — ils vont en commun sur GPIO 6 et GND</text>
</svg>
</figure>

:::tip[Le fil en trop qui rend O2 mesurable]
La sonde 1 a **deux fils sur sa sortie** : un vers `C0`, un vers GPIO 2. Ce n'est
pas une erreur de câblage, c'est le cœur de la manip.

Le croquis lit alors la **même sonde**, dans la **même terre**, au **même
instant**, par deux chemins différents. La différence entre les deux lectures ne
peut venir que du multiplexeur.

Sans ce fil, il faudrait comparer aux valeurs de O3 relevées le 15 août — or la
reproductibilité d'une séance à l'autre vaut
[37 points](/objectifs/o1-une-sonde/#la-vraie-limite--la-reproductibilité-entre-séances),
alors que le décalage cherché en vaut probablement 10 à 20. On chercherait un
effet sous un bruit deux fois plus gros que lui. Avec ce fil, la question ne se
pose plus.
:::

### Pourquoi ces broches-là

Le multiplexeur libère les broches ADC1 qui portaient les sondes 2 et 3 — c'est
tout l'objet de O2. Les quatre fils d'adresse vont donc sur des broches **sans
ADC** (47, 48) ou **ADC2** (19, 20), qu'on ne sait pas utiliser pour mesurer de
toute façon, puisqu'ADC2 tombe dès que le Wi-Fi s'active.

Seul `SIG` occupe une broche ADC1 — GPIO 7, celle qui portait déjà la sonde
unique. C'est la seule qui mesure vraiment.

GPIO 2 et 4 restent libres, dont GPIO 2 sert ici à la lecture de comparaison.

:::caution[Vérifie la sérigraphie de ton module]
Les cartes CD74HC4067 du commerce varient : `SIG` s'appelle parfois `COM` ou
`Z`, `EN` parfois `E` ou `INH` (pour *inhibit*). L'ordre physique des broches
change aussi d'un fabricant à l'autre.

**Fie-toi aux inscriptions, jamais à la position.** Le tableau dit quel *nom*
va où, le schéma ne fait que le redessiner.
:::

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

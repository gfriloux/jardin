---
title: Coque des sondes
description: Le boîtier imprimé en 3D qui protège la partie haute des sondes capacitives, sa conception et ce qui reste à mesurer.
sidebar:
  order: 4
  badge:
    text: v9 validée
    variant: success
---

Les sondes vivront dehors. Leur électronique n'est pas protégée. Ce travail de
conception produit un boîtier imprimable en 3D — paramétrique, versionné dans
`hardware/coque/`.

```console
$ just coque-stl        # génère les deux coquilles
$ just coque-test       # banc d'essai : huit contrôles, un par défaut rencontré
$ just coque-preview    # ouvre le modèle
```

:::tip[Où en est la pièce : la v9 est imprimée et validée au montage]
La géométrie est close. Ce qui reste à prouver n'est plus la forme, c'est la
**tenue dans la durée** — et ça se verra à [O7](/objectifs/o7-mise-au-jardin/),
pas sur une table.

Cinq versions ont été imprimées pour y arriver, chacune corrigée sur un défaut
que la précédente ne pouvait pas montrer :

| | Ce que la pièce en main a appris |
|---|---|
| **v4** | la carte n'entre pas : `enc_y` estimé à 34 mm en vaut 20 |
| **v5** | la carte s'encastre — et deux trous de vis manquent à l'appel, ils sont sous elle |
| **v6** | la coquille arrière est inutilisable : posée par un miroir, elle n'atteint sa pose par aucun mouvement réel |
| **v8** | les deux coquilles s'emboîtent ; le connecteur est traversant et ses soudures tapaient dans le couvercle |
| **v9** | 18 mm d'électrode rendus au sol, et les logements d'écrou refermés |

Le [cheminement](#le-cheminement-de-la-conception) détaille chacune. Aucun de
ces défauts n'était visible à l'écran, et c'est le vrai enseignement de la
série.
:::

## La contrainte qui gouverne tout le reste

**Il ne faut surtout pas enfermer la sonde entière.**

La partie basse est l'**électrode capacitive** : la mesure se fait à travers le
vernis du PCB. Ajouter 2 mm de plastique et une lame d'air ferait chuter la
sensibilité à presque rien — on obtiendrait une sonde parfaitement protégée et
parfaitement aveugle.

```text
     ┌─────────┐  0
     │ NE555   │  ← partie haute : régulateur, connecteur
     │ régul.  │     C'est CE qui tombe en panne dehors,
     │ PH2.0   │     et c'est ce que la coque protège
     ├·········┤  24,4  dernier composant
     ├─────────┤  26,0  trait d'immersion
     ├─────────┤  30,0  ← la coque s'arrête ici
     │         │
     │ÉLECTRODE│  ← surtout pas de plastique par-dessus,
     │         │     et surtout pas de coque non plus :
     │         │     chaque millimètre couvert est un
     ╰────╮╭───╯     millimètre qui ne lit pas le sol
          ││         98,0
```

La coque couvre donc les **30 mm du haut**, et rien d'autre. Ce n'est pas un
chiffre choisi : c'est le trait d'immersion à 26,0 mm plus 4 mm de marge, et le
modèle refuse de se rendre en dessous.

## Le cheminement de la conception

L'intérêt de cette section n'est pas historique : chaque version a été corrigée
sur un défaut précis, et connaître ces défauts évite de les réintroduire.

### v1 — capuchon enfilé par la pointe

Un capuchon qui remonte couvrir la partie haute, avec une jupe évasée pour que
l'eau ruisselant sur les flancs goutte à l'écart du PCB, et un col en haut pour
noyer la sortie de câble dans du silicone.

**Deux défauts rédhibitoires**, relevés à la relecture :

1. **La sortie de câble était verticale.** C'est logique — c'est ce que fait la
   sonde — mais c'est un entonnoir. L'eau ne tombe pas seulement dedans : elle
   descend le long de la gaine par capillarité, et le silicone finit toujours
   par se décoller du PVC du câble à force de cycles chaud/froid.
2. **Rien ne retenait la sonde.** La pièce tenait par collage et friction : il
   suffisait de tirer sur le capteur pour qu'il sorte.

### v2 → v3 — col de cygne et coquilles vissées

**Le col de cygne** répond au premier défaut. Le câble monte, fait une boucle de
180° (rayon 10 mm, largement suffisant pour un câble souple 3 fils), et la
bouche débouche **vers le bas**. Le point haut du conduit est 26 mm plus haut
que la bouche : pour entrer, l'eau devrait remonter.

```text
        ╭──╮
        │  │   point haut
   ╭────╯  ╰────╮
   │             │
   │       bouche ▼  ← 40 mm au-dessus du bas de la coque
 ┌─┴─────────────┐
 │     coque     │
```

Le conduit est moulé dans le plan de joint : le câble se **couche** dedans, il
n'y a rien à enfiler. Le connecteur PH2.0 reste à l'intérieur du boîtier.

**Les deux coquilles vissées** répondent au second : 4 vis M3×12 inox, plus un
épaulement passant sous le corps du connecteur PH2.0. Le connecteur étant soudé
au PCB, tirer sur le capteur le fait buter contre cette marche.

Le joint n'est plus de la colle mais un **cordon de silicone neutre dans une
gorge** usinée sur le plan de joint : il est contenu, il ne s'écrase pas hors du
joint au vissage.

### v4 — les ergots dans les encoches

La sonde possède **deux encoches latérales**, au niveau des derniers composants.
C'est le point d'ancrage idéal : prévu pour ça, symétrique, et surtout **bas**
dans le boîtier — l'effort passe donc près du joint plutôt qu'en porte-à-faux
sur les soudures du connecteur.

Deux ergots dans les parois latérales du logement viennent s'y loger. Ils font
toute l'épaisseur de la carte : une fois la coquille arrière vissée, la carte
est prise dans une **mortaise**.

Vérifié par test d'interférence sur le modèle, avec une carte factice
reproduisant les encoches :

| Position | Résultat |
|---|---|
| Nominale | aucun contact, la carte se pose librement |
| Tirée vers le bas de 1,5 mm | blocage sur les ergots |
| Poussée vers le haut de 1,5 mm | blocage sur les ergots |

L'épaulement sous le connecteur est conservé en **second niveau**, avec 0,8 mm
de jeu : ce sont les encoches qui travaillent, le connecteur ne prend l'effort
que si un ergot casse. Les deux butées bloquant dans le même sens et chacune
ayant son jeu, il n'y a pas de risque de sur-contrainte.

Les ergots sont **volontairement sous-dimensionnés** : 0,3 mm moins profonds
que l'encoche, 0,6 mm plus courts.

**C'est cette version qui a été imprimée.** Elle sort propre, elle se ferme,
et la carte n'entre pas.

![La coquille avant v4 imprimée en blanc, posée à côté de la sonde capacitive v1.2 : le logement, la jupe et le col de cygne sont conformes au modèle](../../../assets/photos/o1-13-coque-v4-imprimee.jpg)

### v5 — la cote relevée, et l'ergot rond

Deux corrections, l'une de position, l'autre de forme.

**La position.** `enc_y` passe de 34,0 à **20,0 mm**. C'est le seul défaut qui
empêchait l'encastrement, et c'était le bon soupçon : la v4 posait les ergots
14 mm trop bas, la carte s'appuyait dessus.

**La forme.** L'encoche n'est pas un rectangle mais un **demi-cercle de
⌀4 mm**. L'ergot rectangulaire de la v4 (3,4 × 1,2 mm) n'y serait pas entré de
toute façon : à 1,7 mm du centre, l'arc ne creuse plus que 1,05 mm, et les
coins de l'ergot auraient buté dessus.

```text
        encoche ⌀4,0             ergot ⌀2,4
   ────────╮      ╭───────    ────────╮  ╭───────
           ╰──────╯                   ╰──╯
   la v4 y mettait un rectangle 3,4 × 1,2 :
   ────────╮ ┌────┐ ╭───────   les coins portent
           ╰─┴────┴─╯          sur l'arc, ça bloque
```

L'ergot est donc un **cylindre**, centré sur le chant de la carte, et
**délibérément plus petit que l'encoche**. Pour deux raisons, pas une :

- la différence de rayon — 2,0 − 1,2 = **0,8 mm** — *est* la tolérance de
  montage sur `enc_y`. Un ergot au diamètre exact n'entrerait qu'à la cote
  parfaite, ce qui est précisément le piège où la v4 est tombée ;
- **un petit cylindre sort toujours surdimensionné de l'imprimante.** Largeur
  d'extrusion et pied d'éléphant ajoutent 0,1 à 0,2 mm au rayon : le ⌀2,4
  modélisé fera plutôt 2,5 à 2,8 une fois posé sur le plateau. Viser le
  diamètre nominal de l'encoche, c'est se garantir un ergot trop gros.

Le débattement vertical concédé reste sous le jeu de 0,8 mm de l'épaulement,
qui prend le relais.

Un petit cône en tête sert de guide à la pose.

**Vérifié par banc d'essai**, `just coque-test`, qui intersecte les ergots avec
une carte factice percée de ses encoches :

```console
$ just coque-test
  ok    décalage     0 mm : libre
  ok    décalage   0.7 mm : libre
  ok    décalage  -0.7 mm : libre
  ok    décalage   0.9 mm : bute
  ok    décalage  -0.9 mm : bute
  ok    décalage   1.5 mm : bute
  ok    décalage  -1.5 mm : bute
ergots OK
```

La bascule tombe exactement sur les 0,8 mm calculés. C'est ce test qui
aurait dû tourner avant la première impression : le modèle se rendait, il
n'était pas pour autant montable.

**Et la v5 a été imprimée : la carte s'encastre.**

![La sonde v1.2 posée dans la coquille avant v5 imprimée, les deux ergots engagés dans les encoches latérales](../../../assets/photos/o1-15-carte-encastree.jpg)

Et avec le câble branché, le col de cygne fait ce qu'on lui demandait depuis la
v2 : le connecteur reste à l'intérieur, le câble se couche dans le conduit sans
rien à enfiler, et il ressort par le bas.

![La même sonde encastrée, câble PH2.0 branché et couché dans le col de cygne, ressortant vers le bas](../../../assets/photos/o1-16-carte-encastree-cablee.jpg)

### v6 — fermer la coque

L'encastrement réglé, le montage de la v5 sur la table montre trois défauts
qui ne se voyaient pas tant que la carte n'entrait pas.

**La coquille arrière était un couvercle plat.** L'avant portait une gorge à
silicone, l'arrière rien : les deux pièces ne s'emboîtaient pas, elles se
posaient l'une sur l'autre. La v6 met une **languette** sur l'arrière, qui
entre dans la **rainure** de l'avant.

```text
   coquille arrière        ██  languette 0,6 × 0,6
   ───────────────────────█  █──────────────────
   ═══════════════════════╡  ╞══════════════════  plan de joint
   ───────────────────╮  ╭─╮  ╭─╮  ╭─────────────
   coquille avant     ╰──╯ ╰──╯ ╰──╯  rainure 1,0 × 0,9
                        ↑         ↑
                   0,2 de jeu par côté, 0,3 de fond :
                   c'est là que le silicone se loge,
                   contenu de trois côtés au lieu
                   d'être écrasé entre deux plats.
```

**Les vis n'avaient ni logement de tête ni logement d'écrou.** La v6 noie un
**écrou M3 dans un logement hexagonal borgne** creusé dans le plan de joint de
la coquille avant, et **fraise la tête de vis** dans la coquille arrière. La
visserie passe en **M3×8 à tête fraisée**.

L'épaisseur de la coquille arrière passe de 2,4 à **3,2 mm** au passage : une
fraisure à 90° mange déjà 1,4 mm, et il faut de la matière dessous.

**Et surtout, les perçages ne traversent plus.** C'est le défaut que personne
ne cherchait :

:::danger[Les quatre avant-trous de la v5 perçaient la coque de part en part]
Ils allaient de z = −1 à 12,4 pour 11,4 mm d'épaisseur, et débouchaient sur la
face **extérieure**, *à l'intérieur* du cordon de joint. Quatre canaux qui
menaient l'eau droit dans le volume qu'on cherchait à étancher — dans une pièce
dont c'est l'unique raison d'exister.

Le logement d'écrou est **borgne** : hexagone sur 2,6 mm, dégagement de 4 mm
pour la pointe de vis, et 4,8 mm de matière pleine en dessous. Plus rien ne
relie l'extérieur à l'intérieur.
:::

**Enfin, deux vis passaient dans la carte.** Elles étaient à x = ±9, y = 46,5 ;
la carte fait 23 de large et monte à y = 48. Sur la photo ci-dessus on ne voit
que deux trous de vis — les deux autres sont sous la carte. Les vis du haut
passent donc sur des oreilles comme celles du bas, et les oreilles grandissent
de 10 à 12 mm parce qu'un logement d'écrou tient plus de place qu'un avant-trou
et doit rester en dedans de la rainure.

![Rendu de la coquille avant : le logement du PCB avec ses deux ergots, la rainure de joint qui suit tout le contour, et les quatre logements hexagonaux d'écrou sur les oreilles](../../../assets/coque/coquille-avant.png)

**Le banc d'essai gagne trois contrôles**, un par défaut :

```console
$ just coque-test
ergots contre la carte
  ok    décalage 0 mm                                  libre
  …
le reste de la coque
  ok    aucune vis ne traverse la carte                libre
  ok    aucune cavité ne débouche dehors               libre
  ok    la languette entre dans la rainure             libre
coque OK
```

:::tip[Un test qui n'a jamais échoué ne prouve rien]
Les trois ont été validés en **réintroduisant le défaut** : vis remises à
x = ±9, dégagement d'écrou allongé jusqu'à percer, languette élargie au-delà de
la rainure. Chaque fois le contrôle passe au rouge. Un contrôle qu'on n'a jamais
vu échouer peut très bien ne rien mesurer du tout.
:::

### v7 — une coquille arrière qu'on peut retourner

La v6 a été imprimée. La coquille arrière était **inutilisable** : languette et
fraisures toutes les deux du mauvais côté.

Et pourtant la vue d'assemblage était juste, et les quatre contrôles passaient.
Le défaut n'était pas dans la pièce, il était dans le **geste qui l'amène à sa
place**.

Le modèle posait la coquille arrière sur l'avant par un `mirror([0,0,1])`.

:::danger[Un miroir n'est pas un retournement]
On ne retourne pas une pièce réelle par une symétrie, seulement par une
**rotation** — et une rotation de 180° inverse *deux* axes, pas un seul. Le
contour de la coque n'étant symétrique ni en x ni en y — col d'un côté, jupe de
l'autre — la pièce exportée ne pouvait atteindre sa pose d'assemblage par aucun
mouvement physique.

Posée dans le sens où le contour coïncide, les deux features pointent du
mauvais côté. Retournée pour les remettre du bon côté, le contour ne coïncide
plus. Aucune des deux positions ne ferme la coque.
:::

La coquille arrière est maintenant dessinée dans le repère de **l'assemblage** —
z = 0 est le plan de joint, la languette descend dedans — et c'est l'export qui
la retourne, par une vraie rotation. La pièce sort donc du modèle déjà à plat,
face extérieure vers le plateau.

Elle paraît retournée par rapport à la coquille avant, et c'est normal : c'est
une pièce qu'on pose face contre face.

#### Le contrôle qui manquait

Aucun des quatre contrôles ne pouvait attraper ça : ils comparaient le modèle à
lui-même, avec le même miroir des deux côtés. Le cinquième prend la pièce
**telle qu'elle sort du slicer**, la retourne par une rotation — le geste des
doigts — et exige qu'elle retombe exactement sur sa pose d'assemblage.

| | Volume de non-recouvrement |
|---|---|
| avec le miroir de la v6 | **15 532 mm³** — la pièce entière |
| avec la rotation de la v7 | 0,000000 mm³ |

#### Et un test qui mentait

En l'écrivant, il a d'abord annoncé un défaut là où il n'y en avait pas :
6472 triangles rendus par CGAL, pour un volume de **0,000000 mm³**. Soustraire
deux solides aux frontières confondues produit un maillage bavard et creux.

Le banc jugeait sur « le fichier existe ». Il juge maintenant sur le **volume**,
calculé par `tools/volume-stl.py`, avec un seuil à 0,001 mm³ — un cube de
0,1 mm de côté. Ça rend au passage les verdicts quantitatifs :

```console
  ok    décalage 0.9 mm                                bute, 0.145150 mm3
  ok    décalage 1.5 mm                                bute, 2.144491 mm3
  ok    la pièce imprimée se retourne                  libre
```

### v8 — les soudures du connecteur

Le connecteur est **traversant** : ses trois soudures dépassent au **dos** de la
carte, côté coquille arrière, qui les rencontrait de plein fouet. Rien dans le
modèle ne représentait la carte autrement que comme une plaque lisse — c'est une
chose qu'on ne voit qu'en tenant la sonde.

Relevé : **2,0 mm** de haut, en rang de trois au pas de **2,54 mm** (un pas au
pouce, pas les 2,0 d'un PH2.0), à 4,5 mm sous le bord haut de la carte.

**Ce qu'il faut dégager n'est pas 2 mm.** La carte s'assoit déjà 0,3 mm sous le
plan de joint, parce que son logement est creusé d'autant en plus. La saillie
réelle au-dessus du joint n'est donc que de 1,7 mm, et la poche fait 2,0 mm avec
son jeu.

```text
                   ██ ██ ██  soudures, 2,0
   ┌──────────────┐  │  │  │ ┌──────────────
   │  coquille    └──┴──┴──┴─┘   poche 2,0
   │  arrière                    fond 2,4 = paroi
   ╞══════════════════════════════════ plan de joint
   │  ▓▓▓▓▓▓▓▓▓ carte, assise 0,3 dessous
```

**L'épaisseur de la coquille arrière en découle**, au lieu d'être posée à la
main : `ep_ar = paroi + deg_p`, soit **4,4 mm**. Le fond sous la poche fait alors
2,4 mm — l'épaisseur de paroi de toute la pièce. C'est +1,2 mm et non les +2 mm
qu'on pourrait croire, et la visserie reste en **M3×8** : 4,4 de coquille plus
2,4 d'écrou laissent encore 1,2 mm de pointe dans le dégagement.

La poche est **large et peu profonde** — 12 × 12 mm pour un rang de 5 : sa
position exacte compte peu, un rang de 5 dans une poche de 12 tolère 3 mm
d'erreur. Sa profondeur, elle, se discute au dixième, parce que son fond est la
seule paroi à cet endroit.

![Rendu de la coquille arrière telle qu'elle est exportée, prête à imprimer : la languette en relief sur le pourtour, la poche de dégagement des soudures, et les quatre perçages fraisés côté plateau](../../../assets/coque/coquille-arriere.png)

**Deux contrôles de plus.** Le premier vérifie que les soudures ne touchent pas
le couvercle — sans la poche, 19,34 mm³ de soudure sont enfouis dans le
plastique. Le second est un garde-fou : la poche passe à 7 mm de l'anneau de
joint, et l'élargir la ferait **couper la languette en deux** sans que rien
d'autre ne s'en aperçoive.

**Cette version a été imprimée, et les deux coquilles s'emboîtent.**

### v9 — raccourcir la coque

La coque engageait 48 mm de carte quand le dernier composant est à 24,4 mm du
bord haut et le trait d'immersion à 26,0. Elle couvrait donc **22 mm
d'électrode sans avoir à le faire** — et chaque millimètre couvert est un
millimètre qui ne lit pas le sol.

```text
   bord haut ─┬─ 0
              │   composants jusqu'à 24,4 ─┐
   trait      ┼─ 26,0  immersion max       │ ce que la coque
   lèvre v9   ┼─ 30,0  ←── nouveau bas     ┘ doit couvrir
              │
   lèvre v8   ┼─ 48,0  ←── ancien bas
              │   18 mm rendus au sol
              ┴─ 98,0  pointe
```

`pcb_in` passe de 48 à **30 mm** : la carte autorise 72 mm d'enfoncement, la
coque en laissait 50, elle en laisse maintenant **68**.

Le corps suit, de 52 à 34 mm, et avec lui le col de cygne et les vis hautes.
Ces cotes sont désormais **dérivées** au lieu d'être posées à la main — `H =
pcb_in + 4`, `y_haut = H + 4`, les vis à `H − 8` — sinon la prochaine révision
en oublierait la moitié.

Et deux garde-fous entrent dans le modèle, à la place d'un commentaire :

```openscad
assert(pcb_in >= trait_y + 2, "pcb_in laisse le trait d'immersion hors de la coque");
assert(pcb_in >= compo_y + 2, "pcb_in laisse le dernier composant hors de la coque");
```

Raccourcir encore fait maintenant **échouer le rendu**, au lieu de sortir une
pièce qui a l'air bonne.

#### Un défaut que le raccourcissement a fait sortir

En rapprochant les vis hautes du col de cygne, cette révision a révélé un
défaut qui dormait **depuis la v6** :

:::danger[Les logements d'écrou du haut ouvraient dans le conduit du câble]
Le brin descendant du conduit tombait à x = 20, son perçage occupant la bande
16,4 → 23,6. Les logements d'écrou du haut occupaient 13,65 → 19,35. **74 mm³
de recouvrement** : le nid d'abeille n'était fermé que sur trois côtés, et
l'écrou serait ressorti au premier serrage.

Le chiffre est identique à `pcb_in = 48` — le défaut n'a rien à voir avec le
raccourcissement, il était simplement invisible tant que rien ne le cherchait.
:::

La boucle passe de 10 à **12 mm de rayon** : le brin descend alors à x = 24, ce
qui laisse 1 mm de paroi entre le conduit et l'écrou — et donne au câble un
rayon de cintrage plus confortable. Le huitième contrôle vérifie qu'**aucun
logement d'écrou n'ouvre dans une cavité**, quelle qu'elle soit.

![Rendu de la coquille avant en v9 : corps raccourci, quatre logements hexagonaux d'écrou fermés, rainure de joint sur tout le contour et boucle du col élargie](../../../assets/coque/coquille-avant.png)

**Cette version est imprimée et validée au montage.**

![La coque v9 montée et vissée, sonde à l'intérieur, vue de la coquille avant : la face est entièrement lisse, sans le moindre perçage](../../../assets/photos/o7-06-coque-montee.jpg)

Cette photo montre la **coquille avant**, et ce qu'on n'y voit pas est le
résultat le plus important de la série : **aucun perçage**. Jusqu'à la v5,
quatre avant-trous traversaient cette face de part en part, à l'intérieur du
cordon de joint. La face est maintenant pleine — la visserie s'arrête dans les
écrous noyés au plan de joint, et rien ne relie plus l'extérieur au volume
qu'on cherche à étancher.

![La coque fermée tenue en main, de profil, la sonde sortant par le bas](../../../assets/photos/o7-09-coque-en-main.jpg)

La géométrie est close. Ce qui reste à prouver, c'est la tenue dehors, et ça ne
se voit pas sur une table.

## Le relevé qui a tranché

La sonde est photographiée **posée sur un réglet**, dans son plan. Mesurer les
pixels contre les graduations semble alors suffire — et donne une échelle
**fausse de 5 %**.

![La partie haute de la sonde v1.2 posée sur un réglet en acier, encoche demi-circulaire visible sur le chant, graduations 6 à 12 cm lisibles](../../../assets/photos/o1-10-encoches-reglet.jpg)

La carte est plus haut dans le cadre que les graduations qui servent d'étalon,
donc plus loin de l'objectif, donc reproduite plus petite. Ça s'est vu à un
détail : l'écart avec les lectures directes au réglet **grandissait avec la
distance** — 0,8 mm sur l'encoche, 1,3 mm sur le trait blanc. Un décalage
proportionnel est une erreur d'échelle ; une erreur de lecture aurait été
constante.

### Ne mesurer que des rapports

Le coin haut de la carte, l'encoche et le trait blanc de sérigraphie sont
**alignés sur le même chant**. Quelle que soit l'échelle à cet endroit de
l'image, elle leur est commune — et se simplifie dans un rapport. Il ne reste
qu'à fournir **un** étalon absolu, et une lecture directe au réglet le donne :
le trait blanc est à 26 mm du bord haut.

```text
   coin haut ─┐          ┌─ encoche ─┐              ┌─ trait blanc
              ▼          ▼           ▼              ▼
   ═══════════╤══════════╤═══════════╤══════════════╤═════════
              │◄─ 18,0 ─►│           │              │
              │◄──── 20,0 (enc_y) ──►│              │
              │◄──────────── 26,0 mm, lu au réglet ►│
```

| Repère | Distance au bord haut du PCB |
|---|---|
| Début de l'encoche, côté connecteur | 18,0 mm |
| **Centre de l'encoche → `enc_y`** | **20,0 mm** *(le modèle disait 34,0)* |
| Fin de l'encoche | 22,0 mm |
| Diamètre de l'encoche | 4,0 mm *(mesuré)* |
| Trait blanc de sérigraphie *(étalon)* | 26,0 mm |
| Largeur du PCB → `pcb_w` | 23,0 mm **confirmé** |

**Deux cadrages indépendants** donnent le même résultat à 0,1 mm près — la
`o1-10` ci-dessus et la `o1-14`, prise plus serrée. Et le « début » ainsi
*calculé* retombe sur les 18,0 mm *lus* au réglet, alors que rien dans le
calcul ne l'y forçait : c'est ce qui permet de faire confiance au reste.

![La même sonde sur le réglet, cadrage serré sur les composants et le connecteur, graduations 9 à 13 cm](../../../assets/photos/o1-14-encoches-reglet-serre.jpg)

### Où le rapport se trompe quand même

Le même calcul donnait **3,77 mm** pour le diamètre de l'encoche, là où la
mesure directe dit **4,0**. Ce n'est pas une contradiction, c'est une limite de
la méthode, et elle a une forme précise.

Le flou de bord coûte environ deux pixels à chaque extrémité d'un repère. Sur
les 500 pixels qui séparent le coin haut du trait blanc, ça fait 0,8 % —
invisible. Sur les 73 pixels de l'encoche, ça fait **5,5 %** — soit exactement
l'écart constaté.

:::tip[La règle qui en sort]
Un rapport mesuré sur une image mesure les **longs écarts**, jamais les petits
détails. Le grand écart calibre, le petit détail se mesure à la main.
:::

:::note[Le trait blanc a fixé la hauteur de la coque]
Ce trait est la **limite d'immersion** de la carte : en dessous, plus un seul
composant, rien que l'électrode jusqu'à la pointe.

C'est lui qui commande `pcb_in`. La coque descend à 30 mm, soit 4 mm sous le
trait — assez pour tout couvrir, pas un millimètre de plus. Le modèle refuse
désormais de se rendre si on descend en dessous.
:::

## Les cotes restantes

À confirmer au pied à coulisse, puis à reporter en tête de
`hardware/coque/coque.scad`. Aucune n'est bloquante : ce sont des jeux, plus des
positions.

| Variable | Ce que c'est | Valeur actuelle | Statut |
|---|---|---|---|
| `enc_y` | bord haut du PCB → centre des encoches | 20,0 mm | ✅ relevé |
| `pcb_w` | largeur du PCB | 23,0 mm | ✅ confirmé |
| `enc_diam` | diamètre de l'encoche demi-circulaire | 4,0 mm | ✅ mesuré |
| `pcb_t` | épaisseur du PCB | 1,6 mm | à confirmer |
| `conn_l` | longueur du connecteur le long du PCB | 8,7 mm | standard PH2.0-3P |
| `conn_dh` | bord haut du PCB → haut du connecteur | 0 mm | à confirmer |
| `conn_h` | hauteur du connecteur au-dessus du PCB | 5,75 mm | à confirmer |

**Deux échappatoires** si le montage résiste encore :

- `encoches = false` redonne la v3, sans verrouillage par ergots ;
- `butee = false` renonce à l'épaulement si le connecteur n'est pas orienté
  comme prévu. Le PCB a peut-être un trou de fixation Ø3,4 : s'il existe, un
  téton dedans serait un blocage encore plus franc.

## Impression et montage

**Impression.** Chaque coquille à plat, **face extérieure sur le plateau**,
**zéro support**. L'orientation n'est pas indifférente : c'est elle qui rend la
fraisure de la tête de vis imprimable, le trou se resserrant en montant, ce qui
ne fait qu'un surplomb à 45°. Trois périmètres.

**Matière : PETG ou ASA. Pas de PLA**, il se délite en extérieur au bout d'une
saison.

**Quincaillerie :** 4 vis **M3×8 à tête fraisée** inox et 4 **écrous M3** inox.
Pas de M3×12 : la vis ne traverse plus la coquille avant, elle s'arrête dans
l'écrou noyé au plan de joint.

**Montage :**

1. un **écrou M3 pressé** dans chacun des quatre logements hexagonaux de la
   coquille avant ;
2. cordon de silicone **neutre** dans la rainure du plan de joint ;
3. PCB posé dans la coquille avant, encoches en face des ergots ;
4. câble couché dans le col de cygne, connecteur PH2.0 à l'intérieur ;
5. coquille arrière posée, **languette dans la rainure**, puis les 4 vis ;
6. **boucle d'égouttage** sur le câble sous la sortie, pour que l'eau ne
   descende pas le long du fil.

:::caution[Silicone neutre, jamais acétique]
Le silicone acétique — celui qui sent le vinaigre, le moins cher, le plus
courant en grande surface — dégage de l'acide acétique en réticulant et
**corrode le cuivre**. Sur une carte électronique, c'est une destruction lente
et garantie.
:::

## La limite honnête

C'est une coque étanche **aux projections et à la pluie**, pas un IP68
immersible.

Et surtout : le vrai talon d'Achille de ces cartes n'est pas le boîtier, ce sont
les **tranches nues du PCB**, qui pompent l'humidité par capillarité jusqu'à
l'électronique.

**Le vernissage est donc indispensable, pas optionnel** : deux fines couches de
vernis PCB, de résine époxy ou de vernis à ongles transparent sur l'électrode et
en insistant sur les chants coupés. Une fine couche ne dégrade quasiment pas la
mesure — contrairement à une coque, ce qui est précisément la raison pour
laquelle la coque s'arrête à 45 mm.

Sans vernis, la coque ne fait que retarder l'échéance.

## Ce que ça change pour la stratégie sondes

Ce travail ouvre une option qui n'existait pas quand
[les risques](/materiel/risques/#les-sondes-génériques-ne-sont-pas-vraiment-étanches)
ont été rédigés :

| Voie | Coût | Ce qu'on sait |
|---|---|---|
| Sondes génériques + coque + vernis | ~2 €/sonde + impression | La coque est imprimée et validée au montage ; les sondes sont déjà là |
| Sondes étanches du commerce (SEN0308, IP65) | ~18 €/sonde | Mal distribuées en France, Farnell annonce septembre 2026 |

La première voie n'est plus une hypothèse : la pièce existe et se monte. Elle
reste à valider **par la durée** — une sonde vernie et encoquée qui tient un
hiver vaut mieux qu'une promesse IP65. La
décision n'est pas à prendre maintenant : elle se prendra à
[O7](/objectifs/o7-mise-au-jardin/), à la lumière du comportement réel des
sondes du POC.

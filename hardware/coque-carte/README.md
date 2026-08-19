# Coque des cartes LoRa

Modèle paramétrique OpenSCAD pour loger une carte Heemol / Heltec WiFi LoRa 32
(V3), sa carte fille et le multiplexeur CD74HC4067.

**Le `.scad` est la source de vérité.** Les STL sont générés, jamais versionnés :

```console
$ just coque-carte-stl       # produit hardware/coque-carte/build/*.stl
$ just coque-carte-test      # banc d'essai
$ just coque-carte-preview   # ouvre le modèle dans OpenSCAD
```

## État

**Aucune cote n'a rencontré un pied à coulisse.** La géométrie est arrêtée et
le banc d'essai passe, mais tout ce qui porte `<< A MESURER` dans le `.scad`
vient de la fiche Heltec V3 — et nos cartes sont des clones. **Ne pas imprimer
avant la séance de mesures.**

Encombrement actuel, à titre indicatif : **77 × 62 × 37 mm**.

## Le principe

Une seule coque pour `NODE-001` et `GATEWAY-001`. Les deux cartes portent la
même rangée de 18 broches soudée, même si la passerelle n'en a pas l'usage :
elles restent ainsi interchangeables si l'une meurt au jardin.

Trois étages :

| Étage | Pièce | Comment elle tient |
|---|---|---|
| 0 | carte LoRa | 4 plots, 4 butées cylindriques aux angles |
| 1 | carte fille (plaque à pastilles) | barrette femelle **tulipe** 1×18 sur la rangée, + 2 entretoises |
| 2 | multiplexeur + borniers | enfiché sur la carte fille |

**La carte fille n'est pas un luxe.** Les huit broches de commande du
CD74HC4067 ne tombent jamais en face des bonnes broches Heltec : il faut une
pièce qui réordonne. Elle rend au passage le multiplexeur remplaçable en dix
secondes.

**La barrette prend les 18 positions alors que 7 suffisent.** Les onze
inutilisées ne portent aucun signal mais font toute la tenue mécanique. Une
barrette de sept se déchausserait à la première dilatation.

### Le nœud est bouché, la passerelle est ouverte

Trois pièces imprimées à part ferment l'USB-C, les boutons `PRG`/`RST` et
l'ouverture d'écran. La passerelle vit sur un bureau et les laisse ouverts ; le
nœud vit dehors et les bouche toutes les trois. Il ne perd rien : son écran est
de toute façon masqué par la carte fille.

## ⚠️ Avant d'imprimer

**Passe `just coque-carte-test`.** Huit contrôles, chacun rendant un volume qui
doit être vide :

| Contrôle | Le défaut qu'il attrape |
|---|---|
| la carte fille au-dessus de l'écran, abaissée de 0 à 9 mm | **le mode de panne propre à l'empilage** : la coque sort propre, se visse, et écrase l'OLED |
| rien ne touche le couvercle | le multiplexeur enfiché ou les borniers dépassent |
| aucune vis ne traverse une carte | v-sonde : deux vis tombaient en plein dans le PCB |
| aucun logement d'écrou ne débouche dehors | v-sonde : quatre perçages menaient l'eau à l'intérieur du joint |
| aucun écrou n'ouvre dans le volume intérieur | v-sonde v6 : nid d'abeille percé, l'écrou sort au serrage |
| aucun écrou ne mord l'anneau de joint | oreilles poussées trop loin, cordon de silicone coupé en quatre |
| la languette entre dans la rainure | v-sonde v5 : le couvercle était un plat |
| la fiche USB-C atteint la prise | ouverture au bon endroit mais trop courte |
| la pièce imprimée se retourne | v-sonde v6 : assemblage juste, pièce imprimée inutilisable |

Le verdict se prend sur le **volume** (`tools/volume-stl.py`, seuil 0,001 mm³),
pas sur l'existence du fichier.

### La contre-épreuve

Le banc rejoue ensuite chaque contrôle **avec son défaut réintroduit**, et
exige qu'il morde. Un contrôle qu'on n'a jamais vu échouer peut très bien ne
rien mesurer — c'est ce qui a été trouvé sur la visserie : sa position se
dérivant de la taille des cartes, elle ne pouvait *pas* tomber dessus. Le
contrôle était vrai par construction et ne prouvait rien. D'où `vis_marge`,
qui n'existe que pour rendre le défaut à nouveau exprimable.

Le contrôle de retournement fait exception : il ne se casse qu'en écrivant
`mirror()` au lieu de `rotate()` dans le `.scad`. Il reste un garde-fou de
régression, pas une mesure.

## Les cotes à relever

Photo avec le réglet dans le champ, et cote lue à la main — la méthode de la
[coque des sondes](../coque/README.md). Toutes portent `<< A MESURER` dans le
`.scad`.

**Carte LoRa** — `lora_l`, `lora_w`, `lora_t` · `lora_compo_h` (le plus haut
composant du dessus, l'écran) · `rang_bord` (bord du PCB → axe de la rangée) ·
`usb_l`, `usb_h`, `usb_y`, `usb_dz` · `bouton_ecart` · `ecran_l`, `ecran_w`,
`ecran_y`.

**Multiplexeur** — `mux_l`, `mux_w`, `mux_h`, `mux_compo_h`.

**Assemblage à blanc** — `fille_h`, **la cote qui décide de tout** : la hauteur
libre entre la face composants de la carte LoRa et le dessous de la carte
fille. Elle ne se calcule pas — elle dépend de la longueur de broche qui
dépasse, de la hauteur du corps de la barrette et de l'enfoncement réel. Elle
se mesure **une fois les deux cartes emboîtées à blanc**.

**Câble de sonde** — son diamètre extérieur, qui décide du presse-étoupe.

## Nomenclature du montage

| Élément | Quantité | Note |
|---|---|---|
| Filament PETG ou ASA | — | pas de PLA, il se délite en extérieur en une saison |
| Barrette femelle **tulipe** 2,54 mm, 1×40 à recouper | 1 | *machined / turned pin* — les modèles estampés n'apportent rien sur le Dupont |
| Plaque à pastilles ~50 × 35 mm | 2 | une pour la carte fille, une pour rater la première |
| Bornier à levier ou à vis | ~6 voies | reçoit les câbles de sondes |
| Presse-étoupe PG7 | 1 | perçage 12,5, collerette 19 — à confirmer sur le modèle acheté |
| Vis M3×10 **tête fraisée** inox | 4 | même visserie que la coque des sondes |
| Écrou M3 inox | 4 | pressé dans un logement hexagonal **borgne** des oreilles |
| Entretoise nylon M2,5 + vis | 2 | reprend le porte-à-faux de la carte fille |
| Silicone **neutre** | — | surtout pas acétique : il corrode le cuivre |

**Recouper une barrette tulipe se fait en sacrifiant une position** : la lame
passe dans un socket, qui est perdu. Contrairement aux barrettes estampées,
qu'on casse entre deux positions.

## Ce que la coque ne fait pas

Elle protège des projections et de la pluie. **Ce n'est pas un IP68
immersible.** Et elle ne dit rien de la tenue du montage dans la durée : c'est
[O7](../../docs/src/content/docs/objectifs/o7-mise-au-jardin.md) qui tranchera,
avec un mois de fonctionnement sans intervention.

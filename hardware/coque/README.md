# Coque de protection des sondes

Modèle paramétrique OpenSCAD pour protéger la partie haute des sondes
capacitives v1.2 (DollaTek, ASIN `B07L2RV1D2`) en extérieur.

**Le `.scad` est la source de vérité.** Les STL sont générés, jamais versionnés :

```console
$ just coque-stl          # produit hardware/coque/build/*.stl
$ just coque-test         # banc d'essai des ergots
$ just coque-preview      # ouvre le modèle dans OpenSCAD
```

## ⚠️ Avant d'imprimer

**Passe `just coque-test`.** Quatre contrôles, un par défaut déjà rencontré :

| Contrôle | Le défaut qu'il attrape |
|---|---|
| ergots contre la carte, décalée de ±0,7 et ±0,9 mm | v4 : `enc_y` faux de 14 mm, la carte ne s'encastrait pas |
| aucune vis ne traverse la carte | v5 : deux vis tombaient en plein dans le PCB |
| aucune cavité ne débouche dehors | v5 : quatre perçages traversaient la coque, à l'intérieur du joint |
| la languette entre dans la rainure | v5 : la coquille arrière était un couvercle plat |

Les trois derniers ont été validés en **réintroduisant le défaut** : un contrôle
qu'on n'a jamais vu échouer peut très bien ne rien mesurer.

Cotes encore à confirmer au pied à coulisse : `pcb_t`, `conn_dh`, `conn_h`.
Aucune n'est bloquante — ce sont des jeux, pas des positions. La liste est dans
l'en-tête de `coque.scad` et dans
[la documentation](../../docs/src/content/docs/materiel/coque-des-sondes.md).

## Ce que la coque ne fait pas

Elle protège des projections et de la pluie. **Ce n'est pas un IP68
immersible**, et surtout elle ne traite pas le vrai point faible de ces cartes :
les tranches nues du PCB, qui pompent l'humidité par capillarité jusqu'à
l'électronique.

Le vernissage de l'électrode et des chants est **indispensable**, pas
optionnel. Sans lui, la coque ne fait que retarder l'échéance.

## Nomenclature du montage

| Élément | Quantité | Note |
|---|---|---|
| Filament PETG ou ASA | — | pas de PLA, il se délite en extérieur en une saison |
| Vis M3×8 **tête fraisée** inox | 4 | la fraisure est dans la coquille arrière |
| Écrou M3 inox | 4 | pressé dans un logement hexagonal **borgne** du plan de joint |
| Silicone **neutre** | — | surtout pas acétique : il corrode le cuivre |
| Vernis PCB, résine époxy ou vernis à ongles transparent | — | 2 fines couches sur l'électrode et les chants |

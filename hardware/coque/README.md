# Coque de protection des sondes

Modèle paramétrique OpenSCAD pour protéger la partie haute des sondes
capacitives v1.2 (DollaTek, ASIN `B07L2RV1D2`) en extérieur.

**Le `.scad` est la source de vérité.** Les STL sont générés, jamais versionnés :

```console
$ just coque-stl          # produit hardware/coque/build/*.stl
$ just coque-preview      # ouvre le modèle dans OpenSCAD
```

## ⚠️ Avant d'imprimer

Les cotes du fichier sont des **estimations**. Sept mesures au pied à coulisse
sont à relever sur une sonde réelle et à reporter en tête de `coque.scad` — la
liste est dans l'en-tête du fichier et dans
[la documentation](../../docs/src/content/docs/materiel/coque-des-sondes.md).

`enc_y` est la cote qui pardonne le moins : fausse de plus d'un millimètre, la
carte ne se pose pas à plat et la coquille refuse de fermer.

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
| Vis M3×12 inox | 4 | avant-trou 2,5 mm dans la coquille avant |
| Silicone **neutre** | — | surtout pas acétique : il corrode le cuivre |
| Vernis PCB, résine époxy ou vernis à ongles transparent | — | 2 fines couches sur l'électrode et les chants |

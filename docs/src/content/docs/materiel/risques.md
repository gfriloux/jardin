---
title: Risques connus
description: Les pièges identifiés avant même d'avoir déballé le matériel, et comment on compte les détecter.
sidebar:
  order: 2
---

Chaque entrée suit le même format : le risque, pourquoi il existe, comment on
le détecte, et ce qu'on fait. Rien ici n'est résolu à l'avance — conformément au
[principe 5](/projet/principes/#5-on-ne-résout-pas-un-problème-avant-de-lavoir-rencontré),
on veut d'abord constater.

## Les cartes sont des clones, pas des Heltec

**Le risque.** La carte commandée est une « Heemol SX1262 LoRa V3 », clone de la
*Heltec WiFi LoRa 32 (V3)*. Le brochage est en général identique, mais rien ne
le garantit — et un brochage faux, c'est au mieux une soirée perdue, au pire une
carte morte.

Deuxième point : la Heltec V3 est marquée
« *Not actively maintained* » dans le registre des cartes PlatformIO. Le support
existe, mais personne ne le maintient activement.

**Le brochage de référence à vérifier**, tel que documenté pour la Heltec V3 :

| Fonction | GPIO |
|---|---|
| SX1262 `NSS` | 8 |
| SX1262 `SCK` | 9 |
| SX1262 `MOSI` | 10 |
| SX1262 `MISO` | 11 |
| SX1262 `RST` | 12 |
| SX1262 `BUSY` | 13 |
| SX1262 `DIO1` | 14 |
| OLED `SDA` / `SCL` / `RST` | 17 / 18 / 21 |
| `Vext` (alim périphériques, **actif à l'état bas**) | 36 |
| LED | 35 |
| Mesure batterie (via `ADC_Ctrl` GPIO 37) | 1 |
| Bouton `PRG` | 0 |

**Comment on détecte.** Premier test à faire à la réception, avant tout
câblage : flasher un croquis qui allume l'OLED et fait un `radio.begin()`
RadioLib. Si l'écran s'allume et que la radio répond, le brochage est le bon.

**Ce qu'on fait.** Ce test est le tout premier de
[O1](/objectifs/o1-une-sonde/). Si le brochage diffère, on le documente ici et
on le centralise dans un seul en-tête du firmware.

:::tip[Risque levé — 15 août 2026]
Les quatre croquis de validation passent sur la carte réelle : `01-blink` pour
la LED (35), `02-oled` pour `Vext` (36) et l'écran (17, 18, 21), `03-radio` pour
les sept broches SPI de la SX1262 (8 à 14), `04-sonde` pour l'entrée analogique
(7).

**Le clone Heemol suit le brochage Heltec V3 sans un seul écart.**
`firmware/include/board.h` n'a demandé aucune correction.

Reste vraie, en revanche, la seconde moitié du risque : la Heltec V3 est
toujours marquée « *Not actively maintained* » côté PlatformIO. C'est ce que la
version épinglée dans `platformio.ini` protège.
:::

## La powerbank va se couper en deep sleep

**Le risque.** La INIU 10 000 mAh, comme la quasi-totalité des powerbanks
grand public, coupe sa sortie quand le courant tiré passe sous un seuil (souvent
50–100 mA) pendant quelques dizaines de secondes. Un ESP32-S3 en deep sleep
consomme quelques dizaines de **micro**ampères. La powerbank va donc considérer
qu'on a débranché l'appareil, et couper.

Résultat typique : le nœud fonctionne parfaitement en test, puis « meurt » la
première nuit — sans que rien ne soit cassé.

**Comment on détecte.** Symptôme caractéristique : le nœud émet quelques trames
puis s'arrête définitivement, et repart dès qu'on touche au câble USB.

**Ce qu'on fait.** Rien pour l'instant : ce n'est un problème qu'à partir de
[O6](/objectifs/o6-autonomie/). D'ici là, le nœud reste alimenté en USB depuis
le PC. Quand le sujet arrivera, les options sont connues : batterie Li-ion
directement sur le connecteur de la carte (les Heltec V3 ont un chargeur
intégré), ou powerbank avec mode « faible consommation », ou pulse de charge
périodique — la première étant de loin la plus propre.

## Les sondes génériques ne sont pas vraiment étanches

**Le risque.** Les modules « Capacitive Soil Moisture Sensor V1.2 » à 1–3 € sont
partout, et beaucoup ne sont qu'un PCB recouvert d'une couche de vernis. Ce
n'est pas la même chose qu'une sonde conçue pour rester dans le sol. En
extérieur permanent, l'humidité finit par atteindre le cuivre, et la mesure part
en vrille avant que le module ne meure.

**Comment on détecte.** Dérive lente et monotone d'une sonde sur plusieurs
semaines, non corrélée aux autres sondes ni à la pluie.

**Ce qu'on fait.** Deux voies existent désormais, et la seconde n'existait pas
au lancement du projet :

1. **Sondes étanches du commerce** — type DFRobot SEN0308, annoncé IP65, sortie
   0–2,9 V, alimentation 3,3–5,5 V. Mal distribuées en France : RS autour de
   18 €, Farnell annonce des livraisons à partir de septembre 2026, Mouser
   applique des restrictions aux particuliers de l'UE.
2. **Protéger les sondes génériques** — une [coque imprimée en
   3D](/materiel/coque-des-sondes/) sur la partie haute, plus un vernissage de
   l'électrode et des chants. La coque n'est plus une intention : elle est
   **imprimée et validée au montage**, à ~0,20 € de filament la pièce contre
   18 € la sonde étanche.

La décision se prendra à [O7](/objectifs/o7-mise-au-jardin/), à la lumière du
comportement réel des sondes pendant le POC.

:::danger[Le vernissage n'est pas optionnel]
Quelle que soit la voie retenue, le vrai point faible de ces cartes est
constitué des **tranches nues du PCB**, qui pompent l'humidité par capillarité
jusqu'à l'électronique. Deux fines couches de vernis PCB, de résine époxy ou de
vernis à ongles transparent, en insistant sur les chants coupés, **avant toute
mise en terre** — même pour un test de quelques jours.

Et surtout : **ne jamais recouvrir l'électrode d'une coque**. La mesure se fait
à travers le vernis du PCB ; 2 mm de plastique et une lame d'air feraient
chuter la sensibilité à presque rien. Une fine couche de vernis, elle, ne
dégrade quasiment pas la mesure.
:::

## Il n'y a que trois sondes

**Le risque.** Le plan initial parlait de quatre sondes, voire six. Avec trois,
une sonde qui meurt ou qui dérive ramène la comparaison à deux points — ce qui
suffit à voir un écart, mais pas à savoir laquelle des deux a tort.

**Ce qu'on fait.** On commence à trois, et l'expérience de comparaison en pot
unique de [O3](/objectifs/o3-calibration/) devient d'autant plus importante :
c'est elle qui dira si un deuxième lot est nécessaire. Un lot supplémentaire
coûte 7 € et arrive en deux jours ; ce n'est pas un blocage.

## L'ADC de l'ESP32-S3 est médiocre

**Le risque.** Deux problèmes distincts.

1. **Non-linéarité.** Les ADC des ESP32 sont notoirement non linéaires,
   surtout aux extrémités de la plage. Une variation de 10 points en bas
   d'échelle ne représente pas la même variation de tension qu'en haut.
2. **ADC2 est inutilisable avec le Wi-Fi.** Sur ESP32-S3, `ADC1` couvre
   GPIO 1–10 et `ADC2` GPIO 11–20 ; `ADC2` est réquisitionné par la radio Wi-Fi
   dès qu'elle est active.

**Ce qu'on fait.** Deux règles de câblage, fixées dès maintenant :

- la sortie du multiplexeur va sur une broche **ADC1** ;
- le nœud **n'active jamais le Wi-Fi** (il n'en a aucun besoin : la liaison est
  LoRa).

La non-linéarité, elle, est absorbée par la calibration — c'est précisément
pour ça qu'on [stocke le brut](/decisions/#adr-002--on-stocke-la-valeur-adc-brute).

## Le multiplexeur n'a pas de date de livraison

**Le risque.** `B07TXPQ2VM` est la seule commande sans date annoncée. Elle
bloque [O2](/objectifs/o2-multiplexage/).

**Ce qu'on fait.** Rien : le chemin `O1 → O4` ne passe pas par le multiplexeur.
Si le colis tarde, on avance sur le lien radio avec une sonde unique, et O2
s'intercalera quand le matériel arrivera. C'est exactement ce que montre le
graphe de la [feuille de route](/projet/feuille-de-route/#le-graphe).

## Ne jamais alimenter la carte sans antenne

**Le risque.** Émettre sur un SX1262 sans antenne connectée renvoie la puissance
dans l'étage de sortie. C'est le moyen le plus rapide de détruire une carte
LoRa neuve.

**Ce qu'on fait.** Règle absolue : **antenne montée avant la première mise sous
tension**, sur les deux cartes, y compris pour un simple test d'OLED. Le coût
d'appliquer cette règle est nul, celui de l'oublier est de 25 €.

Côté carte, le connecteur est une prise u.FL qui se **clipse** — il n'y a pas de
filetage. Le pas de vis se trouve à l'autre extrémité de la queue de cochon.

Le firmware d'usine de nos cartes affiche `LORA MODE 0` dès le démarrage : la
radio est donc initialisée avant toute intervention. La règle n'est pas
théorique, le risque existe au tout premier branchement.

## Une sonde déchaussée est indétectable

**Le risque.** Mesuré en O1 le 15 août 2026 : la terre sèche lit 2680,3 et l'air
libre 2683,9. **3,6 points d'écart**, contre 37 points de reproductibilité entre
deux séances. Les deux états sont électriquement indiscernables.

Une sonde qui sort du sol — gel, animal, coup de bêche, affaissement du terrain
après un arrosage — produit donc une lecture parfaitement crédible de « sol très
sec ». Rien dans la valeur ne trahit l'anomalie.

Sur une chaîne qui déclenche un arrosage en
[O9](/objectifs/o9-irrigation/), ce scénario mène à arroser en continu, sur un
sol qui n'en a pas besoin, jusqu'à ce que quelqu'un s'en aperçoive.

**Ce qu'on fait.** Rien pour l'instant : le risque est identifié, pas traité.
Les pistes, par ordre de simplicité :

- **Un plafond de durée d'arrosage**, qui borne les dégâts quelle que soit la
  cause. C'est le garde-fou le moins cher et le plus robuste, à poser dès que
  O9 existera.
- **Un seuil de vraisemblance sur la vitesse de variation.** Une sonde
  déchaussée passe à « sec » en quelques minutes ; un sol met des jours. Une
  chute trop rapide est un signal d'anomalie, pas de sécheresse.
- **Une seconde grandeur corrélée**, typiquement la température du sol, dont le
  comportement change franchement à l'air libre.

Aucune ne se décide avant d'avoir vu le comportement réel sur le terrain en
[O7](/objectifs/o7-mise-au-jardin/).

## Le rapport cyclique EU868

**Le risque.** En Europe, la bande 863–870 MHz impose un rapport cyclique
d'environ **1 %** sur la plupart des sous-bandes : un paquet qui met 100 ms à
partir interdit de réémettre pendant 10 s. Une boucle de test qui émet en
continu est illégale, et surtout donnera des résultats de portée non
représentatifs.

La carte étant vendue « 863–928 MHz », il faudra en outre **explicitement
configurer 868 MHz** dans le firmware — le défaut du module peut être ailleurs.

**Ce qu'on fait.** La fréquence et la période minimale d'émission sont des
constantes du firmware, posées dès [O4](/objectifs/o4-lien-radio/), avec un
garde-fou qui refuse d'émettre trop tôt.

## Les straps Dupont ne sont pas des câbles

**Le risque.** Les sondes seront à plusieurs mètres du nœud. Les straps Dupont
20 cm servent **uniquement au prototypage sur la table** : contacts non
maintenus, section minuscule, aucune tenue mécanique, aucun blindage.

**Ce qu'on fait.** Ils ne sortent jamais de la table. Le câblage réel du jardin
est un sujet à part entière de [O7](/objectifs/o7-mise-au-jardin/), et la
section comme le blindage seront choisis à partir du bruit effectivement
mesuré — pas avant.

---
title: Décisions d'architecture
description: Les choix structurants, leur contexte, leurs conséquences et ce qui les ferait changer.
---

Chaque décision note ce qui la **remettrait en cause**. Une décision sans
condition de révision est un dogme, et un dogme dans un projet de jardin finit
toujours par coûter un week-end.

**Statuts :** ✅ actée · 🔄 provisoire, révision planifiée · ❓ ouverte

---

## ADR-001 — LoRa point-à-point plutôt que LoRaWAN

**Statut :** ✅ actée · 13 août 2026

**Contexte.** Le terrain est privé, on parle de 5 à 20 nœuds à terme, et les
mesures sont périodiques et minuscules. LoRaWAN apporte l'adressage, la
sécurité, l'itinérance et la gestion de flotte — dont rien n'est nécessaire ici.

**Décision.** LoRa brut, protocole maison très simple, MQTT côté passerelle.

**Conséquences.**

- Pas de serveur de réseau à héberger, pas de clés à provisionner, pas de
  *join procedure* à déboguer.
- Le rapport cyclique EU868 reste à notre charge : c'est au firmware de le
  respecter.
- Pas de chiffrement au départ. Acceptable : les données sont des taux
  d'humidité de fraisiers. À revoir si des actionneurs entrent dans la boucle
  (voir [O9](/objectifs/o9-irrigation/)) — commander une électrovanne par radio
  non authentifiée serait une autre affaire.

**Ce qui la changerait.** Passer la cinquantaine de nœuds, vouloir profiter
d'une infrastructure LoRaWAN existante (TTN), ou avoir besoin d'actionneurs
commandés à distance.

---

## ADR-002 — On stocke la valeur ADC brute

**Statut :** ✅ actée · 13 août 2026

**Contexte.** Une sonde capacitive produit une grandeur électrique. La
convertir en pourcentage d'humidité suppose de connaître le type de sol, sa
composition, sa salinité, la profondeur, le modèle de sonde et son implantation.
Aucune de ces informations n'est connue aujourd'hui, et plusieurs varieront dans
le temps.

**Décision.** La mesure stockée est le nombre d'ADC, avec `unit = raw`. La
calibration est une couche dérivée, appliquée à la lecture.

**Conséquences.**

- Les premiers graphes seront des nombres sans signification physique. C'est
  assumé : leur **forme** est déjà exploitable.
- Le jour où la calibration change, tout l'historique se recalcule.
- Deux entités par sonde côté Home Assistant : la brute et la calibrée.

**Ce qui la changerait.** Rien. C'est le genre de décision qu'on ne regrette
jamais — l'inverse, si.

---

## ADR-003 — Modèle de données générique

**Statut :** ✅ actée · 13 août 2026

**Contexte.** L'objectif n'est pas « des sondes pour les fraisiers » mais « un
réseau de télémétrie du terrain ». Un schéma qui code en dur l'humidité du sol
condamne à une migration au premier capteur de température.

**Décision.** Le tuple `node_id / sensor_id / timestamp / measurement_type /
value / unit`. Le serveur ignore le matériel qui produit la mesure.

**Conséquences.** Voir [le modèle de données](/projet/modele-de-donnees/).
Coût : un peu plus de cérémonie que « une colonne par capteur ». Bénéfice : un
nouveau type de capteur ne touche pas au serveur.

**Ce qui la changerait.** Rien de prévu.

---

## ADR-004 — Deux cartes identiques, pas de passerelle LoRaWAN

**Statut :** 🔄 provisoire · révision à [O7](/objectifs/o7-mise-au-jardin/)

**Contexte.** Une vraie passerelle SX1302/SX1303 coûte 100 € et plus. L'objectif
du POC est de démontrer que le lien fonctionne, pas d'exploiter un réseau.

**Décision.** Deux cartes identiques : `NODE-001` dans le jardin,
`GATEWAY-001` branchée en USB sur le PC. La seconde carte est un récepteur LoRa
minimal.

**Conséquences.**

- Un seul canal, un seul facteur d'étalement à la fois, pas de réception
  simultanée de plusieurs nœuds sur des réglages différents.
- Suffisant jusqu'à quelques nœuds qui se partagent le même réglage radio.
- Rien n'est jeté quand on changera : la carte devient un nœud de plus.

**Ce qui la changerait.** Plus de trois ou quatre nœuds, ou des collisions
observées.

---

## ADR-005 — Firmware en PlatformIO + Arduino + RadioLib

**Statut :** ✅ actée · 13 août 2026

**Contexte.** Trois options : PlatformIO/Arduino avec RadioLib, ESP-IDF nu, ou
Rust `esp-hal`.

**Décision.** PlatformIO + framework Arduino + RadioLib.

**Pourquoi.** RadioLib gère très bien le SX1262 des cartes Heltec V3 et
l'écosystème d'exemples est massif — ce qui compte quand la carte est un clone
au brochage à vérifier. `platformio-core` est packagé dans nixpkgs, donc le
devshell reste propre. Les deux alternatives sont meilleures sur le long terme
mais coûtent du temps là où on veut aller vite : ESP-IDF sur la gestion du deep
sleep, Rust sur un écosystème Heltec V3 bien moins balisé.

**Conséquences.** La couche Arduino masque une partie du contrôle fin de
l'alimentation et du sommeil, ce qui se paiera peut-être à
[O6](/objectifs/o6-autonomie/). On accepte de migrer vers ESP-IDF à ce
moment-là si les chiffres de consommation ne tiennent pas.

**Ce qui la changerait.** Une consommation en deep sleep qu'on n'arrive pas à
faire descendre sous quelques centaines de µA.

---

## ADR-006 — Collecteur en Rust

**Statut :** ✅ actée · 13 août 2026

**Contexte.** Le collecteur lit la liaison série de `GATEWAY-001`, horodate,
publie en MQTT et écrit l'archive NDJSON. C'est un daemon qui doit tourner des
mois sans surveillance.

**Décision.** Rust — `serialport` + `rumqttc`.

**Pourquoi.** Un binaire unique sans runtime, packageable aussi bien en
dérivation Nix qu'en image de conteneur minimale. Le programme est petit et son
domaine est stable : c'est exactement le cas où le coût d'entrée de Rust est le
plus faible et son bénéfice de robustesse le plus direct.

**Conséquences.**

- `serialport` se lie à `libudev` — `pkg-config` et `udev` sont dans le
  devshell, et devront l'être aussi dans l'image de build.
- Depuis [ADR-011](#adr-011--la-stack-serveur-est-un-jeu-de-conteneurs), la
  cible de déploiement est un conteneur plutôt qu'un service systemd. Le choix
  de Rust n'en est pas affecté : un binaire statique dans une image `scratch`
  ou `distroless` est ce qui se conteneurise le mieux.

**Ce qui la changerait.** Rien de prévu.

---

## ADR-007 — Home Assistant via MQTT discovery

**Statut :** 🔄 **révisée le 13 août 2026** — voir
[ADR-012](#adr-012--larchive-ndjson-est-le-bus-mqtt-sort-du-chemin-principal)
et [ADR-014](#adr-014--grafana-dabord-interface-maison-différée)

**Contexte.** Trois familles d'options : une TSDB dédiée avec Grafana
(InfluxDB, ou PostgreSQL/TimescaleDB), ou Home Assistant.

**Décision.** Home Assistant, alimenté par MQTT discovery, plus une archive
NDJSON brute sur disque en parallèle.

**Pourquoi.** Les entités apparaissent seules, l'historique, les graphes et les
automatisations sont fournis, et surtout : [O9](/objectifs/o9-irrigation/)
devient presque gratuit le jour où on y arrivera, alors qu'avec Grafana il
faudrait construire toute la couche de commande.

**Conséquences.**

- Le recorder de Home Assistant est fait pour de l'état d'entité, pas pour de
  l'analyse au long cours : purges agressives par défaut, requêtes croisées
  pénibles. D'où l'archive NDJSON, qui n'est pas une redondance mais **la**
  source de vérité pour l'analyse de calibration.
- Ne pas annoncer de `device_class` ni d'unité sur les valeurs brutes.

**Ce qui l'a changée.** Un objectif exprimé après coup : construire une **carte
du jardin**, y placer les sondes, et faire tourner des algorithmes par zone.
Home Assistant n'a aucun modèle spatial — ses « zones » sont des pièces
logiques, sans géométrie ni coordonnées, et son recorder n'a pas de capacité de
requête spatiale. La carte `picture-elements` affiche, elle n'analyse pas. Les
algorithmes finiraient en composant Python maison branché sur HA : écrire le
système soi-même, mais dans un carcan.

**Où en est HA aujourd'hui.** Hors du chemin principal, conservé dans le
`compose.yaml` derrière un profil `ha`. Il reste bon à ce pour quoi il avait été
choisi — automatisations, reprise en main manuelle, notifications mobiles — et
pourrait revenir pour la commande d'arrosage de [O9](/objectifs/o9-irrigation/),
alimenté par une sortie MQTT ajoutée au collecteur. Rien n'est fermé.

---

## ADR-008 — Le POC tourne sur le PC de dev

**Statut :** 🔄 provisoire · **remplacée en partie par
[ADR-011](#adr-011--la-stack-serveur-est-un-jeu-de-conteneurs)** · 13 août 2026

**Contexte.** Le serveur définitif n'est pas choisi.

**Décision.** Pendant le POC, `GATEWAY-001`, le collecteur, le broker et Home
Assistant tournent sur le poste de développement.

**Conséquences.** Pas de mesures la nuit quand le PC est éteint, ce qui est
gênant pour observer un cycle d'assèchement complet.

**Ce qui a changé.** La question « quelle machine ? » a perdu son caractère
structurant : ADR-011 rend la stack portable, donc la migration devient un
`docker compose up` ailleurs. Ce qui reste à décider à
[O7](/objectifs/o7-mise-au-jardin/) est un choix d'exploitation — quelle
machine reste allumée — et non plus un choix d'architecture.

---

## ADR-009 — Un nœud central câblé, pas plusieurs petits nœuds radio

**Statut :** ✅ actée pour la zone fraisiers · ❓ ouverte pour le reste du terrain

**Contexte.** Deux architectures possibles.

```text
Option A                          Option B
sondes ─câbles─> boîtier unique   [sondes] → [nœud LoRa] )))
                                  [sondes] → [nœud LoRa] )))  → passerelle
                                  [sondes] → [nœud LoRa] )))
```

**Décision.** Option A pour l'allée de 15 m.

**Pourquoi.** Une seule batterie, une seule alimentation solaire, un seul
boîtier, un seul point de panne, une seule maintenance. L'option B multiplie
tout ça pour couvrir une distance que du câble couvre très bien.

**Conséquences.** Il faut tirer les câbles, et une sonde analogique au bout de
plusieurs mètres n'est pas triviale — c'est le risque principal de
[O7](/objectifs/o7-mise-au-jardin/).

**Ce qui la changerait.** L'extension à d'autres zones du terrain (potager,
verger) basculera naturellement vers B : un nœud par zone, chacun en option A
localement. Les deux options coexisteront.

---

## ADR-010 — Documentation Astro Starlight, environnement Nix

**Statut :** ✅ actée · 13 août 2026

**Contexte.** Le projet va s'étaler sur des mois, avec des interruptions
longues. Ce qui n'est pas écrit sera reperdu.

**Décision.** Un `flake.nix` fournissant tout l'outillage (Node, PlatformIO,
Rust, mosquitto), et une documentation Astro Starlight versionnée avec le code
dans `docs/`.

**Conséquences.** `nix develop` suffit à reprendre le projet six mois plus tard
sans rien réinstaller. La doc n'est pas un sous-produit : un objectif n'est
tenu que quand sa page est écrite.

**Ce qui la changerait.** Rien de prévu.

---

## ADR-011 — La stack serveur est un jeu de conteneurs

**Statut :** ✅ actée · 13 août 2026

**Contexte.** [ADR-008](#adr-008--le-poc-tourne-sur-le-pc-de-dev) laissait
ouverte la question de la machine hôte, à trancher en
[O7](/objectifs/o7-mise-au-jardin/) : poste de développement, machine NixOS
existante, ou Raspberry Pi dédié. Trancher tôt aurait figé le déploiement ;
trancher tard laissait planer une migration douloureuse.

**Décision.** La partie serveur — broker MQTT, Home Assistant, collecteur — est
décrite dans un `stack/compose.yaml` unique. Le choix de la machine devient une
question d'exploitation, plus une question d'architecture.

**Pourquoi.** C'est ce qui rend la solution pérenne : le même fichier tourne
sur le poste de développement aujourd'hui, sur un Raspberry Pi cet hiver, sur
autre chose dans trois ans. La migration se réduit à copier un répertoire et
relancer `docker compose up`.

**Conséquences.**

- **Le collecteur doit accéder au port série depuis un conteneur.** C'est la
  contrainte réelle introduite par ce choix : `devices: [/dev/…]` dans le
  compose, et surtout une **règle udev donnant un nom stable** à la passerelle,
  sinon `ttyUSB0` devient `ttyUSB1` au premier rebranchement et le conteneur
  refuse de démarrer. Détail dans `stack/README.md`.
- **Le collecteur devient une image, pas un binaire système.** Cela ne
  contredit pas [ADR-006](#adr-006--collecteur-en-rust) : un binaire Rust
  statique dans une image `scratch` ou `distroless` est précisément ce qui se
  conteneurise le mieux. Nix peut d'ailleurs construire l'image directement
  avec `dockerTools.buildLayeredImage`, sans Dockerfile, ce qui préserve la
  reproductibilité.
- **L'archive NDJSON reste hors volume Docker**, en clair sur l'hôte dans
  `stack/data/`. C'est la source de vérité de l'analyse de calibration : elle
  doit survivre à un `docker compose down -v` distrait.
- **Le broker n'est publié que sur la boucle locale.** Il accepte les
  connexions anonymes ; l'exposer au réseau permettrait à n'importe quel
  appareil du LAN d'injecter de fausses mesures. Home Assistant et le
  collecteur l'atteignent par le réseau interne de la stack.

**Ce qui la changerait.** Un besoin d'intégration système poussée qui rendrait
le conteneur plus gênant qu'utile — auquel cas la cible naturelle serait un
module NixOS, et le collecteur Rust s'y prêterait tout aussi bien.

---

## ADR-012 — L'archive NDJSON est le bus, MQTT sort du chemin principal

**Statut :** ✅ actée · 13 août 2026

**Contexte.** MQTT avait été retenu comme transport entre le collecteur et Home
Assistant. Avec un seul producteur et un seul consommateur, son apport de
découplage était mince : il était surtout **l'adaptateur de Home Assistant**.
Or [ADR-007](#adr-007--home-assistant-via-mqtt-discovery) a été révisée.

**Décision.** Le collecteur n'écrit que l'archive NDJSON. Un **importeur**
séparé relit l'archive et alimente MariaDB.

```text
collecteur ──> NDJSON ──> importeur ──> MariaDB ──> Grafana
              (vérité)    (rejouable)
```

**Pourquoi.** Le collecteur ne connaît ni SQL ni MQTT : il sait écrire des
lignes. Comme l'archive contient le brut, **rejouer tout l'historique après un
changement de calibration est un réimport**, sans code supplémentaire — c'est
exactement ce que promettait [ADR-002](#adr-002--on-stocke-la-valeur-adc-brute).
La base peut tomber, être migrée ou changée de moteur sans qu'on perde quoi que
ce soit.

**Conséquences.**

- Un conteneur de moins dans le chemin principal (le broker).
- Deux processus au lieu d'un, mais **une seule image** : le binaire Rust
  expose deux sous-commandes, `collect` et `import`.
- L'idempotence du réimport repose sur l'unicité de `(source_file,
  source_line)` dans la table `frame`. C'est ce qui rend le rejeu sûr.
- MQTT reste ajoutable comme **sortie supplémentaire** du collecteur, sans rien
  casser, si Home Assistant revient pour [O9](/objectifs/o9-irrigation/).

**Ce qui la changerait.** L'arrivée de plusieurs consommateurs temps réel
indépendants — c'est là que MQTT reprendrait tout son sens.

---

## ADR-013 — MariaDB plutôt que PostgreSQL

**Statut :** ✅ actée · 13 août 2026

**Contexte.** Le besoin exprimé — carte du terrain, positions des sondes, zones
et algorithmes par zone — appelle une base capable de géométrie. Le réflexe
serait PostgreSQL avec PostGIS.

**Décision.** MariaDB.

**Pourquoi.**

- **Le spatial nécessaire y est.** Types `POINT` et `POLYGON`, index `SPATIAL`
  sur InnoDB, et les fonctions utiles : `ST_Contains`, `ST_Within`,
  `ST_Distance`, `ST_Intersects`. « Cette sonde est-elle dans cette zone » est
  du natif.
- **Ce que PostGIS a en plus ne sert pas ici.** Calculs géodésiques sur
  sphéroïde, transformations de projections, raster : les zones sont en
  **repère local, en mètres**. Pour un jardin, la courbure de la Terre
  n'intervient pas.
- **Le volume est négligeable** : 20 sondes toutes les 5 minutes ≈ 2 millions
  de lignes par an.
- **L'exploitation prime, à équivalence technique.** Les montées de version
  majeures de PostgreSQL sont pénibles, et c'est le moteur que l'auteur du
  projet connaît le moins. Quand deux options se valent, celle qu'on sait
  exploiter gagne.

**Conséquences.**

- Le choix est **peu risqué et réversible** : la base n'est qu'un index dérivé
  de l'archive (ADR-012). Migrer, c'est vider et réimporter.
- Les vues utilisent `JSON_VALUE`, disponible à partir de MariaDB 10.9 — l'image
  est épinglée sur `mariadb:11`.
- Pas de kriging ni d'interpolation en base. Ce n'est pas un manque : voir
  l'avertissement sur les zones dans
  [le modèle de données](/projet/modele-de-donnees/#les-zones).

**Ce qui la changerait.** Un besoin réel de géodésie ou de raster, ce qui
supposerait de sortir de l'échelle du jardin.

---

## ADR-014 — Grafana d'abord, interface maison différée

**Statut :** ✅ actée · 13 août 2026

**Contexte.** L'objectif à terme est une carte du jardin avec les sondes
positionnées et des algorithmes de zones. Aucun logiciel libre ne fait
exactement cela : [farmOS](https://farmos.org/model/) est le plus proche sur la
géométrie — ses *land assets* portent une géométrie dessinée sur carte et ses
*data streams* reçoivent des séries temporelles par API — mais c'est un système
de tenue de registre agricole : il stocke et affiche, il n'analyse pas.
ThingsBoard est fort sur les règles, faible sur la géométrie de jardin, et son
stockage est PostgreSQL.

**Décision.** Grafana sur MariaDB pendant tout le POC, aucune ligne de
frontend. Interface maison différée à [O8](/objectifs/o8-exploitation/).

**Pourquoi.** **La carte ne sert à rien avant d'avoir assez de sondes.** Avec
trois sondes alignées, une carte est une décoration : on voit trois points dont
on connaît déjà les valeurs. Les zones ne deviennent un objet utile que
lorsqu'il y en a plusieurs, instrumentées différemment — soit O7 au plus tôt. Et
à ce moment-là, on saura ce qu'on veut y voir, ce qui est le
[principe 5](/projet/principes/#5-on-ne-résout-pas-un-problème-avant-de-lavoir-rencontré).

**Conséquences.**

- Source de données MySQL/MariaDB native dans Grafana, provisionnée par
  fichier — rien à cliquer.
- Le panneau **Canvas** permet déjà de poser des éléments sur une image de fond :
  une carte grossière du jardin, sans code.
- Le modèle de données prévoit les zones **dès maintenant**, ce qui évite une
  migration douloureuse le jour où l'interface arrive.

**Ce qui la changerait.** Le moment où les zones auront un sens : assez de
sondes, réparties sur plusieurs zones, avec des comportements différents.

---

## ADR-015 — On détecte un seuil, on ne mesure pas une humidité

**Statut :** ✅ actée · 15 août 2026

**Contexte.** La caractérisation de [O1](/objectifs/o1-une-sonde/) a produit des
chiffres flatteurs : 1481 points de dynamique entre terre sèche et terre
saturée, 3 points de bruit instantané, des sondes qui divergent de moins de 8
points. La tentation qui vient avec est de raffiner — étalonner chaque sonde,
contrôler le décalage des canaux d'ADC, imposer une profondeur de pose au
millimètre.

Cette tentation confond la qualité de l'instrument avec le besoin.

**Décision.** Le système répond à une question binaire : **faut-il arroser ?**
Il ne prétend pas mesurer un taux d'humidité, ni maintenant ni plus tard.

**Pourquoi.** Personne ne consultera un pourcentage. Ce qu'on veut savoir, c'est
si la terre est devenue sèche au point qu'il faille intervenir — une décision à
deux issues, dont le seuil se découvrira en regardant sécher le sol réel, pas en
raffinant l'électronique sur une table.

**Conséquences.**

- **Ce que ça retire du travail.** L'étalonnage par sonde n'a pas lieu d'être :
  8 points de divergence sur 1481 sont sans effet sur un seuil. Le décalage des
  canaux d'ADC1 ne sera pas mesuré. Le gabarit de profondeur envisagé pour la
  pose devient superflu — un centimètre d'écart vaut une centaine de points,
  soit 7 % de la plage, invisible pour une décision grossière.
- **Ce que ça promeut.** La **fiabilité dans la durée** passe devant la
  justesse : une sonde qui dérive de 5 % par an est un problème, une sonde qui
  lit 8 points à côté n'en est pas un.
- **Le risque dominant devient la
  [sonde déchaussée](/materiel/risques/#une-sonde-déchaussée-est-indétectable)**,
  qui lit comme une terre sèche et déclencherait donc un arrosage permanent.
  C'est le seul écart qui trompe la décision au lieu de la nuancer.
- Le seuil lui-même est un résultat de [O8](/objectifs/o8-exploitation/),
  obtenu en observant des courbes d'assèchement réelles sur plusieurs semaines.
  Il n'est pas dérivable des mesures de table.
- L'[ADR-002](#adr-002--on-stocke-la-valeur-adc-brute) s'en trouve renforcée :
  puisque le seuil est empirique et révisable, stocker le brut permet de le
  changer d'avis sans perdre l'historique.

**Ce qui la changerait.** Un usage qui demanderait une grandeur physique
comparable entre jardins ou publiable — pilotage agronomique fin, comparaison
avec des données externes. Rien de tel n'est au programme.

---

## ADR-016 — Le seuil d'arrosage est un réglage par zone, pas une constante

**Statut :** ✅ actée · 15 août 2026

**Contexte.** [L'ADR-015](#adr-015--on-détecte-un-seuil-on-ne-mesure-pas-une-humidité)
pose que le système détecte un seuil. Restait à savoir d'où sort ce seuil, et
comment il encaisse tout ce qui fait qu'une valeur brute n'est pas comparable
d'un point à l'autre du jardin :

- la divergence entre sondes — mesurée à moins de 8 points en
  [O3](/objectifs/o3-calibration/), donc négligeable ;
- la profondeur de pose, qui vaut de l'ordre de cent points par centimètre ;
- le type de sol, qui change d'une planche à l'autre ;
- et surtout **les besoins de la plante**, qui n'ont aucune raison d'être les
  mêmes pour des fraisiers et pour un pied qui veut la terre humide.

**Décision.** Le seuil de déclenchement est une **propriété de la zone**,
pré-remplie par une valeur par défaut et modifiable à l'usage. Une surcharge par
sonde reste possible, pour absorber une profondeur de pose atypique.

**Pourquoi.** Le seuil se règle contre la seule référence qui compte : **l'état
de la plante**. Si les fraisiers souffrent alors que la sonde annonce 2400, on
descend le seuil de cette zone et on n'a plus jamais à se demander pourquoi.

Ce faisant, **tous les termes d'erreur disparaissent d'un coup** — divergence,
profondeur, type de sol, modèle de sonde. Ils sont absorbés par le réglage, sans
jamais avoir besoin d'être mesurés séparément. C'est ce qui rend inutile la
calibration par sonde que O3 envisageait.

**Conséquences.**

- Les seuils vivent en base, à côté des zones, et s'appliquent **à la lecture**
  comme la calibration de
  [l'ADR-002](#adr-002--on-stocke-la-valeur-adc-brute). Les changer ne réécrit
  rien : l'historique reste brut, et se relit avec le seuil du jour.
- L'appartenance d'une sonde à une zone est déjà **déclarée et datée** dans le
  [modèle de données](/projet/modele-de-donnees/#les-zones). Le seuil suit la
  même logique : une valeur, une date d'entrée en vigueur.
- **Deux seuils, pas un.** Un seuil unique fait battre la commande : le sol
  repasse au-dessus dès l'arrosage, puis redescend. Il faut un seuil de
  déclenchement et un seuil d'arrêt plus haut, ou un délai minimal entre deux
  arrosages. La mesure de O1 le confirme — la sonde **descend deux à trois fois
  plus vite qu'elle ne remonte**, donc le retour au sec est lent et l'humidité
  après arrosage est trompeuse.
- La granularité est la **zone**, pas la sonde. Avec 8 points de divergence pour
  1481 de dynamique, un réglage par sonde serait un bouton de plus à entretenir
  pour un effet non mesurable. La surcharge par sonde existe pour la profondeur,
  pas pour la sonde elle-même.

**Ce qui la changerait.** Rien de prévisible. Si un jour un seuil unique
suffisait à tout le jardin, le réglage par zone resterait compatible — il
serait simplement partout identique.

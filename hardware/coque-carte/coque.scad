// =========================================================
//  Coque des cartes LoRa - Heemol / Heltec WiFi LoRa 32 (V3)
//
//  VERSION 1 : bac + couvercle, joint rainure + languette,
//  4 vis M3 a tete fraisee sur ecrous noyes, cartes EMPILEES.
//
//  Une seule coque pour NODE-001 et GATEWAY-001. Les deux
//  cartes portent la meme rangee de 18 broches soudee, meme si
//  la passerelle n'en a pas l'usage : elles restent ainsi
//  interchangeables si l'une meurt au jardin.
//
//  ---------------------------------------------------------
//  LES COTES SONT PROVISOIRES. Tout ce qui porte
//  << A MESURER n'a jamais rencontre un pied a coulisse : ce
//  sont les valeurs publiees par Heltec pour la V3, et notre
//  carte est un clone. La geometrie, elle, est arretee.
//  ---------------------------------------------------------
//
//  Principe de l'empilage, de bas en haut :
//
//    +--------------------------------------------+ couvercle
//    |          [ ouverture ecran ]               |
//    |   +--------+                               |
//    |   |  mux   |            [borniers]         | etage 2
//    |   +--------+                               |
//    |  =============carte fille==============    | etage 1
//    |           || barrette tulipe ||            |
//    |  ---------carte LoRa------------------     | etage 0
//    |   o   o                          o   o     | plots
//    +--------------------------------------------+ fond
//
//  L'etage 1 n'est pas un luxe : les huit broches de commande
//  du CD74HC4067 ne tombent jamais en face des bonnes broches
//  Heltec. Il faut une piece qui reordonne, et c'est elle.
//
//  Elle se pose sur la rangee par une barrette femelle TULIPE
//  1x18 soudee dessous. Les 18 positions sont prises alors que
//  7 suffisent : les onze inutilisees ne portent aucun signal
//  mais font toute la tenue mecanique. Deux entretoises au bord
//  oppose reprennent le porte-a-faux, sans quoi la barrette
//  encaisserait seule tous les efforts.
//
//  ---------------------------------------------------------
//  LA COTE QUI DECIDE DE TOUT : fille_h
//
//  C'est la hauteur libre entre la face composants de la carte
//  LoRa et le dessous de la carte fille. Elle ne se calcule
//  pas : elle depend de la longueur de broche qui depasse, de
//  la hauteur du corps de la barrette tulipe et de la
//  profondeur d'enfoncement reelle. Elle se MESURE une fois les
//  deux cartes emboitees a blanc, au pied a coulisse.
//
//  Si elle est trop faible, la carte fille s'assoit sur l'ecran
//  OLED. C'est le mode de panne propre a l'empilage, et c'est
//  le premier controle du banc d'essai.
//  ---------------------------------------------------------
//
//  Le nœud est BOUCHE, la passerelle est OUVERTE. Trois pieces
//  imprimees a part ferment l'USB-C, les boutons et l'ouverture
//  d'ecran. La passerelle vit sur un bureau et les laisse
//  ouverts ; le nœud vit dehors et les bouche tous les trois.
//  Il ne perd rien : son ecran est de toute facon masque par la
//  carte fille, et O6 cherchera a l'eteindre pour economiser la
//  batterie.
//
//  Impression : chaque piece a plat, sans supports. PETG ou ASA
//  (PAS de PLA, il se delite en exterieur en une saison),
//  3 perimetres.
//
//  Montage : 4 ecrous M3 presses dans les logements hexagonaux
//  des oreilles, joint silicone NEUTRE (pas acetique, il corrode
//  le cuivre) dans la rainure, carte LoRa posee sur ses plots,
//  carte fille enfichee puis vissee sur ses deux entretoises,
//  multiplexeur enfiche en dernier, couvercle, 4 vis M3x10 a
//  tete fraisee inox.
//
//  M3 et non M2,5 : c'est la visserie de la coque des sondes.
//  Un seul diametre sur tout le projet vaut mieux qu'un gain de
//  4 mm d'encombrement.
//
// =========================================================

/* [Piece a exporter] */
piece = "fond";  // ["fond","couvercle","bouchon-usb","bouchon-boutons","bouchon-ecran","assemblage","interference-fille","interference-couvercle","interference-vis","interference-peau","interference-ecrous","integrite-joint","interference-joint","interference-usb","interference-retournement"]

// Banc d'essai : abaissement de la carte fille, en mm, pour la
// piece "interference-fille". A 0 elle doit passer au-dessus de
// tout ; abaissee, elle doit taper dans l'ecran.
essai = 0;

/* [Carte LoRa] */
lora_l  = 50.2;   // longueur du PCB, le long de X       << A MESURER
lora_w  = 25.5;   // largeur du PCB, le long de Y        << A MESURER
lora_t  = 1.6;    // epaisseur du PCB                    << A MESURER

// Hauteur du plus haut composant de la face du dessus. C'est
// l'ecran OLED qui donne la cote, pas la puce radio : le module
// est colle sur le PCB et ne se demonte pas.
lora_compo_h = 3.0;                                   // << A MESURER

// Etendue de la zone composants, pour le banc d'essai. Prise
// egale a la carte entiere : c'est le cas defavorable, et il
// evite de dependre de la position exacte de l'ecran.
lora_compo_l = lora_l;
lora_compo_w = lora_w;

// La carte est decalee vers -Y pour degager, cote +Y, la place
// des deux entretoises de la carte fille. Sans ce decalage les
// butees de la carte LoRa et les entretoises se chevauchent.
lora_y  = -4.5;

/* [Rangee de broches soudee] */
// Une seule rangee, cote composants, broches vers le haut. Les
// sept signaux du projet - 3V3, GND, GPIO 7, 2, 4, 5, 6 - y sont
// tous, verifie sur la carte.
rang_n    = 18;
rang_pas  = 2.54;
rang_bord = 2.0;   // bord -Y du PCB -> axe de la rangee  << A MESURER
rang_l    = (rang_n - 1) * rang_pas;

/* [Carte fille] */
// Plaque a pastilles. Sa largeur commande l'encombrement de
// toute la coque : c'est elle la plus grande piece, pas la
// carte LoRa. La reduire reduit la boite.
fille_l = 50.0;   // le long de X
fille_w = 35.0;   // le long de Y
fille_t = 1.6;

// LA cote critique. Voir l'en-tete.                    << A MESURER
// 11,0 = ~8,5 mm de broche au-dessus du PCB + ~5,5 mm de corps
// de barrette tulipe - ~3 mm d'enfoncement. Trois estimations
// multipliees : c'est dire si elle doit etre mesuree.
fille_h = 11.0;

/* [Multiplexeur CD74HC4067] */
mux_l  = 30.0;    // longueur                            << A MESURER
mux_w  = 15.0;    // largeur                             << A MESURER
mux_t  = 1.6;
mux_h  = 8.0;     // dessus carte fille -> dessous du mux << A MESURER
mux_compo_h = 3.0;                                    // << A MESURER

/* [Borniers] */
// Ce sont eux qui recoivent les cables de sondes. A levier ou a
// vis : le levier se refait au jardin sans tournevis, la vis
// tient un peu mieux. Le modele prend le plus haut des deux.
bornier_l = 25.0;
bornier_w = 8.0;
bornier_h = 12.0;                                     // << A MESURER

/* [Coque] */
paroi   = 2.4;
h_fond  = 2.4;    // epaisseur du plancher
ep_couv = 2.4;    // epaisseur du couvercle
plot_h  = 3.0;    // hauteur des plots sous la carte LoRa
jeu     = 3.0;    // jeu lateral entre la plus grande carte et la paroi
r_coin  = 4.0;
garde   = 2.0;    // vide au-dessus du plus haut composant

/* [Joint : rainure et languette] */
// Meme principe que la coque des sondes : le bac porte une
// rainure, le couvercle une languette qui vient dedans, et le
// silicone occupe le jeu qui reste. Il est contenu de trois
// cotes au lieu d'etre ecrase entre deux plats.
joint_axe   = 1.25;
rainure_l   = 1.0;
rainure_p   = 0.9;
languette_l = 0.6;
languette_h = 0.6;

/* [Visserie] */
vis_d      = 3.4;
vis_tete_d = 6.2;
ecrou_plat = 5.7;
ecrou_ep   = 2.6;
ecrou_deg  = 4.0;
oreille_d  = 12.0;

/* [Ouvertures] */
usb_l      = 12.0;  // largeur de l'ouverture USB-C       << A MESURER
usb_h      = 7.0;   // hauteur                            << A MESURER
usb_y      = 0.0;   // decalage / axe de la carte         << A MESURER
usb_dz     = 1.6;   // face composants -> axe de la prise << A MESURER

bouton_d     = 6.0;
bouton_ecart = 9.0; // ecart entre PRG et RST             << A MESURER
bouton_dz    = 1.5;

antenne_d  = 6.5;   // percage de traversee SMA
antenne_dz = 12.0;  // hauteur libre, choisie et non subie

ecran_l = 26.0;     // ouverture d'ecran dans le couvercle << A MESURER
ecran_w = 16.0;                                        // << A MESURER
ecran_y = 0.0;      // decalage / axe de la carte LoRa    << A MESURER

bouchon_jeu = 0.25; // jeu peripherique des bouchons
bouchon_col = 2.0;  // debord de la collerette

/* [Presse-etoupe] */
// PG7 : perce 12,5, collerette 19. C'est la collerette qui
// commande, pas le percage - il lui faut de la paroi PLATE.
// C'est l'argument qui a fait choisir l'empilage contre la
// disposition a plat : une coque de 18 mm de haut ne peut pas
// recevoir une collerette de 19.
etoupe_perc = 12.5;                                   // << A MESURER
etoupe_col  = 19.0;                                   // << A MESURER

$fn = 64;

// ---------------- cotes derivees ---------------------------
// Derivees et non posees a la main : changer fille_h ou la
// hauteur du mux doit remonter jusqu'a la hauteur de la boite,
// sinon le couvercle ecrase le montage sans que rien ne le dise.

z_lora    = h_fond + plot_h;          // dessous carte LoRa
z_lora_t  = z_lora + lora_t;          // face composants
z_fille   = z_lora_t + fille_h;       // dessous carte fille
z_fille_t = z_fille + fille_t;        // dessus carte fille

h_etage2  = max(mux_h + mux_t + mux_compo_h, bornier_h);
H_int     = (z_fille_t - h_fond) + h_etage2 + garde;
z_joint   = h_fond + H_int;

W_int = max(lora_l, fille_l) + 2 * jeu;
D_int = max(lora_w, fille_w) + 2 * jeu;
W_ext = W_int + 2 * paroi;
D_ext = D_int + 2 * paroi;
r_int = r_coin - paroi;

// Les oreilles sont poussees vers l'exterieur jusqu'a ce que le
// logement d'ecrou passe entierement en dehors du volume
// interieur. 4,5 mm : le rayon circonscrit d'un ecrou M3 vaut
// 3,3, plus 1,2 de paroi. Les rapprocher rouvrirait le nid
// d'abeille sur la cavite et l'ecrou sortirait au serrage -
// c'est le defaut v6 de la coque des sondes.
//
// C'est un parametre et non une constante pour que le banc
// d'essai puisse REINTRODUIRE le defaut : les trois controles
// de visserie sont sans valeur tant qu'on ne les a pas vus
// echouer. `just coque-carte-test` les rejoue a vis_marge
// negatif.
vis_marge = 4.5;
vis_cx = W_int/2 + vis_marge;
vis_cy = D_int/2 + vis_marge;
vis_pos = [[-vis_cx,-vis_cy],[vis_cx,-vis_cy],[-vis_cx,vis_cy],[vis_cx,vis_cy]];

// ---------------- garde-fous -------------------------------
// Des assert() plutot que des commentaires : ils refusent de
// rendre la piece au lieu d'en sortir une qui a l'air bonne.

assert(fille_h > lora_compo_h + 1.0,
       "fille_h : la carte fille s'assoit sur l'ecran OLED");

// La collerette du presse-etoupe a besoin de paroi PLATE. Si
// cet assert saute, il faut soit une coque plus haute, soit un
// presse-etoupe plus petit (M10 : collerette 15).
assert(H_int >= etoupe_col + 2.0,
       "H_int : la collerette du presse-etoupe deborde de la paroi");

// La rangee doit tenir dans la longueur de la carte.
assert(rang_l + 2 <= lora_l, "rang_l : la rangee deborde de la carte");

// ---------------- profils 2D ------------------------------

module p_ext() {
    union() {
        offset(r = r_coin)
            square([W_ext - 2*r_coin, D_ext - 2*r_coin], center = true);
        for (p = vis_pos) translate(p) circle(d = oreille_d);
    }
}

module p_int() {
    offset(r = r_int)
        square([W_int - 2*r_int, D_int - 2*r_int], center = true);
}

// Rainure et languette : deux anneaux concentriques suivant le
// contour exterieur, centres sur le meme axe. La languette est
// plus etroite et moins haute, et cette difference est le volume
// ou le silicone se loge.
module p_anneau(larg) {
    difference() {
        offset(delta = -(joint_axe - larg/2)) p_ext();
        offset(delta = -(joint_axe + larg/2)) p_ext();
    }
}
module p_rainure()   { p_anneau(rainure_l); }
module p_languette() { p_anneau(languette_l); }

module p_ecran() {
    translate([0, lora_y + ecran_y])
        square([ecran_l, ecran_w], center = true);
}

// ---------------- appuis interieurs ------------------------

// Quatre plots sous la carte LoRa. Ils la tiennent en hauteur ;
// ce sont les butees qui la tiennent en plan.
module plots() {
    for (sx = [-1,1], sy = [-1,1])
        translate([sx * (lora_l/2 - 5), lora_y + sy * (lora_w/2 - 5), h_fond])
            cylinder(d = 6, h = plot_h);
}

// Quatre butees cylindriques aux angles de la carte, juste en
// dehors de son contour. Elles montent 1 mm au-dessus de la face
// composants : la carte est prise en plan, sans vis ni percage a
// deviner sur un clone.
module butees() {
    for (sx = [-1,1], sy = [-1,1])
        translate([sx * (lora_l/2 + 1.8), lora_y + sy * (lora_w/2 + 1.8), h_fond])
            cylinder(d = 3, h = z_lora_t + 1.0 - h_fond);
}

// Deux entretoises sous le bord +Y de la carte fille. Sans
// elles la carte fille est tenue par la seule barrette et
// pivote : la barrette encaisserait tous les efforts.
module entretoises() {
    for (sx = [-1,1])
        translate([sx * (fille_l/2 - 4), fille_w/2 - 2.5, h_fond])
            difference() {
                cylinder(d = 6, h = z_fille - h_fond);
                translate([0,0,z_fille - h_fond - 6])
                    cylinder(d = 2.1, h = 7);   // avant-trou M2,5
            }
}

// ---------------- visserie ---------------------------------

module vis_futs() {
    for (p = vis_pos)
        translate([p[0], p[1], -1]) cylinder(d = vis_d, h = z_joint + ep_couv + 2);
}

// Logement hexagonal BORGNE, ouvert vers le haut au plan de
// joint. Rien ne traverse le plancher : un canal qui debouche
// dehors mene l'eau droit dans le volume qu'on cherche a
// etancher.
module ecrou_logements() {
    for (p = vis_pos)
        translate([p[0], p[1], z_joint - ecrou_ep]) {
            cylinder(d = ecrou_plat / cos(30), h = ecrou_ep + 1, $fn = 6);
            translate([0,0,-ecrou_deg]) cylinder(d = vis_d, h = ecrou_deg + 0.1);
        }
}

// ---------------- ouvertures de paroi ----------------------

module ouv_usb() {
    translate([W_int/2 - 1, lora_y + usb_y, z_lora_t + usb_dz])
        rotate([0,90,0])
            linear_extrude(paroi + 3)
                offset(r = 1) square([usb_h - 2, usb_l - 2], center = true);
}

module ouv_boutons() {
    for (s = [-1,1])
        translate([W_int/2 - 1, lora_y + s * bouton_ecart/2, z_lora_t + bouton_dz])
            rotate([0,90,0]) cylinder(d = bouton_d, h = paroi + 3);
}

module ouv_antenne() {
    translate([-(W_int/2 + paroi + 2), 0, h_fond + antenne_dz])
        rotate([0,90,0]) cylinder(d = antenne_d, h = paroi + 3);
}

module ouv_etoupe() {
    translate([0, D_int/2 - 1, h_fond + H_int/2])
        rotate([-90,0,0]) cylinder(d = etoupe_perc, h = paroi + 3);
}

module ouvertures() { ouv_usb(); ouv_boutons(); ouv_antenne(); ouv_etoupe(); }

// ---------------- pieces 3D --------------------------------

module fond() {
    union() {
        difference() {
            linear_extrude(z_joint) p_ext();
            translate([0,0,h_fond]) linear_extrude(H_int + 1) p_int();
            translate([0,0,z_joint - rainure_p])
                linear_extrude(rainure_p + 1) p_rainure();
            ecrou_logements();
            ouvertures();
        }
        plots();
        butees();
        entretoises();
    }
}

// Couvercle defini EN PLACE, dans le repere de l'assemblage.
module couvercle() {
    difference() {
        union() {
            translate([0,0,z_joint]) linear_extrude(ep_couv) p_ext();
            translate([0,0,z_joint - languette_h])
                linear_extrude(languette_h) p_languette();
        }
        translate([0,0,z_joint - languette_h - 1])
            linear_extrude(ep_couv + languette_h + 2) p_ecran();
        vis_futs();
        // fraisure de tete, dans la face exterieure
        for (p = vis_pos)
            translate([p[0], p[1], z_joint + ep_couv - 1.4])
                cylinder(d1 = vis_d, d2 = vis_tete_d, h = 1.4 + 0.01);
    }
}

// Retournee pour l'impression, face exterieure sur le plateau.
// rotate et non mirror : c'est le geste qu'on fera avec les
// doigts. Voir le controle de retournement plus bas.
module couvercle_a_plat() {
    translate([0,0,z_joint + ep_couv]) rotate([180,0,0]) couvercle();
}

// ---------------- bouchons ---------------------------------
// Le nœud est bouche, la passerelle est ouverte.

module bouchon_usb() {
    linear_extrude(paroi)
        offset(r = 1) square([usb_h - 2 - 2*bouchon_jeu,
                              usb_l - 2 - 2*bouchon_jeu], center = true);
    translate([0,0,paroi])
        linear_extrude(1.2)
            offset(r = 1) square([usb_h - 2 + 2*bouchon_col,
                                  usb_l - 2 + 2*bouchon_col], center = true);
}

module bouchon_boutons() {
    for (s = [-1,1]) translate([s * bouton_ecart/2, 0, 0]) {
        cylinder(d = bouton_d - 2*bouchon_jeu, h = paroi);
        translate([0,0,paroi]) cylinder(d = bouton_d + 2*bouchon_col, h = 1.2);
    }
    // pontet : les deux bouchons ne font qu'une piece, sinon on
    // en perd un dans l'herbe.
    translate([-bouton_ecart/2, -1.5, paroi])
        cube([bouton_ecart, 3, 1.2]);
}

module bouchon_ecran() {
    linear_extrude(ep_couv)
        offset(delta = -bouchon_jeu)
            square([ecran_l, ecran_w], center = true);
    translate([0,0,ep_couv])
        linear_extrude(1.2)
            square([ecran_l + 2*bouchon_col, ecran_w + 2*bouchon_col],
                   center = true);
}

// ---------------- factices (banc d'essai) ------------------

module lora_pcb() {
    color("green")
    translate([-lora_l/2, lora_y - lora_w/2, z_lora])
        cube([lora_l, lora_w, lora_t]);
}

// Zone composants de la face du dessus. Prise egale a la carte
// entiere : cas defavorable, et independant de la position
// exacte de l'ecran, qu'on n'a pas mesuree.
module lora_composants() {
    color("dimgray")
    translate([-lora_compo_l/2, lora_y - lora_compo_w/2, z_lora_t])
        cube([lora_compo_l, lora_compo_w, lora_compo_h]);
}

// La rangee de broches, telle qu'elle sort de la face composants.
module rangee() {
    color("goldenrod")
    for (i = [0 : rang_n - 1])
        translate([-rang_l/2 + i * rang_pas,
                   lora_y - lora_w/2 + rang_bord, z_lora_t])
            cylinder(d = 0.64, h = fille_h);
}

// Carte fille, barrette tulipe comprise. Le corps de la
// barrette descend sous la carte : c'est lui, et pas seulement
// le PCB, qui peut venir toucher l'ecran.
module fille_factice() {
    color("darkorange") {
        translate([-fille_l/2, -fille_w/2, z_fille])
            cube([fille_l, fille_w, fille_t]);
        // corps de la barrette tulipe, sous la carte fille
        translate([-rang_l/2 - 1.5,
                   lora_y - lora_w/2 + rang_bord - 1.5,
                   z_fille - 5.5])
            cube([rang_l + 3, 3, 5.5]);
    }
}

module mux_factice() {
    color("royalblue")
    translate([-mux_l/2, -mux_w/2 - 4, z_fille_t + mux_h])
        cube([mux_l, mux_w, mux_t + mux_compo_h]);
}

module bornier_factice() {
    color("khaki")
    translate([-bornier_l/2, fille_w/2 - bornier_w - 1, z_fille_t])
        cube([bornier_l, bornier_w, bornier_h]);
}

module contenu() {
    lora_pcb(); lora_composants(); rangee();
    fille_factice(); mux_factice(); bornier_factice();
}

// Fiche USB-C factice, balayee de l'exterieur jusqu'a la prise.
// Ce n'est pas la fiche a l'arret qu'il faut degager, c'est son
// trajet : une ouverture au bon endroit mais trop courte laisse
// la fiche buter sur la paroi.
module fiche_usb() {
    translate([W_int/2 - 4, lora_y + usb_y, z_lora_t + usb_dz])
        rotate([0,90,0])
            linear_extrude(20)
                offset(r = 1.2) square([2.2, 6.0], center = true);
}

// ---------------- selection de la piece --------------------

if (piece == "fond")            fond();
if (piece == "couvercle")       couvercle_a_plat();
if (piece == "bouchon-usb")     bouchon_usb();
if (piece == "bouchon-boutons") bouchon_boutons();
if (piece == "bouchon-ecran")   bouchon_ecran();

if (piece == "assemblage") {
    fond();
    translate([0,0,-essai]) contenu();
    couvercle();
}

// ---------------- banc d'essai -----------------------------
// Neuf volumes qui doivent tous etre VIDES. `just coque-carte-test`
// les rend un par un et echoue des que l'un n'est pas nul.
//
// Chacun correspond a un defaut plausible, pas a une idee
// generale de qualite. Ceux marques (v-sonde) ont deja ete
// rencontres pour de vrai sur la coque des sondes.

// 1. La carte fille touche-t-elle les composants de la carte
//    LoRa ? C'est LE defaut propre a l'empilage : la coque sort
//    propre, se visse, et ecrase l'ecran. `essai` abaisse la
//    carte fille pour verifier que le controle mord.
if (piece == "interference-fille")
    intersection() {
        translate([0,0,-essai]) fille_factice();
        lora_composants();
    }

// 2. Quelque chose touche-t-il le couvercle ? Le mux enfiche et
//    les borniers sont les deux plus hauts, et ni l'un ni l'autre
//    n'a ete mesure.
if (piece == "interference-couvercle")
    intersection() { couvercle(); contenu(); }

// 3. Une vis passe-t-elle dans une carte ? (v-sonde : deux vis
//    tombaient en plein dans le PCB.)
if (piece == "interference-vis")
    intersection() {
        vis_futs();
        union() { lora_pcb(); fille_factice(); }
    }

// 4. Un logement d'ecrou debouche-t-il sur la face exterieure du
//    fond ? (v-sonde : quatre percages traversaient la coque, a
//    l'interieur du cordon de joint.)
if (piece == "interference-peau")
    intersection() {
        ecrou_logements();
        linear_extrude(0.6) p_ext();
    }

// 5. Un logement d'ecrou ouvre-t-il dans le volume interieur ?
//    Un nid d'abeille perce sur un cote ne retient plus rien :
//    l'ecrou sort au serrage. (v-sonde v6.)
if (piece == "interference-ecrous")
    intersection() {
        ecrou_logements();
        translate([0,0,h_fond]) linear_extrude(H_int) p_int();
    }

// 6. Un logement d'ecrou mord-il l'anneau de joint ? Les
//    oreilles sont poussees dehors pour fuir la cavite ; les
//    pousser trop couperait le cordon de silicone en quatre
//    sans que rien d'autre ne s'en apercoive.
if (piece == "integrite-joint")
    intersection() {
        ecrou_logements();
        translate([0,0,z_joint - languette_h])
            linear_extrude(languette_h) p_languette();
    }

// 7. La languette entre-t-elle dans la rainure sans forcer ?
if (piece == "interference-joint")
    intersection() { fond(); couvercle(); }

// 8. La fiche USB-C atteint-elle la prise ? Le seul controle du
//    lot qui porte sur un geste et non sur un montage.
if (piece == "interference-usb")
    intersection() { fond(); fiche_usb(); }

// 9. Le couvercle EXPORTE se retourne-t-il sur le bac ? On prend
//    la piece telle qu'elle sort du slicer, on la retourne par
//    une rotation - le geste des doigts - et on demande qu'elle
//    retombe sur sa pose d'assemblage. Un miroir glisse dans la
//    chaine et les deux volumes cessent de coincider. C'est le
//    seul controle qui aurait attrape le defaut v6 de la coque
//    des sondes, ou la vue d'assemblage etait juste et la piece
//    imprimee inutilisable.
module couvercle_retourne() {
    translate([0,0,z_joint + ep_couv]) rotate([180,0,0]) couvercle_a_plat();
}
if (piece == "interference-retournement")
    union() {
        difference() { couvercle_retourne(); couvercle(); }
        difference() { couvercle(); couvercle_retourne(); }
    }

// =========================================================
//  Coque de protection - capteur d'humidite capacitif v1.2
//  (DollaTek, ASIN B07L2RV1D2 - PCB 98 x 23 x 1.6 mm,
//   connecteur PH2.0 3 broches en haut)
//
//  VERSION 4 : deux coquilles vissees, sortie de cable en
//  col de cygne (U inverse, bouche vers le bas), et ergots
//  venant se loger dans les 2 encoches laterales du PCB.
//
//  ---------------------------------------------------------
//  CONTRAINTE FONDAMENTALE, a ne jamais perdre de vue :
//  la coque ne couvre QUE les 45 mm du haut. La partie basse
//  est l'electrode capacitive, et la mesure se fait a travers
//  le vernis du PCB. Ajouter 2 mm de plastique et une lame
//  d'air ferait chuter la sensibilite a presque rien.
//  ---------------------------------------------------------
//
//  Principe :
//   - la coque s'ouvre : on POSE le PCB dedans, on visse
//   - deux ergots CYLINDRIQUES se logent dans les encoches
//     laterales du PCB, qui sont des demi-cercles : la carte
//     est prise dans une mortaise, aucun debattement vertical
//     dans un sens comme dans l'autre
//   - un epaulement sous le connecteur PH2.0 sert de second
//     niveau, avec 0.8 mm de jeu : il ne travaille que si un
//     ergot casse
//   - la sortie de cable regarde vers le bas, plus haut
//     que la bouche : l'eau devrait remonter pour entrer
//
//  Impression : chaque piece a plat, face exterieure sur
//  le plateau, sans supports. PETG ou ASA (PAS de PLA, il se
//  delite en exterieur au bout d'une saison), 3 perimetres.
//
//  Montage : 4 ecrous M3 presses dans les logements hexagonaux
//  du plan de joint, joint silicone NEUTRE (pas acetique, il
//  corrode le cuivre) dans la rainure, PCB pose dans la
//  coquille avant, cable couche dans le col, coquille arriere
//  posee languette dans la rainure, puis 4 vis M3x8 a tete
//  fraisee inox.
//
//  =========================================================
//  ETAT DES COTES  (v5, apres la premiere impression d'essai)
//
//  La v4 a ete imprimee : elle sort propre, mais la carte ne
//  s'encastre pas. Un seul defaut, et c'est enc_y — estime a
//  34 mm, il vaut 20. Les ergots tombaient 14 mm trop bas et
//  la carte reposait dessus au lieu de s'asseoir.
//
//  Comment les cotes ont ete obtenues, parce que la methode
//  compte ici plus que les chiffres :
//
//  Mesurer les pixels contre les graduations du reglet donne
//  une echelle FAUSSE de 5 %. La carte est plus haut dans le
//  cadre que les graduations qui servent d'etalon, donc plus
//  loin de l'objectif, donc plus petite. Les 17,2 mm sortis
//  ainsi contredisaient la lecture directe (18) — et l'ecart
//  grandissait avec la distance, signature d'une erreur
//  d'echelle et non de lecture.
//
//  La parade est de ne mesurer que des RAPPORTS. Le coin haut,
//  l'encoche et le trait blanc de serigraphie sont alignes sur
//  le meme chant : quelle que soit l'echelle, elle leur est
//  commune et se simplifie. Un seul etalon absolu suffit, et
//  c'est une lecture directe au reglet : trait blanc a 26 mm.
//
//    encoche : debut 18,0 - centre 20,0 - fin 22,0, diam 4,0
//    PCB     : 23,0 mm de large, confirme
//
//  Verifie sur deux cadrages independants (o1-10 et o1-14),
//  qui s'accordent a 0,1 mm pres. Et le « debut » ainsi calcule
//  retombe sur les 18 mm lus directement au reglet, alors que
//  rien dans le calcul ne l'y forcait.
//
//  Le rapport a en revanche donne 3,77 pour le diametre, la ou
//  la mesure directe dit 4,0. Il ne s'est pas trompe de la meme
//  facon : perdre 2 px de flou a chaque bord coute 0,8 % sur
//  les 500 px du grand ecart, et 5,5 % sur les 73 px de
//  l'encoche. La regle qui en sort : un rapport d'image mesure
//  les longs ecarts, jamais les petits details.
//
//  RESTE A CONFIRMER AU PIED A COULISSE :
//    pcb_t      epaisseur du PCB
//    conn_dh    bord haut du PCB -> haut du connecteur
//    conn_h     hauteur du connecteur au-dessus du PCB
//
//  pcb_in RESTE A 48, ET C'EST UN CHOIX :
//  le trait blanc a 26 mm est la limite d'immersion de la
//  carte, et sous lui il n'y a plus que l'electrode. La coque
//  engage 48 mm, soit 22 mm en dessous de ce trait : elle
//  limite l'enfoncement a 50 mm d'electrode dans le sol la ou
//  la carte en autorise 72. Reduire pcb_in a ~30 rendrait ces
//  22 mm, au prix d'une refonte des proportions (H, vis_pos,
//  jupe, col).
//
//  On ne le fait pas maintenant : la v5 corrige un seul defaut,
//  et changer la hauteur du boitier en meme temps rendrait le
//  resultat de l'impression illisible. La profondeur utile est
//  une question de sol, pas de modele — elle se tranche a O7.
// =========================================================

/* [Piece a exporter] */
piece = "avant";   // ["avant","arriere","pose","assemblage","interference","interference-vis","interference-peau","interference-joint"]

// Banc d'essai : decalage de la carte factice le long de son axe,
// en mm, pour la piece "interference". A 0 la carte doit se poser
// sans toucher les ergots ; decalee, elle doit buter dessus.
essai = 0;

/* [Capteur] */
pcb_w   = 23.0;    // largeur du PCB
pcb_t   = 1.6;     // epaisseur du PCB
pcb_in  = 48.0;    // hauteur de PCB engagee dans la coque
conn_l  = 8.7;     // longueur du connecteur PH2.0-3P (le long du PCB)
conn_dh = 0.0;     // distance bord haut du PCB -> haut du connecteur
conn_h  = 5.75;    // hauteur du connecteur au-dessus du PCB
butee   = true;    // epaulement de blocage sous le connecteur

/* [Encoches laterales du PCB] */
encoches = true;   // ergots venant se loger dans les 2 encoches
enc_y    = 20.0;   // bord HAUT du PCB -> centre des encoches
enc_diam = 4.0;    // diametre de l'encoche demi-circulaire     <<< MESURE
// Rayon de l'ergot, volontairement plus petit que celui de
// l'encoche. Deux raisons, pas une :
//
//   - la difference (enc_diam/2 - ergot_r = 0,80 mm) EST la
//     tolerance de montage sur enc_y. Un ergot au diametre
//     exact n'entrerait qu'a la cote parfaite ;
//   - un petit cylindre sort TOUJOURS surdimensionne de
//     l'imprimante — largeur d'extrusion et pied d'elephant
//     ajoutent 0,1 a 0,2 mm au rayon. Le 2,4 modelise fait
//     plutot 2,5 a 2,8 une fois pose sur le plateau.
//
// Le debattement vertical concede reste sous le jeu de 0,8 mm
// de l'epaulement, qui prend le relais.
ergot_r  = 1.2;

/* [Corps] */
H       = 52.0;    // hauteur du corps
Wb      = 30.0;    // largeur du corps
r_coin  = 3.0;
paroi   = 2.4;
ep_av   = 11.4;    // epaisseur de la coquille avant
ep_ar   = 3.2;     // epaisseur de la coquille arriere
                   // 3,2 et non 2,4 : il faut de la matiere sous la
                   // fraisure de la tete de vis, qui mange deja 1,4 mm.

prof_conn = 9.0;   // profondeur de la cavite connecteur
prof_comp = 3.5;   // profondeur de la cavite composants
larg_comp = 21.0;  // largeur cavite composants (laisse 2 appuis lateraux)
jeu       = 0.5;   // jeu lateral du PCB

/* [Jupe anti-ruissellement] */
Wj      = 42.0;
jupe_h  = 8.0;

/* [Col de cygne] */
arc_R      = 10.0;  // rayon de la boucle
tube_ext   = 12.0;  // diametre exterieur du conduit
tube_bore  = 7.2;   // diametre interieur (passage du cable)
y_haut     = 56.0;  // altitude de l'axe de la boucle
y_bouche   = 40.0;  // altitude de la bouche de sortie

/* [Joint : rainure et languette] */
// La coquille avant porte une RAINURE sur son plan de joint, la
// coquille arriere une LANGUETTE qui vient dedans. Les deux
// s'emboitent, et le silicone occupe le jeu qui reste : il est
// contenu de trois cotes au lieu d'etre ecrase entre deux plats.
joint_axe  = 1.25;  // retrait de l'axe du joint / contour exterieur
rainure_l  = 1.0;   // largeur de la rainure
rainure_p  = 0.9;   // profondeur de la rainure
languette_l= 0.6;   // largeur de la languette (0,2 de jeu par cote)
languette_h= 0.6;   // hauteur (0,3 de fond libre pour le silicone)

/* [Visserie] */
// Vis M3x8 a TETE FRAISEE, ecrou M3 noye dans le plan de joint.
//
// Rien ne traverse la coquille avant. C'est le point important :
// jusqu'a la v5 les quatre avant-trous debouchaient sur la face
// exterieure, a l'interieur du cordon de joint — quatre canaux qui
// menaient l'eau droit dans le volume qu'on cherche a etancher.
vis_d      = 3.4;   // percage de passage
vis_tete_d = 6.2;   // diametre de la fraisure (tete DIN 965 : 6,0)
ecrou_plat = 5.7;   // entre plats du logement (ecrou M3 : 5,5)
ecrou_ep   = 2.6;   // profondeur du logement (ecrou M3 : 2,4)
ecrou_deg  = 4.0;   // degagement sous l'ecrou, pour la pointe de vis

// Les deux vis du haut etaient a x=+-9, y=46,5 : en plein dans la
// carte, qui va jusqu'a y=48 et fait 23 de large. Elles passent sur
// des oreilles, comme celles du bas. Et les oreilles grandissent
// (10 -> 12) parce qu'un logement d'ecrou tient plus de place qu'un
// avant-trou : il faut qu'il reste en dedans de la rainure.
vis_pos    = [[-16,8],[16,8],[-16,44],[16,44]];
oreille_d  = 12.0;

$fn = 64;

// ---------------- profils 2D (x = largeur, y = hauteur) ----

module p_corps() {
    translate([0, r_coin])
        offset(r = r_coin)
            translate([-(Wb/2 - r_coin), 0])
                square([Wb - 2*r_coin, H - 2*r_coin]);
}

module p_jupe() {
    offset(r = 1) offset(delta = -1)
        polygon([[-Wj/2, 0], [Wj/2, 0], [Wb/2, jupe_h], [-Wb/2, jupe_h]]);
}

module p_oreilles() {
    for (p = vis_pos) if (abs(p[0]) > Wb/2 - oreille_d/2)
        translate(p) circle(d = oreille_d);
}

// chemin du cable : montee, boucle 180 deg, descente
module chemin(bas_desc) {
    translate([-0.05, H - 8]) square([0.1, y_haut - (H - 8)]);
    translate([arc_R, y_haut]) intersection() {
        difference() { circle(r = arc_R + 0.05); circle(r = arc_R - 0.05); }
        translate([-arc_R - 1, 0]) square([2*arc_R + 2, arc_R + 2]);
    }
    translate([2*arc_R - 0.05, bas_desc]) square([0.1, y_haut - bas_desc]);
}

module p_arche()  { offset(r = tube_ext/2)  chemin(y_bouche); }
module p_conduit(){ offset(r = tube_bore/2) chemin(y_bouche - 8); }

module p_ext() { union() { p_corps(); p_jupe(); p_oreilles(); p_arche(); } }

module p_pcb()  { translate([-(pcb_w/2 + jeu), -1])
                      square([pcb_w + 2*jeu, pcb_in + 1.5]); }
module p_comp() { translate([-larg_comp/2, 4])
                      square([larg_comp, H - 9]); }
y_butee = butee ? pcb_in - conn_dh - conn_l - 0.8 : 4;
module p_conn() { translate([-(conn_l + 1.4)/2, y_butee])
                      square([conn_l + 1.4, H + 1 - y_butee]); }
// Rainure et languette : deux anneaux concentriques suivant le contour,
// centres sur le meme axe. La languette est plus etroite et moins haute,
// et cette difference est le volume ou le silicone se loge.
module p_anneau(larg) {
    difference() {
        offset(delta = -(joint_axe - larg/2)) p_ext();
        offset(delta = -(joint_axe + larg/2)) p_ext();
    }
}
module p_rainure()   { p_anneau(rainure_l); }
module p_languette() { p_anneau(languette_l); }

// ---------------- pieces 3D --------------------------------

// Ergots ronds, centres sur le chant du PCB. La moitie interieure
// remplit l'encoche, la moitie exterieure est noyee dans la paroi
// du logement : l'ergot est ancre, pas colle sur une surface.
// Le petit cone du haut sert de guide a la pose.
module ergots() {
    h_cyl = pcb_t * 0.9;               // fut droit, sur l'epaisseur utile
    h_cne = pcb_t + 0.3 - h_cyl;       // guide, jusqu'au plan de joint
    for (s = [-1, 1])
        translate([s * pcb_w/2, pcb_in - enc_y, ep_av - (pcb_t + 0.3)]) {
            cylinder(r = ergot_r, h = h_cyl);
            translate([0, 0, h_cyl])
                cylinder(r1 = ergot_r, r2 = ergot_r - 0.5, h = h_cne);
        }
}

// Futs des vis, traversant l'assemblage. Sert au montage comme au
// banc d'essai : c'est ce volume qu'on intersecte avec la carte pour
// verifier qu'aucune vis ne lui passe au travers.
module vis_futs() {
    for (p = vis_pos)
        translate([p[0], p[1], ep_av - ecrou_ep - ecrou_deg])
            cylinder(d = vis_d, h = ecrou_deg + ecrou_ep + ep_ar + 1);
}

// Logement d'ecrou : hexagone BORGNE creuse dans le plan de joint,
// prolonge d'un degagement pour la pointe de la vis. Tourne de 30
// degres pour presenter un plat — et non une pointe — au logement du
// PCB, ce qui gagne 0,4 mm de matiere du bon cote.
module ecrou_logements() {
    for (p = vis_pos) translate([p[0], p[1], ep_av - ecrou_ep]) {
        rotate([0, 0, 30])
            cylinder(d = ecrou_plat / cos(30), h = ecrou_ep + 1, $fn = 6);
        translate([0, 0, -ecrou_deg])
            cylinder(d = vis_d, h = ecrou_deg + 0.1);
    }
}

// Tout ce qui est retire a la coquille avant, en un seul module :
// le banc d'essai l'intersecte avec la peau exterieure pour prouver
// qu'aucune cavite ne debouche dehors.
module avant_cavites() {
    translate([0,0,ep_av - prof_conn]) linear_extrude(prof_conn + 1) p_conn();
    translate([0,0,ep_av - prof_comp]) linear_extrude(prof_comp + 1) p_comp();
    translate([0,0,ep_av - (pcb_t + 0.3)]) linear_extrude(pcb_t + 1.3) p_pcb();
    translate([0,0,ep_av - prof_conn]) linear_extrude(prof_conn + 1) p_conduit();
    translate([0,0,ep_av - rainure_p]) linear_extrude(rainure_p + 1) p_rainure();
    ecrou_logements();
}

module coque_avant() {
    if (encoches) ergots();
    difference() {
        linear_extrude(ep_av) p_ext();
        avant_cavites();
    }
}

module coque_arriere() {
    difference() {
        union() {
            linear_extrude(ep_ar) p_ext();
            // languette, sur la face qui regarde la coquille avant
            translate([0, 0, ep_ar]) linear_extrude(languette_h) p_languette();
        }
        for (p = vis_pos) translate([p[0], p[1], 0]) {
            translate([0, 0, -1])
                cylinder(d = vis_d, h = ep_ar + languette_h + 2);
            // Fraisure a 90 deg, ouverte sur la face EXTERIEURE (z=0).
            // Elle s'imprime sans support : le trou se resserre en
            // montant, ce qui fait un surplomb a 45 degres.
            translate([0, 0, -0.01])
                cylinder(d1 = vis_tete_d, d2 = vis_d,
                         h = (vis_tete_d - vis_d) / 2 + 0.01);
        }
    }
}

// Coquille arriere posee sur la coquille avant, plans de joint au
// contact : la languette doit alors etre entierement dans la rainure.
module arriere_en_place() {
    translate([0, 0, ep_av + ep_ar]) mirror([0,0,1]) coque_arriere();
}

// Carte factice, encoches comprises : c'est elle qui sert de banc
// d'essai. `just coque-test` intersecte les ergots avec elle et
// echoue si le volume commun n'est pas nul.
module pcb_factice() {
    color("green")
    difference() {
        translate([-pcb_w/2, -50, ep_av - pcb_t - 0.3])
            cube([pcb_w, 98, pcb_t]);
        for (s = [-1, 1])
            translate([s * pcb_w/2, pcb_in - enc_y, ep_av - pcb_t - 1.3])
                cylinder(d = enc_diam, h = pcb_t + 2);
    }
}

if (piece == "avant")   coque_avant();
if (piece == "arriere") coque_arriere();
// Coquille avant + carte posee dedans, coquille arriere otee : la vue
// qui montre si l'ergot tombe dans l'encoche.
if (piece == "pose") {
    coque_avant();
    translate([0, essai, 0]) pcb_factice();
}
if (piece == "assemblage") {
    coque_avant();
    translate([0, essai, 0]) pcb_factice();
    arriere_en_place();
}

// ---------------- banc d'essai -----------------------------
// Quatre volumes qui doivent tous etre VIDES. `just coque-test`
// les rend un par un et echoue des que l'un n'est pas nul.

// 1. Les ergots touchent-ils la carte a la cote nominale ?
if (piece == "interference")
    intersection() { ergots(); translate([0, essai, 0]) pcb_factice(); }

// 2. Une vis passe-t-elle dans la carte ? C'etait le cas des deux
//    vis du haut jusqu'a la v5, et rien ne le disait.
if (piece == "interference-vis")
    intersection() { vis_futs(); pcb_factice(); }

// 3. Une cavite de la coquille avant debouche-t-elle sur la face
//    exterieure ? Si oui, l'eau a un chemin vers l'electronique.
if (piece == "interference-peau")
    intersection() {
        avant_cavites();
        linear_extrude(0.6) p_ext();   // la peau, cote plateau
    }

// 4. La languette entre-t-elle dans la rainure sans forcer ?
if (piece == "interference-joint")
    intersection() { coque_avant(); arriere_en_place(); }

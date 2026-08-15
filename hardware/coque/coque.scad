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
//  Montage : joint silicone NEUTRE (pas acetique, il corrode
//  le cuivre) dans la gorge du plan de joint, PCB pose dans
//  la coquille avant, cable couche dans le col, puis 4 vis
//  M3x12 inox (avant-trou 2.5).
//
//  =========================================================
//  ETAT DES COTES  (v5, apres la premiere impression d'essai)
//
//  La v4 a ete imprimee : elle sort propre, mais la carte ne
//  s'encastre pas. Un seul defaut, et c'est enc_y — estime a
//  34 mm, il vaut ~19 mm. Les ergots tombaient 15 mm trop bas
//  et la carte reposait dessus au lieu de s'asseoir.
//
//  Releve sur photo au reglet (graduations au 1/2 mm servant
//  d'etalon) + lecture directe au reglet :
//    encoche : debut a 17,2 mm du bord haut (lecture directe
//              du bord : 18 mm), fin a 20,7 mm, diametre 3,55
//    PCB     : 22,6 mm de large -> 23,0 nominal confirme
//    trait blanc de serigraphie a 24,7 mm du bord haut
//
//  Les deux releves de enc_y (18,95 par la photo, 19,8 par la
//  lecture directe) s'ecartent de 0,85 mm. La valeur retenue,
//  19,4, est a moins de 0,45 mm de chacun — et l'ergot rond
//  tolere 0,57 mm (voir ergot_r). Les deux hypotheses passent.
//
//  RESTE A CONFIRMER AU PIED A COULISSE :
//    enc_diam   diametre de l'encoche (3,55 vient de la photo)
//    pcb_t      epaisseur du PCB
//    conn_dh    bord haut du PCB -> haut du connecteur
//    conn_h     hauteur du connecteur au-dessus du PCB
//
//  L'encoche n'est PAS le repere d'enfoncement maximal : a
//  19 mm du bord haut, elle est trop pres du connecteur pour
//  ca. Le trait blanc a 24,7 mm est le candidat serieux, et il
//  reste lui aussi bien au-dessus du bas de la coque. pcb_in
//  n'a donc pas a etre reduit.
// =========================================================

/* [Piece a exporter] */
piece = "avant";   // ["avant","arriere","pose","assemblage","interference"]

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
enc_y    = 19.4;   // bord HAUT du PCB -> centre des encoches
enc_diam = 3.55;   // diametre de l'encoche demi-circulaire     <<< A CONFIRMER
// Rayon de l'ergot, volontairement plus petit que celui de
// l'encoche : la difference (enc_diam/2 - ergot_r = 0,57 mm)
// EST la tolerance de montage sur enc_y. Un ergot au diametre
// exact de l'encoche n'entrerait qu'a la cote parfaite ; celui-ci
// entre a 0,5 mm pres, et 0,57 mm de debattement vertical reste
// sous le jeu de 0,8 mm de l'epaulement, qui prend le relais.
ergot_r  = 1.2;

/* [Corps] */
H       = 52.0;    // hauteur du corps
Wb      = 30.0;    // largeur du corps
r_coin  = 3.0;
paroi   = 2.4;
ep_av   = 11.4;    // epaisseur de la coquille avant
ep_ar   = 2.4;     // epaisseur de la coquille arriere

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

/* [Visserie] */
vis_pilote = 2.5;   // avant-trou (vis M3 autotaraudeuse)
vis_passage= 3.4;   // percage traversant coquille arriere
vis_pos    = [[-15,8],[15,8],[-9,46.5],[9,46.5]];
oreille_d  = 10.0;

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
module p_gorge() { difference() { offset(delta=-0.7) p_ext(); offset(delta=-1.8) p_ext(); } }

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

module coque_avant() {
    if (encoches) ergots();
    difference() {
        linear_extrude(ep_av) p_ext();
        translate([0,0,ep_av - prof_conn]) linear_extrude(prof_conn + 1) p_conn();
        translate([0,0,ep_av - prof_comp]) linear_extrude(prof_comp + 1) p_comp();
        translate([0,0,ep_av - (pcb_t + 0.3)]) linear_extrude(pcb_t + 1.3) p_pcb();
        translate([0,0,ep_av - prof_conn]) linear_extrude(prof_conn + 1) p_conduit();
        for (p = vis_pos) translate([p[0], p[1], -1])
            cylinder(d = vis_pilote, h = ep_av + 2);
        // gorge a silicone sur le plan de joint
        translate([0, 0, ep_av - 0.8]) linear_extrude(1.8) p_gorge();
    }
}

module coque_arriere() {
    difference() {
        linear_extrude(ep_ar) p_ext();
        for (p = vis_pos) translate([p[0], p[1], -1])
            cylinder(d = vis_passage, h = ep_ar + 2);
    }
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
    translate([0, 0, ep_av + ep_ar + 0.2]) mirror([0,0,1]) coque_arriere();
}
if (piece == "interference")
    intersection() { ergots(); translate([0, essai, 0]) pcb_factice(); }

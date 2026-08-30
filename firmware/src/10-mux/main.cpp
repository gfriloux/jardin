// 10 — Trois sondes à travers le multiplexeur CD74HC4067.
//
// C'est le croquis de O2. Il répond aux trois questions de l'objectif en une
// seule exécution, et il les répond par la mesure, pas par la lecture de la
// fiche technique :
//
//   1. le multiplexeur décale-t-il les valeurs, et de combien ?
//   2. faut-il attendre après un changement de canal, et combien de temps ?
//   3. une lecture porte-t-elle la trace du canal précédent (diaphonie) ?
//
// Câblage : voir la page O2 de la documentation. En résumé, le module sur
// GPIO 7 (SIG), 47/48/19/20 (adresse S0..S3), 5 (EN), et les trois sondes sur
// C0, C1, C2 avec leurs VCC en commun sur GPIO 6.
//
// PLUS UN FIL PARTICULIER : la sortie de la sonde du canal 0 va AUSSI sur
// GPIO 2, en direct. C'est lui qui rend la question 1 mesurable — sans lui il
// faudrait comparer aux relevés de O3, or la reproductibilité entre séances
// vaut 37 points quand le décalage cherché en vaut peut-être 15. On mesurerait
// surtout le temps qui passe.

#include <Arduino.h>

#include "board.h"

// Les trois canaux câblés. Le module en offre seize ; treize restent libres,
// et c'est tout l'intérêt de O2.
static const int CANAUX[] = {0, 1, 2};
static const int N_CANAUX = sizeof(CANAUX) / sizeof(CANAUX[0]);

// Délai de stabilisation après mise sous tension des sondes, mesuré en O1.
static const int STABILISATION_MS = 200;

// Délai généreux après un changement de canal, employé pour établir les
// valeurs de référence. Il doit être largement supérieur à ce qui est
// nécessaire : c'est justement ce que la question 2 cherche à réduire.
static const int REPOS_MS = 50;

static const int ECHANTILLONS = 64;

// Les délais balayés pour la question 2. Zéro compris : c'est le cas où on lit
// immédiatement après avoir changé d'aiguillage, celui qui doit échouer si la
// diaphonie existe.
static const int DELAIS_MS[] = {0, 1, 2, 5, 10, 20, 50};
static const int N_DELAIS = sizeof(DELAIS_MS) / sizeof(DELAIS_MS[0]);

// Au-dessus de ce seuil, un canal porte une sonde ; en dessous, il est en
// l'air. Le fond d'une entrée non câblée se promène entre 75 et 170 selon la
// lecture, quand la sonde la plus mouillée observée donnait 580. Le seuil est
// absolu et non relatif à une mesure du fond : caler le critère sur une seule
// lecture du canal 15 faisait passer tout le bruit pour des sondes.
static const float SEUIL_SONDE = 300.0f;

// Sélectionne un canal en écrivant son numéro en binaire sur les quatre fils
// d'adresse. Canal 5 = 0101 = S3 bas, S2 haut, S1 bas, S0 haut.
static void mux_selectionner(int canal) {
  digitalWrite(PIN_MUX_S0, (canal >> 0) & 1);
  digitalWrite(PIN_MUX_S1, (canal >> 1) & 1);
  digitalWrite(PIN_MUX_S2, (canal >> 2) & 1);
  digitalWrite(PIN_MUX_S3, (canal >> 3) & 1);
}

static float lire_moyenne(int broche, int n) {
  long somme = 0;
  for (int i = 0; i < n; i++) {
    somme += analogRead(broche);
    delayMicroseconds(200);
  }
  return (float)somme / n;
}

// Valeur d'un canal, l'aiguillage largement reposé. C'est la référence.
static float lire_canal_repose(int canal) {
  mux_selectionner(canal);
  delay(REPOS_MS);
  return lire_moyenne(PIN_MUX_SIG, ECHANTILLONS);
}

static void alimenter_sondes(bool actif) {
  digitalWrite(PIN_SOIL_PWR, actif ? HIGH : LOW);
  if (actif) delay(STABILISATION_MS);
}

// --- Balayage des seize canaux --------------------------------------------
//
// Les canaux 0, 1 et 2 n'emploient que S0 et S1 : trois sondes ne prouvent donc
// RIEN sur les deux autres fils d'adresse. Or il faut S2 pour atteindre le
// canal 4 et S3 pour le canal 8, et c'est là toute la raison d'être de O2 —
// franchir la limite de quatre entrées, qui est précisément ce que S0 et S1
// seuls permettent.
//
// Lire le canal 15 ne suffit pas à les valider : si S2 et S3 restaient bas,
// `1111` sélectionnerait `0011`, soit le canal 3, non câblé lui aussi, qui rend
// la même valeur de fond. Les deux cas sont indiscernables.
//
// D'où ce balayage : on déplace UNE sonde de canal en canal et on regarde
// laquelle des seize lignes réagit. Si la sonde branchée sur C4 apparaît bien
// en face du canal 4, S2 commute. Idem pour C8 et S3.
static void balayer_tous_les_canaux(float vide) {
  Serial.println();
  Serial.println("--- Balayage des 16 canaux ---");
  Serial.println("Une sonde branchee sur un canal doit apparaitre EN FACE de");
  Serial.println("ce canal. La deplacer sur C4 valide S2, sur C8 valide S3.");
  Serial.println();

  for (int c = 0; c < 16; c++) {
    float v = lire_canal_repose(c);
    Serial.printf("  C%-2d %8.1f %s", c, v, v > SEUIL_SONDE ? "<-- sonde" : "");
    // Rappel de ce qu'il faut pour atteindre ce canal, pour que la lecture
    // du tableau dise directement quel fil d'adresse est en cause.
    if (c == 4) Serial.print("   (exige S2)");
    if (c == 8) Serial.print("   (exige S3)");
    if (c == 12) Serial.print("   (exige S2 et S3)");
    // Une sonde capacitive alimentee en 3,3 V plafonne vers 2,8 V a l'air
    // libre. Au-dela, ce n'est plus une mesure de sol.
    if (v > 3100.0f) Serial.print("   ?? au-dessus de l'air libre");
    Serial.println();
  }
}

// --- Vérification du montage, avant toute mesure ---------------------------
//
// Ce croquis a d'abord été écrit sans ce contrôle, et il a annoncé « écart
// moyen : -2316 points » avec l'aplomb d'une mesure, alors que le module
// n'était simplement pas en service. Un résultat faux qui a l'air d'un
// résultat coûte plus cher qu'une panne franche.
//
// Deux symptômes suffisent à distinguer un montage muet d'une vraie mesure.
//
// Rend true si le montage est exploitable.
static bool verifier_montage(const float *repos, float vide) {
  bool ok = true;

  // 1. Un canal câblé qui lit comme un canal non câblé ne reçoit rien.
  //    Une sonde dans l'eau donne ~875, à l'air ~2600 : le seuil est large.
  for (int i = 0; i < N_CANAUX; i++) {
    if (fabsf(repos[i] - vide) < 50.0f) {
      Serial.printf("  canal %d (%.0f) est indiscernable du canal 15 non "
                    "cable (%.0f)\n",
                    CANAUX[i], repos[i], vide);
      ok = false;
    }
  }

  // 2. Une sortie qui flotte donne une valeur différente selon le canal d'où
  //    l'on vient, parce qu'elle dépend de la charge résiduelle. Une liaison
  //    réelle, elle, ne dépend pas du chemin.
  float mini = 4095.0f, maxi = 0.0f;
  for (int depuis = 0; depuis < N_CANAUX; depuis++) {
    mux_selectionner(CANAUX[depuis]);
    delay(REPOS_MS);
    float v = lire_canal_repose(CANAUX[0]);
    if (v < mini) mini = v;
    if (v > maxi) maxi = v;
  }
  if (maxi - mini > 100.0f) {
    Serial.printf("  canal 0 vaut entre %.0f et %.0f selon le canal d'ou "
                  "l'on vient (%.0f points d'ecart)\n",
                  mini, maxi, maxi - mini);
    Serial.println("  -> la sortie flotte : les interrupteurs ne se ferment pas");
    ok = false;
  }

  if (!ok) {
    Serial.println();
    Serial.println("  MONTAGE MUET — aucune mesure n'est exploitable.");
    Serial.println();
    Serial.println("  Le module n'est pas alimente, ou pas en service. Verifier");
    Serial.println("  dans cet ordre, ce sont les trois derniers fils du schema :");
    Serial.println("    1. VCC du module  -> 3V3");
    Serial.println("    2. GND du module  -> GND  (distincte de celle des sondes)");
    Serial.println("    3. EN du module   -> GPIO 5");
    Serial.println();
    Serial.printf("  EN est ACTIF A L'ETAT BAS : sur 3V3 ou en l'air, il inhibe.\n"
                  "  Il va sur GPIO %d — ni sur 3V3, ni sur GPIO %d qui alimente\n"
                  "  les sondes et passe a HIGH pendant la mesure.\n",
                  PIN_MUX_EN, PIN_SOIL_PWR);
    Serial.println();
    Serial.println("  Sur breadboard, la rainure centrale coupe tout : un fil en");
    Serial.println("  10a et l'autre en 10f ne sont pas relies, et ca ne se voit pas.");
  }

  return ok;
}

// --- Question 1 : le multiplexeur décale-t-il les valeurs ? ----------------
//
// Même sonde, même terre, même instant, deux chemins. Tout ce qui varie d'une
// séance à l'autre disparaît de la comparaison ; il ne reste que le mux.
static void question_decalage() {
  Serial.println();
  Serial.println("--- 1. Decalage introduit par le multiplexeur ---");
  Serial.println("Sonde du canal 0, lue en direct (GPIO 2) et via le mux.");

  // La comparaison n'a de sens que si le fil de GPIO 2 et l'entree C0 pointent
  // bien la MEME sonde. Deplacer cette sonde ailleurs — pour eprouver S2 ou S3,
  // par exemple — casse l'hypothese sans rien casser de visible, et la mesure
  // devient un ecart entre une sonde et une entree en l'air. C'est arrive.
  float direct = lire_moyenne(PIN_SOIL_SIG_DIRECT, ECHANTILLONS);
  float via_mux = lire_canal_repose(0);
  if (fabsf(via_mux - direct) > 0.2f * direct) {
    Serial.println();
    Serial.printf("  IGNORE : direct = %.0f mais C0 = %.0f.\n", direct, via_mux);
    Serial.println("  La sonde lue par GPIO 2 n'est pas branchee sur C0, donc");
    Serial.println("  ces deux valeurs ne decrivent pas le meme capteur et leur");
    Serial.println("  difference ne mesure rien. Remettre le fil sur C0.");
    return;
  }

  Serial.println();
  Serial.println("  essai   direct     mux    ecart");

  float somme_ecart = 0;
  const int ESSAIS = 5;

  for (int i = 0; i < ESSAIS; i++) {
    // Le direct d'abord, le mux ensuite, dans la même poignée de
    // millisecondes : la terre n'a pas le temps de bouger entre les deux.
    float direct = lire_moyenne(PIN_SOIL_SIG_DIRECT, ECHANTILLONS);
    float via_mux = lire_canal_repose(0);
    float ecart = via_mux - direct;
    somme_ecart += ecart;

    Serial.printf("  %5d %8.1f %7.1f %8.1f\n", i + 1, direct, via_mux, ecart);
    delay(200);
  }

  float moyen = somme_ecart / ESSAIS;
  Serial.println();
  Serial.printf("  ecart moyen : %+.1f points\n", moyen);
  // 7,8 points est la divergence maximale entre les trois sondes, mesurée en
  // O3. Un mux qui décale moins que ça décale moins que le matériel qu'il
  // dessert : la question est close.
  if (fabsf(moyen) < 8.0f) {
    Serial.println("  -> sous les 7,8 points de divergence inter-sondes de O3.");
    Serial.println("     Le mux decale moins que les sondes entre elles.");
  } else {
    Serial.println("  -> superieur a la divergence inter-sondes de O3.");
    Serial.println("     A prendre en compte, voir les Resultats de O2.");
  }
}

// --- Questions 2 et 3 : diaphonie temporelle ------------------------------
//
// On repose l'aiguillage sur le canal le plus contrasté, puis on bascule sur
// le canal visé et on lit après un délai donné. Si la lecture porte encore la
// trace du canal précédent, l'écart à la valeur reposée le dira.
//
// Le test n'a de sens que si deux canaux lisent des valeurs très différentes :
// une sonde dans l'eau et une à l'air libre. Sinon il n'y a rien à contaminer.
static void question_diaphonie(const float *repos) {
  Serial.println();
  Serial.println("--- 2 et 3. Diaphonie apres changement de canal ---");

  // Le canal le plus haut et le plus bas PARMI CEUX QUI PORTENT UNE SONDE.
  // Prendre une entree en l'air comme extremite donnerait un ecart magnifique
  // et un resultat vide : on mesurerait la derive d'une entree flottante, pas
  // une contamination entre canaux.
  int bas = -1, haut = -1;
  for (int i = 0; i < N_CANAUX; i++) {
    if (repos[i] <= SEUIL_SONDE) continue;
    if (bas < 0 || repos[i] < repos[bas]) bas = i;
    if (haut < 0 || repos[i] > repos[haut]) haut = i;
  }

  if (bas < 0 || bas == haut) {
    Serial.println();
    Serial.println("  IGNORE : il faut au moins deux canaux portant une sonde");
    Serial.println("  parmi C0, C1 et C2. Y rebrancher les sondes deplacees.");
    return;
  }

  Serial.printf("Canal %d (%.0f) et canal %d (%.0f), ecart de %.0f points.\n",
                CANAUX[bas], repos[bas], CANAUX[haut], repos[haut],
                repos[haut] - repos[bas]);

  if (repos[haut] - repos[bas] < 200.0f) {
    Serial.println();
    Serial.println("  ATTENTION : les canaux se ressemblent trop pour que ce");
    Serial.println("  test signifie quoi que ce soit. Mettre une sonde dans");
    Serial.println("  un verre d'eau et une autre a l'air libre, puis relancer.");
    return;
  }

  Serial.println();
  Serial.println("  delai   apres canal haut   apres canal bas");
  Serial.println("   (ms)    lu    ecart        lu    ecart");

  for (int d = 0; d < N_DELAIS; d++) {
    // Venant du canal haut, on lit le canal bas.
    mux_selectionner(CANAUX[haut]);
    delay(REPOS_MS);
    mux_selectionner(CANAUX[bas]);
    delay(DELAIS_MS[d]);
    float vers_bas = lire_moyenne(PIN_MUX_SIG, 16);

    // Puis l'inverse.
    mux_selectionner(CANAUX[bas]);
    delay(REPOS_MS);
    mux_selectionner(CANAUX[haut]);
    delay(DELAIS_MS[d]);
    float vers_haut = lire_moyenne(PIN_MUX_SIG, 16);

    Serial.printf("  %5d %7.0f %7.1f %9.0f %7.1f\n", DELAIS_MS[d], vers_bas,
                  vers_bas - repos[bas], vers_haut, vers_haut - repos[haut]);
  }

  Serial.println();
  Serial.println("  Le bon delai est le premier ou les deux ecarts tombent");
  Serial.println("  dans le bruit. S'ils sont deja nuls a 0 ms, aucun delai");
  Serial.println("  n'est necessaire et la sequence de mesure reste simple.");
}

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 10-mux ===");

  pinMode(PIN_SOIL_PWR, OUTPUT);
  digitalWrite(PIN_SOIL_PWR, LOW);

  pinMode(PIN_MUX_S0, OUTPUT);
  pinMode(PIN_MUX_S1, OUTPUT);
  pinMode(PIN_MUX_S2, OUTPUT);
  pinMode(PIN_MUX_S3, OUTPUT);
  pinMode(PIN_MUX_EN, OUTPUT);

  // EN est actif à l'état bas : l'aiguillage est en service.
  digitalWrite(PIN_MUX_EN, LOW);
  mux_selectionner(0);

  Serial.printf("SIG sur GPIO %d, adresse sur %d/%d/%d/%d, EN sur GPIO %d\n",
                PIN_MUX_SIG, PIN_MUX_S0, PIN_MUX_S1, PIN_MUX_S2, PIN_MUX_S3,
                PIN_MUX_EN);
  Serial.printf("Lecture directe de comparaison sur GPIO %d\n",
                PIN_SOIL_SIG_DIRECT);

  alimenter_sondes(true);

  // Les valeurs de référence, aiguillage largement reposé.
  Serial.println();
  Serial.println("--- 0. Valeurs de reference, mux repose ---");
  static float repos[N_CANAUX];
  for (int i = 0; i < N_CANAUX; i++) {
    repos[i] = lire_canal_repose(CANAUX[i]);
    Serial.printf("  canal %d : %.1f\n", CANAUX[i], repos[i]);
  }

  // Un canal non câblé, pour savoir à quoi ressemble « rien ». Utile pour
  // reconnaître une sonde débranchée d'une sonde qui lit vraiment.
  float vide = lire_canal_repose(15);
  Serial.printf("  canal 15 (non cable) : %.1f\n", vide);

  Serial.println();
  Serial.println("--- Verification du montage ---");
  if (!verifier_montage(repos, vide)) {
    alimenter_sondes(false);
    Serial.println();
    Serial.println("Corriger le cablage, puis relancer. Le suivi continu");
    Serial.println("ci-dessous aide a trouver le fil fautif : un canal doit");
    Serial.println("bouger quand on sort SA sonde de l'eau, et lui seul.");
    Serial.println();
    return;  // on ne mesure pas un montage muet
  }
  Serial.println("  OK — les canaux recoivent, la sortie ne flotte pas.");

  balayer_tous_les_canaux(vide);

  question_decalage();
  question_diaphonie(repos);

  alimenter_sondes(false);

  Serial.println();
  Serial.println("=== fin de la campagne ===");
  Serial.println("Suivi continu ci-dessous, une ligne toutes les 5 s.");
  Serial.println("Deplacer une sonde et regarder son canal bouger valide");
  Serial.println("qu'aucun canal n'en lit un autre.");
  Serial.println();
}

void loop() {
  alimenter_sondes(true);

  Serial.print("canaux :");
  for (int i = 0; i < N_CANAUX; i++) {
    Serial.printf("  %d=%6.1f", CANAUX[i], lire_canal_repose(CANAUX[i]));
  }
  Serial.printf("   direct=%6.1f\n",
                lire_moyenne(PIN_SOIL_SIG_DIRECT, ECHANTILLONS));

  alimenter_sondes(false);
  delay(5000);
}

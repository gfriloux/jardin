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

// --- Question 1 : le multiplexeur décale-t-il les valeurs ? ----------------
//
// Même sonde, même terre, même instant, deux chemins. Tout ce qui varie d'une
// séance à l'autre disparaît de la comparaison ; il ne reste que le mux.
static void question_decalage() {
  Serial.println();
  Serial.println("--- 1. Decalage introduit par le multiplexeur ---");
  Serial.println("Sonde du canal 0, lue en direct (GPIO 2) et via le mux.");
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
  // Le canal le plus haut et le plus bas : la pire contamination possible.
  int bas = 0, haut = 0;
  for (int i = 1; i < N_CANAUX; i++) {
    if (repos[i] < repos[bas]) bas = i;
    if (repos[i] > repos[haut]) haut = i;
  }

  Serial.println();
  Serial.println("--- 2 et 3. Diaphonie apres changement de canal ---");
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

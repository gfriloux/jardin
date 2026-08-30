// 11 — NODE-001 : trois sondes à travers le multiplexeur, émises par radio.
//
// C'est la couture de O2 et de O4, et le firmware que le nœud portera
// désormais. Ses deux moitiés sont éprouvées séparément :
//
//   - la séquence de mesure vient de 10-mux, dont O2 a montré qu'elle n'a
//     besoin d'aucun délai après un changement de canal ;
//   - l'émission et le garde-fou de rapport cyclique viennent de
//     08-node-emission, que la campagne de portée de O4 a validé.
//
// Il rend `08-node-emission` obsolète : celui-ci lisait une sonde en direct sur
// GPIO 7, or GPIO 7 est maintenant la sortie du multiplexeur. Le flasher sur ce
// câblage laisserait EN en l'air, donc le mux inhibé, et ferait émettre des
// valeurs flottantes qui ressemblent à des mesures.
//
// Câblage : voir la page O2. Module sur GPIO 7 (SIG), 47/48/19/20 (adresse),
// 5 (EN), sondes sur C0, C1, C2, alimentation commune sur GPIO 6.
//
// DANGER : l'antenne doit être clipsée avant toute mise sous tension.

#include <Arduino.h>
#include <RadioLib.h>

#include "board.h"

// --- Paramètres radio ------------------------------------------------------
//
// IDENTIQUES à ceux de 09-gateway-reception. Un seul écart et les deux cartes
// ne s'entendront jamais, sans qu'aucune ne signale d'erreur.
static const float RADIO_BW_KHZ = 125.0;
static const int RADIO_SF = 7;
static const int RADIO_CR = 5;
static const int RADIO_PUISSANCE_DBM = 14;
static const int RADIO_PREAMBULE = 8;
static const uint8_t RADIO_SYNCWORD = 0x12;

// --- Garde-fou de rapport cyclique ----------------------------------------
//
// Calculé et non deviné : RadioLib donne le temps d'antenne réel de la charge
// utile, et on attend cent fois ça pour le 1 % de la bande 863–870 MHz. Le
// plancher de 60 s s'applique par-dessus, le sol bougeant à l'échelle de
// l'heure. Voir 08-node-emission pour l'historique de cette valeur.
//
// La trame passe ici de 71 à ~110 octets — trois sondes au lieu d'une — donc
// le temps d'antenne monte d'environ moitié. Le plancher continue de commander
// largement.
static const uint32_t PERIODE_PLANCHER_MS = 60000;
static const uint32_t RAPPORT_CYCLIQUE = 100;

// --- Mesure ----------------------------------------------------------------
static const int STABILISATION_MS = 200;
static const int ECHANTILLONS = 32;

// Les canaux du multiplexeur, et le nom que chacun porte dans la trame.
// L'ordre est fixe, pour que toute diaphonie résiduelle soit au moins
// reproductible — même si O2 n'en a trouvé aucune.
struct Voie {
  int canal;
  const char *nom;
};
static const Voie VOIES[] = {
    {0, "soil-01"},
    {1, "soil-02"},
    {2, "soil-03"},
};
static const int N_VOIES = sizeof(VOIES) / sizeof(VOIES[0]);

static const char *NODE_ID = "NODE-001";

SPIClass loraSpi(HSPI);
SX1262 radio =
    new Module(PIN_LORA_NSS, PIN_LORA_DIO1, PIN_LORA_RST, PIN_LORA_BUSY, loraSpi);

static uint32_t seq = 0;

static void mux_selectionner(int canal) {
  digitalWrite(PIN_MUX_S0, (canal >> 0) & 1);
  digitalWrite(PIN_MUX_S1, (canal >> 1) & 1);
  digitalWrite(PIN_MUX_S2, (canal >> 2) & 1);
  digitalWrite(PIN_MUX_S3, (canal >> 3) & 1);
}

// Lecture d'une voie. AUCUN délai après le changement de canal : O2 a comparé
// sept délais de 0 à 50 ms sur 1484 points de contraste entre un canal dans
// l'eau et un canal à l'air, et les écarts tiennent tous dans un point. Le seul
// temps de repos est celui de la première conversion de l'ADC.
static int lire_voie(int canal) {
  mux_selectionner(canal);

  long somme = 0;
  for (int i = 0; i < ECHANTILLONS; i++) {
    somme += analogRead(PIN_MUX_SIG);
    delayMicroseconds(200);
  }
  return (int)(somme / ECHANTILLONS);
}

// Tension de batterie, en volts.
//
// À CONFIRMER : la campagne de O4 a émis 170 trames portant toutes 0.00. Le
// pont diviseur ne renvoie rien d'exploitable sur ce clone — premier suspect,
// la polarité de PIN_BAT_CTRL. C'est O6 qui tranchera ; ici la valeur ne sert
// qu'à remplir le champ.
static const float BAT_RAPPORT_PONT = 4.9;
static const float BAT_VREF = 3.3;

static float lire_batterie() {
  pinMode(PIN_BAT_CTRL, OUTPUT);
  digitalWrite(PIN_BAT_CTRL, LOW);
  delay(10);

  long somme = 0;
  for (int i = 0; i < 16; i++) {
    somme += analogRead(PIN_BAT_ADC);
    delay(2);
  }

  digitalWrite(PIN_BAT_CTRL, HIGH);
  return (float)somme / 16.0f / 4095.0f * BAT_VREF * BAT_RAPPORT_PONT;
}

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 11-node-mux ===");
  Serial.println("ANTENNE OBLIGATOIRE : ce croquis emet.");

  pinMode(PIN_SOIL_PWR, OUTPUT);
  digitalWrite(PIN_SOIL_PWR, LOW);

  pinMode(PIN_MUX_S0, OUTPUT);
  pinMode(PIN_MUX_S1, OUTPUT);
  pinMode(PIN_MUX_S2, OUTPUT);
  pinMode(PIN_MUX_S3, OUTPUT);
  pinMode(PIN_MUX_EN, OUTPUT);

  // EN est actif à l'état bas. Le multiplexeur reste en service en permanence :
  // le couper entre deux mesures économiserait peut-être quelque chose, et
  // c'est O6 qui le mesurera. Tant que ce n'est pas mesuré, on ne complique
  // pas la séquence.
  digitalWrite(PIN_MUX_EN, LOW);
  mux_selectionner(VOIES[0].canal);

  loraSpi.begin(PIN_LORA_SCK, PIN_LORA_MISO, PIN_LORA_MOSI, PIN_LORA_NSS);

  int etat = radio.begin(LORA_FREQ_MHZ, RADIO_BW_KHZ, RADIO_SF, RADIO_CR,
                         RADIO_SYNCWORD, RADIO_PUISSANCE_DBM, RADIO_PREAMBULE);
  if (etat != RADIOLIB_ERR_NONE) {
    Serial.print("SX1262 : echec de begin(), code ");
    Serial.println(etat);
    Serial.println("Voir 03-radio, qui teste le bus SPI seul.");
    while (true) delay(1000);
  }

  Serial.printf("radio OK : %.1f MHz, BW %.0f kHz, SF%d, CR4/%d, %d dBm\n",
                LORA_FREQ_MHZ, RADIO_BW_KHZ, RADIO_SF, RADIO_CR,
                RADIO_PUISSANCE_DBM);
  Serial.printf("%d voies via le mux : ", N_VOIES);
  for (int i = 0; i < N_VOIES; i++) {
    Serial.printf("C%d=%s ", VOIES[i].canal, VOIES[i].nom);
  }
  Serial.println();
}

void loop() {
  // Les sondes sont alimentées une seule fois pour les trois lectures : le
  // délai de stabilisation de 200 ms se paie une fois et non trois.
  digitalWrite(PIN_SOIL_PWR, HIGH);
  delay(STABILISATION_MS);

  int valeurs[N_VOIES];
  for (int i = 0; i < N_VOIES; i++) {
    valeurs[i] = lire_voie(VOIES[i].canal);
  }

  digitalWrite(PIN_SOIL_PWR, LOW);

  float batterie = lire_batterie();

  // Trame du modèle de données. Composée à la main : quelques champs ne
  // justifient pas une bibliothèque JSON dans un firmware qui doit dormir.
  char trame[192];
  int n = snprintf(trame, sizeof(trame),
                   "{\"node\":\"%s\",\"seq\":%lu,\"battery\":%.2f,\"sensors\":{",
                   NODE_ID, (unsigned long)seq, batterie);

  for (int i = 0; i < N_VOIES && n > 0 && n < (int)sizeof(trame); i++) {
    n += snprintf(trame + n, sizeof(trame) - n, "%s\"%s\":%d",
                  i ? "," : "", VOIES[i].nom, valeurs[i]);
  }
  if (n > 0 && n < (int)sizeof(trame)) {
    n += snprintf(trame + n, sizeof(trame) - n, "}}");
  }

  if (n < 0 || n >= (int)sizeof(trame)) {
    Serial.println("trame tronquee : rien n'est emis");
    delay(PERIODE_PLANCHER_MS);
    return;
  }

  // `seq` compte les TENTATIVES, pas les succès. Mesuré en O4 : transmit()
  // rend parfois une erreur alors que la trame est partie, et incrémenter
  // seulement en cas de succès faisait réémettre le même numéro — deux fois
  // seq:0 à quatorze secondes d'intervalle. Compter les tentatives rend en
  // prime le taux de perte honnête : un envoi raté laisse un trou.
  seq++;

  uint32_t debut = millis();
  int etat = radio.transmit((uint8_t *)trame, n);
  uint32_t duree = millis() - debut;

  if (etat == RADIOLIB_ERR_NONE) {
    Serial.print("emis : ");
    Serial.println(trame);
  } else {
    Serial.print("echec d'emission, code ");
    Serial.println(etat);
  }

  uint32_t toa_ms = radio.getTimeOnAir(n) / 1000;
  uint32_t attente_legale = toa_ms * RAPPORT_CYCLIQUE;
  uint32_t attente = attente_legale > PERIODE_PLANCHER_MS ? attente_legale
                                                          : PERIODE_PLANCHER_MS;

  Serial.printf("temps d'antenne %lu ms -> attente legale %lu ms, "
                "retenue %lu ms (emission en %lu ms)\n",
                (unsigned long)toa_ms, (unsigned long)attente_legale,
                (unsigned long)attente, (unsigned long)duree);

  delay(attente);
}

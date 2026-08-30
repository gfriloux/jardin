// 08 — NODE-001 émet une trame LoRa, avec garde-fou de rapport cyclique.
//
// C'est la moitié émettrice de O4. Le nœud lit une sonde, lit sa batterie,
// compose la trame du modèle de données et l'envoie. Il affiche aussi sur la
// liaison série ce qu'il vient d'émettre : le croquis se teste donc seul, sans
// la passerelle, en regardant simplement défiler le moniteur.
//
// Câblage : sonde VCC -> GPIO 6, GND -> GND, AOUT -> GPIO 7. C'est le montage
// de O1, une seule sonde — le multiplexeur est le sujet de O2 et n'est pas
// nécessaire ici.
//
// DANGER : l'antenne doit être clipsée avant toute mise sous tension. Ce
// croquis-ci ÉMET pour de vrai, contrairement à 03-radio. Un SX1262 qui émet
// sans antenne se détruit.

#include <Arduino.h>
#include <RadioLib.h>

#include "board.h"

// --- Paramètres radio ------------------------------------------------------
//
// Ce sont des constantes, pas des réglages : les deux cartes doivent s'accorder
// sur les six, et un seul écart suffit à ce qu'elles ne s'entendent jamais.
// Toute modification se fait ici ET dans 09-gateway-reception.
static const float RADIO_BW_KHZ = 125.0;
static const int RADIO_SF = 7;      // on ne monte que sur preuve de portée
static const int RADIO_CR = 5;      // coding rate 4/5
static const int RADIO_PUISSANCE_DBM = 14;  // maximum légal courant en EU868
static const int RADIO_PREAMBULE = 8;
// 0x12 = réseau privé. 0x34 est réservé à LoRaWAN : l'employer ferait entendre
// nos trames par toute passerelle LoRaWAN à portée, et réciproquement.
static const uint8_t RADIO_SYNCWORD = 0x12;

// --- Garde-fou de rapport cyclique ----------------------------------------
//
// La bande 863–870 MHz impose ~1 % de rapport cyclique : une trame de 100 ms
// interdit de réémettre pendant 10 s. Une boucle qui émet en continu est
// illégale, et fausse en plus la campagne de portée, la radio chauffant.
//
// Le garde-fou est donc calculé, pas deviné : RadioLib sait dire le temps
// d'antenne exact d'une charge utile donnée, et on attend cent fois ça.
//
// Le plancher de 60 s s'applique par-dessus le calcul légal : à SF7 une trame
// de 71 octets autoriserait de réémettre toutes les treize secondes, ce qui est
// légal mais inutile pour du sol qui bouge à l'échelle de l'heure. Émettre plus
// souvent ne coûte pas que de la batterie, ça remplit l'archive de points qui
// n'apprennent rien.
//
// Il a été abaissé à 10000 le 30 août 2026, le temps de la campagne de portée
// de O4, où le raisonnement s'inverse : mesurer un taux de perte demande cent
// trames par position, et à 60 s cela coûte 1 h 40 par position contre 20
// minutes en laissant le calcul légal commander. La campagne est close, le
// plancher est revenu à sa valeur d'exploitation.
//
// Si une nouvelle campagne l'exigeait, le rabaisser — mais jamais à zéro : le
// plancher reste un filet contre un getTimeOnAir() qui renverrait 0. Sans lui,
// une seule valeur aberrante ferait émettre en continu, illégalement, et sans
// que rien ne le signale.
static const uint32_t PERIODE_PLANCHER_MS = 60000;
static const uint32_t RAPPORT_CYCLIQUE = 100;  // 1 % => attendre 100x le temps d'antenne

// --- Mesure ----------------------------------------------------------------
// Délai de stabilisation après mise sous tension de la sonde, mesuré en O1 :
// la valeur est à moins d'un point de sa valeur finale au bout de 200 ms.
static const int STABILISATION_MS = 200;
static const int ECHANTILLONS = 32;

static const char *NODE_ID = "NODE-001";
static const char *CANAL = "soil-01";

SPIClass loraSpi(HSPI);
SX1262 radio =
    new Module(PIN_LORA_NSS, PIN_LORA_DIO1, PIN_LORA_RST, PIN_LORA_BUSY, loraSpi);

static uint32_t seq = 0;

// Moyenne de ECHANTILLONS lectures, sonde alimentée le temps de la mesure.
static int lire_sonde() {
  digitalWrite(PIN_SOIL_PWR, HIGH);
  delay(STABILISATION_MS);

  long somme = 0;
  for (int i = 0; i < ECHANTILLONS; i++) {
    somme += analogRead(PIN_SOIL_SIG);
    delay(2);
  }

  digitalWrite(PIN_SOIL_PWR, LOW);
  return (int)(somme / ECHANTILLONS);
}

// Tension de batterie, en volts.
//
// À CONFIRMER SUR LE CLONE. Sur la Heltec V3, GPIO 37 commande le pont
// diviseur et GPIO 1 le lit, le rapport étant d'environ 4,9. Ces trois valeurs
// viennent de la documentation Heltec, pas d'une mesure sur notre carte.
//
// Si le chiffre émis est absurde, le premier suspect est la polarité de
// PIN_BAT_CTRL, le second le rapport du pont. C'est O6 qui tranchera, la
// consommation et l'autonomie étant son sujet ; ici la valeur ne sert qu'à
// remplir le champ `battery` de la trame.
static const float BAT_RAPPORT_PONT = 4.9;
static const float BAT_VREF = 3.3;

static float lire_batterie() {
  pinMode(PIN_BAT_CTRL, OUTPUT);
  digitalWrite(PIN_BAT_CTRL, LOW);  // actif à l'état bas
  delay(10);

  long somme = 0;
  for (int i = 0; i < 16; i++) {
    somme += analogRead(PIN_BAT_ADC);
    delay(2);
  }

  digitalWrite(PIN_BAT_CTRL, HIGH);

  float brut = (float)somme / 16.0f;
  return brut / 4095.0f * BAT_VREF * BAT_RAPPORT_PONT;
}

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 08-node-emission ===");
  Serial.println("ANTENNE OBLIGATOIRE : ce croquis emet.");

  pinMode(PIN_SOIL_PWR, OUTPUT);
  digitalWrite(PIN_SOIL_PWR, LOW);

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
}

void loop() {
  int humidite = lire_sonde();
  float batterie = lire_batterie();

  // Trame du modèle de données. Composée à la main plutôt qu'avec une
  // bibliothèque JSON : trois champs et un objet imbriqué ne justifient pas
  // une dépendance de plus dans un firmware qui doit tenir en veille.
  char trame[128];
  int n = snprintf(trame, sizeof(trame),
                   "{\"node\":\"%s\",\"seq\":%lu,\"battery\":%.2f,"
                   "\"sensors\":{\"%s\":%d}}",
                   NODE_ID, (unsigned long)seq, batterie, CANAL, humidite);

  if (n < 0 || n >= (int)sizeof(trame)) {
    Serial.println("trame tronquee : rien n'est emis");
    delay(PERIODE_PLANCHER_MS);
    return;
  }

  // `seq` compte les TENTATIVES, pas les succès, et s'incrémente donc quoi
  // qu'il advienne de l'émission.
  //
  // Il comptait les succès jusqu'au 30 août 2026, et c'était faux : mesuré,
  // `transmit()` rend parfois un code d'erreur alors que la trame est bien
  // partie — un délai d'attente interne, la marge étant mince (128 ms de temps
  // d'antenne pour 136 ms d'émission constatés). Le nœud croyait avoir échoué,
  // ne comptait pas la trame, et réémettait le MÊME numéro au cycle suivant.
  //
  // La passerelle recevait alors deux fois `seq:0`, à quatorze secondes
  // d'intervalle. Ce doublon a fini par casser le calcul de taux de perte du
  // tableau de bord, où (seq - precedent - 1) débordait par le bas.
  //
  // Compter les tentatives rend en prime le taux de perte honnête : un trou
  // dans la séquence signifie qu'une trame n'est pas arrivée, ce qui est
  // exactement la question posée. Un envoi réellement raté DOIT laisser un
  // trou.
  seq++;

  uint32_t debut = millis();
  int etat = radio.transmit((uint8_t *)trame, n);
  uint32_t duree = millis() - debut;

  if (etat == RADIOLIB_ERR_NONE) {
    Serial.print("emis : ");
    Serial.println(trame);
  } else {
    // Pas forcément un échec réel : la trame est peut-être partie quand même.
    // C'est pour ça qu'on ne réémet pas le même numéro.
    Serial.print("echec d'emission, code ");
    Serial.println(etat);
  }

  // Temps d'antenne réel de cette charge utile, en microsecondes.
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

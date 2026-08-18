// 09 — GATEWAY-001 reçoit les trames et les écrit sur la liaison série.
//
// C'est la moitié réceptrice de O4, et le point où le monde radio rejoint le
// monde des fichiers. La passerelle ne fait qu'une chose : recevoir, ajouter
// le RSSI et le SNR, écrire une ligne.
//
// La ligne produite est EXACTEMENT ce que le collecteur attend déjà :
//
//   {"rssi":-90,"snr":5.4,"frame":{"node":"NODE-001","seq":48,...}}
//
// Ce format n'est pas inventé ici : il est celui que `tools/simulateur-noeud.py`
// produit depuis O0 et que `collector/` consomme. Toute la chaîne aval —
// archive NDJSON, base, Grafana — a donc déjà tourné dessus. La passerelle n'a
// qu'à parler la même langue, et rien en dessous ne bouge.
//
// DANGER : l'antenne doit être clipsée avant toute mise sous tension. Un
// SX1262 sans antenne se détruit, même en réception mal configurée.

#include <Arduino.h>
#include <RadioLib.h>

#include "board.h"

// --- Paramètres radio ------------------------------------------------------
//
// IDENTIQUES à ceux de 08-node-emission. Un seul écart et les deux cartes ne
// s'entendront jamais, sans qu'aucune ne signale d'erreur : elles resteront
// simplement muettes l'une pour l'autre. C'est le mode de panne le plus
// coûteux à diagnostiquer sur le terrain, d'où cette redite assumée.
static const float RADIO_BW_KHZ = 125.0;
static const int RADIO_SF = 7;
static const int RADIO_CR = 5;
static const int RADIO_PUISSANCE_DBM = 14;  // sans effet en réception
static const int RADIO_PREAMBULE = 8;
static const uint8_t RADIO_SYNCWORD = 0x12;

SPIClass loraSpi(HSPI);
SX1262 radio =
    new Module(PIN_LORA_NSS, PIN_LORA_DIO1, PIN_LORA_RST, PIN_LORA_BUSY, loraSpi);

static uint32_t recues = 0;
static uint32_t rejetees = 0;

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 09-gateway-reception ===");
  Serial.println("ANTENNE OBLIGATOIRE.");

  loraSpi.begin(PIN_LORA_SCK, PIN_LORA_MISO, PIN_LORA_MOSI, PIN_LORA_NSS);

  int etat = radio.begin(LORA_FREQ_MHZ, RADIO_BW_KHZ, RADIO_SF, RADIO_CR,
                         RADIO_SYNCWORD, RADIO_PUISSANCE_DBM, RADIO_PREAMBULE);
  if (etat != RADIOLIB_ERR_NONE) {
    Serial.print("SX1262 : echec de begin(), code ");
    Serial.println(etat);
    Serial.println("Voir 03-radio, qui teste le bus SPI seul.");
    while (true) delay(1000);
  }

  Serial.printf("radio OK : %.1f MHz, BW %.0f kHz, SF%d, CR4/%d — en ecoute\n",
                LORA_FREQ_MHZ, RADIO_BW_KHZ, RADIO_SF, RADIO_CR);
  // Ces trois lignes ne sont pas du JSON. Le collecteur les note et passe :
  // il prévoit explicitement le bruit de démarrage d'une carte.
}

void loop() {
  String charge;
  int etat = radio.receive(charge);

  if (etat == RADIOLIB_ERR_RX_TIMEOUT) {
    return;  // rien n'est passé, on se remet en écoute
  }

  if (etat == RADIOLIB_ERR_CRC_MISMATCH) {
    // Trame reçue mais corrompue. Elle compte comme perdue dans la campagne
    // de portée, et c'est une information : à la limite de portée, le CRC
    // casse avant que la réception ne s'arrête.
    rejetees++;
    Serial.printf("# CRC invalide (%lu rejetees, RSSI %.1f dBm)\n",
                  (unsigned long)rejetees, radio.getRSSI());
    return;
  }

  if (etat != RADIOLIB_ERR_NONE) {
    Serial.printf("# erreur de reception, code %d\n", etat);
    return;
  }

  float rssi = radio.getRSSI();
  float snr = radio.getSNR();

  // La charge utile EST déjà la trame JSON : on l'insère telle quelle, sans
  // la relire. Le nœud est seul maître de son contenu, et le jour où il y
  // ajoute un champ, celui-ci traverse la passerelle intact — même principe
  // que le collecteur, qui recopie sans comprendre.
  //
  // Une vérification minimale quand même : à la limite de portée, une trame
  // au CRC juste par accident produirait une ligne qui n'est pas du JSON et
  // salirait l'archive.
  charge.trim();
  if (!charge.startsWith("{") || !charge.endsWith("}")) {
    rejetees++;
    Serial.printf("# charge utile non JSON, ignoree (%u octets)\n",
                  charge.length());
    return;
  }

  recues++;
  Serial.printf("{\"rssi\":%.0f,\"snr\":%.1f,\"frame\":%s}\n", rssi, snr,
                charge.c_str());
}

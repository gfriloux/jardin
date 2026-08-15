// 03 — Réveiller la puce radio, sans rien émettre.
//
// Ce croquis valide le bus SPI vers le SX1262 (NSS 8, SCK 9, MOSI 10, MISO 11,
// RST 12, BUSY 13, DIO1 14). Il appelle begin() et s'arrête là.
//
// Il n'émet volontairement rien : l'émission a ses propres contraintes (rapport
// cyclique EU868, antenne obligatoire), et c'est le sujet de l'objectif O4. Ici
// on veut seulement savoir si la puce répond.
//
// DANGER : l'antenne doit être clipsée avant toute mise sous tension. Un SX1262
// qui émet sans antenne se détruit. Même si ce croquis n'émet pas, prends
// l'habitude — c'est 25 euros la carte.

#include <Arduino.h>
#include <RadioLib.h>

#include "board.h"

SPIClass loraSpi(HSPI);
SX1262 radio =
    new Module(PIN_LORA_NSS, PIN_LORA_DIO1, PIN_LORA_RST, PIN_LORA_BUSY, loraSpi);

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 03-radio ===");

  loraSpi.begin(PIN_LORA_SCK, PIN_LORA_MISO, PIN_LORA_MOSI, PIN_LORA_NSS);

  int state = radio.begin(LORA_FREQ_MHZ);

  if (state == RADIOLIB_ERR_NONE) {
    Serial.println("SX1262 OK : le bus SPI repond et la radio s'initialise.");
    Serial.print("Frequence : ");
    Serial.print(LORA_FREQ_MHZ);
    Serial.println(" MHz");
    Serial.println("Aucune emission : c'est le sujet de O4.");
  } else {
    Serial.print("SX1262 KO. Code RadioLib = ");
    Serial.println(state);
    Serial.println("-1 = puce muette, souvent un brochage SPI faux.");
    Serial.println("-> verifier include/board.h contre la doc du vendeur.");
  }
}

void loop() {
  delay(1000);
}

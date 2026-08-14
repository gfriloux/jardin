// 06 — N'alimenter la sonde que pendant la mesure.
//
// Câblage, qui change par rapport à 04 et 05 :
//   sonde VCC  -> GPIO 6 (PIN_SOIL_PWR)   et NON plus 3V3
//   sonde GND  -> GND
//   sonde AOUT -> GPIO 7 (PIN_SOIL_SIG)
//
// Deux raisons de faire ça, et aucune n'est le confort :
//   - la consommation, qui décidera de l'autonomie du nœud (objectif O6) ;
//   - la durée de vie de la sonde, qu'on évite de laisser électriquement
//     active en permanence dans la terre.
//
// Ce croquis mesure le TEMPS DE STABILISATION : combien de millisecondes il
// faut attendre, après la mise sous tension, pour que la valeur cesse de
// bouger. C'est ce délai qu'on inscrira dans le firmware du nœud.

#include <Arduino.h>

#include "board.h"

static const int MESURES = 26;
static const int PERIODE_MS = 20;

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 06-alim-a-la-demande ===");
  Serial.println("Cherche a partir de quel instant raw= arrete de bouger.");
  Serial.println("C'est le delai de stabilisation a retenir.");

  pinMode(PIN_SOIL_PWR, OUTPUT);
  digitalWrite(PIN_SOIL_PWR, LOW);

  analogReadResolution(12);
  analogSetPinAttenuation(PIN_SOIL_SIG, ADC_11db);
}

void loop() {
  Serial.println("--- alimentation ON ---");
  unsigned long t0 = micros();
  digitalWrite(PIN_SOIL_PWR, HIGH);

  for (int i = 0; i < MESURES; i++) {
    int raw = analogRead(PIN_SOIL_SIG);
    Serial.printf("t=%6lu us  raw=%4d\n", micros() - t0, raw);
    delay(PERIODE_MS);
  }

  digitalWrite(PIN_SOIL_PWR, LOW);
  Serial.println("--- alimentation OFF ---");
  Serial.println();

  delay(5000);
}

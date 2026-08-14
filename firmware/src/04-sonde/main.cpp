// 04 — Lire la sonde d'humidité.
//
// Câblage sur la breadboard :
//   sonde VCC  -> 3V3   de la carte
//   sonde GND  -> GND   de la carte
//   sonde AOUT -> GPIO 7 (PIN_SOIL_SIG)
//
// La valeur affichée est le nombre brut de l'ADC, entre 0 et 4095. On ne le
// convertit PAS en pourcentage d'humidité : c'est tout le principe du projet.
// Voir la décision ADR-002 dans la documentation.
//
// Ordre de grandeur attendu : la valeur DIMINUE quand l'humidité augmente.
// Sonde en l'air = valeur haute. Sonde dans l'eau = valeur basse.

#include <Arduino.h>

#include "board.h"

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 04-sonde ===");
  Serial.println("valeur brute de l'ADC, de 0 a 4095");

  analogReadResolution(12);
  // 11 dB d'attenuation : plage d'entree d'environ 0 a 3,1 V, ce qui couvre la
  // sortie de la sonde. Sans ca, tout ce qui depasse ~1 V sature.
  analogSetPinAttenuation(PIN_SOIL_SIG, ADC_11db);
}

void loop() {
  int raw = analogRead(PIN_SOIL_SIG);
  Serial.printf("soil-01  raw=%4d  (~%.2f V)\n", raw, raw * 3.3f / 4095.0f);
  delay(500);
}

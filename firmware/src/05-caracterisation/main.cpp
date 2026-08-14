// 05 — Caractériser la sonde : combien elle bruite, et quelle dynamique elle a.
//
// Même câblage que 04. Ce croquis prend 100 mesures d'affilée et en sort la
// moyenne, l'écart-type et l'étendue.
//
// Deux chiffres à noter dans la documentation :
//   - l'ÉCART-TYPE, sonde immobile. Il dit combien de mesures il faudra
//     moyenner par la suite.
//   - la MOYENNE dans l'air puis dans l'eau. L'écart entre les deux est la
//     dynamique utile de la sonde. Si elle est faible (moins de ~500 points),
//     la sonde ne distinguera jamais deux états de sol, dont les variations
//     sont bien plus subtiles que « air » contre « eau ».

#include <Arduino.h>
#include <math.h>

#include "board.h"

static const int ECHANTILLONS = 100;
static const int PERIODE_MS = 10;

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 05-caracterisation ===");
  Serial.printf("%d mesures par serie, une toutes les %d ms\n", ECHANTILLONS,
                PERIODE_MS);
  Serial.println("Laisse la sonde immobile pendant une serie complete.");

  analogReadResolution(12);
  analogSetPinAttenuation(PIN_SOIL_SIG, ADC_11db);
}

void loop() {
  long somme = 0;
  long sommeCarres = 0;
  int mini = 4095;
  int maxi = 0;

  for (int i = 0; i < ECHANTILLONS; i++) {
    int v = analogRead(PIN_SOIL_SIG);
    somme += v;
    sommeCarres += (long)v * (long)v;
    if (v < mini) mini = v;
    if (v > maxi) maxi = v;
    delay(PERIODE_MS);
  }

  double moyenne = (double)somme / ECHANTILLONS;
  double variance = (double)sommeCarres / ECHANTILLONS - moyenne * moyenne;
  double ecartType = variance > 0.0 ? sqrt(variance) : 0.0;

  Serial.printf("moy=%7.1f  ecart-type=%5.1f  min=%4d  max=%4d  etendue=%4d\n",
                moyenne, ecartType, mini, maxi, maxi - mini);
}

// 07 — Trois sondes en direct, sans multiplexeur.
//
// C'est le montage de l'expérience de divergence de O3 : les trois sondes dans
// le même pot, à la même profondeur, lues par le même nœud.
//
// Câblage :
//   toutes les sondes VCC -> GPIO 6 (PIN_SOIL_PWR), en commun
//   toutes les sondes GND -> GND
//   sonde 1 AOUT -> GPIO 7    sonde 2 AOUT -> GPIO 2    sonde 3 AOUT -> GPIO 4
//
// Trois sondes à ~5 mA font 15 mA sur la broche d'alimentation, sous les 40 mA
// qu'un GPIO fournit. Au-delà de sept sondes il faudra un transistor.
//
// Pourquoi pas le multiplexeur : mesurer la divergence à travers le CD74HC4067
// ne permettrait plus de distinguer la dispersion des sondes de celle des
// canaux du multiplexeur. Ces mesures en direct sont aussi la référence contre
// laquelle O2 se validera.
//
// Les trois sondes sont lues dans la même fenêtre de temps, parce que la
// reproductibilité entre séances (~37 points, mesurée en O1) est dix fois
// supérieure au bruit instantané : à un quart d'heure d'écart, la dérive
// masquerait la divergence qu'on cherche.

#include <Arduino.h>

#include "board.h"

static const int SONDES[] = {PIN_SOIL_SIG, PIN_SOIL_SIG_2, PIN_SOIL_SIG_3};
static const int N_SONDES = sizeof(SONDES) / sizeof(SONDES[0]);

// Délai de stabilisation après mise sous tension, mesuré en O1 : la valeur est
// à moins d'un point de sa valeur finale au bout de 200 ms.
static const int STABILISATION_MS = 200;

static const int ECHANTILLONS = 100;

// Moyenne et écart-type sur ECHANTILLONS lectures d'une broche.
static void mesure(int broche, float *moy, float *ecart, int *mini, int *maxi) {
  long somme = 0;
  double somme_carres = 0;
  *mini = 4095;
  *maxi = 0;

  for (int i = 0; i < ECHANTILLONS; i++) {
    int v = analogRead(broche);
    somme += v;
    somme_carres += (double)v * v;
    if (v < *mini) *mini = v;
    if (v > *maxi) *maxi = v;
    delay(10);
  }

  *moy = (float)somme / ECHANTILLONS;
  float variance = (float)(somme_carres / ECHANTILLONS) - (*moy) * (*moy);
  *ecart = variance > 0 ? sqrtf(variance) : 0.0f;
}

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 07-trois-sondes ===");
  Serial.printf("%d sondes en direct sur GPIO", N_SONDES);
  for (int i = 0; i < N_SONDES; i++) Serial.printf(" %d", SONDES[i]);
  Serial.println();
  Serial.println("Les trois dans le meme pot, meme profondeur.");
  Serial.println("L'ecart entre S1, S2 et S3 est le resultat cherche.");
  Serial.println();

  analogReadResolution(12);
  for (int i = 0; i < N_SONDES; i++) {
    analogSetPinAttenuation(SONDES[i], ADC_11db);
  }

  pinMode(PIN_SOIL_PWR, OUTPUT);
  digitalWrite(PIN_SOIL_PWR, LOW);
}

void loop() {
  // Une seule mise sous tension pour les trois : le delai de stabilisation se
  // paie une fois, pas trois.
  digitalWrite(PIN_SOIL_PWR, HIGH);
  delay(STABILISATION_MS);

  float moy[N_SONDES], ecart[N_SONDES];
  int mini, maxi;

  for (int i = 0; i < N_SONDES; i++) {
    mesure(SONDES[i], &moy[i], &ecart[i], &mini, &maxi);
    Serial.printf("S%d (GPIO %2d)  moy=%7.1f  ecart-type=%5.1f  min=%4d  max=%4d\n",
                  i + 1, SONDES[i], moy[i], ecart[i], mini, maxi);
  }

  digitalWrite(PIN_SOIL_PWR, LOW);

  float mn = moy[0], mx = moy[0];
  for (int i = 1; i < N_SONDES; i++) {
    if (moy[i] < mn) mn = moy[i];
    if (moy[i] > mx) mx = moy[i];
  }

  // 1481 points : la dynamique terre seche -> terre saturee mesuree en O1.
  Serial.printf("divergence = %.1f points, soit %.1f %% de la dynamique utile\n\n",
                mx - mn, (mx - mn) / 1481.0f * 100.0f);

  delay(2000);
}

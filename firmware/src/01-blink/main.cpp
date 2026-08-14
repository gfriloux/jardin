// 01 — Faire clignoter la LED de la carte.
//
// Ce croquis ne sert pas à faire clignoter une LED. Il sert à prouver que la
// chaîne complète fonctionne : PlatformIO compile, le téléversement passe par
// l'USB, la carte démarre, et le moniteur série affiche ce qu'elle raconte.
// Tant que ça ne marche pas, rien d'autre ne peut marcher.

#include <Arduino.h>

#include "board.h"

void setup() {
  Serial.begin(115200);
  delay(2000);  // laisse le temps d'ouvrir le moniteur série après le reset

  pinMode(PIN_LED, OUTPUT);

  Serial.println();
  Serial.println("=== 01-blink ===");
  Serial.println("Si tu lis cette ligne, la chaine compilation -> televersement");
  Serial.println("-> moniteur serie fonctionne. La LED doit clignoter.");
}

void loop() {
  digitalWrite(PIN_LED, HIGH);
  Serial.println("LED allumee");
  delay(500);

  digitalWrite(PIN_LED, LOW);
  Serial.println("LED eteinte");
  delay(500);
}

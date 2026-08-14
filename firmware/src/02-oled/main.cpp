// 02 — Écrire sur le petit écran de la carte.
//
// Ce croquis valide deux choses du brochage de board.h :
//   - Vext (GPIO 36), la broche qui met les périphériques de la carte sous
//     tension. Elle est ACTIVE À L'ÉTAT BAS : on écrit LOW pour allumer.
//   - le bus I2C de l'écran (SDA 17, SCL 18, RST 21).
//
// Si l'écran reste noir, c'est que le clone ne suit pas le brochage Heltec V3.

#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>

#include "board.h"

// SSD1306 128 x 64, en I2C matériel. « F » = buffer complet en RAM.
U8G2_SSD1306_128X64_NONAME_F_HW_I2C oled(U8G2_R0, PIN_OLED_RST, PIN_OLED_SCL,
                                         PIN_OLED_SDA);

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 02-oled ===");

  // Mettre les peripheriques de la carte sous tension.
  pinMode(PIN_VEXT, OUTPUT);
  digitalWrite(PIN_VEXT, LOW);
  delay(100);

  oled.begin();
  oled.clearBuffer();

  oled.setFont(u8g2_font_ncenB10_tr);
  oled.drawStr(0, 14, "JARDIN");

  oled.setFont(u8g2_font_6x12_tr);
  oled.drawStr(0, 34, "O1 - ecran OK");
  oled.drawStr(0, 48, "brochage Heltec V3");
  oled.drawStr(0, 62, "confirme");

  oled.sendBuffer();

  Serial.println("Texte envoye a l'ecran.");
  Serial.println("Regarde la carte : tu dois lire JARDIN.");
  Serial.println("Si l'ecran reste noir -> le brochage du clone differe,");
  Serial.println("corriger include/board.h et documenter dans la doc.");
}

void loop() {
  delay(1000);
}

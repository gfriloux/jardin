#pragma once

// Brochage de la carte : Heltec WiFi LoRa 32 (V3), ESP32-S3 + SX1262.
//
// ATTENTION : la carte du projet est un clone (Heemol SX1262 LoRa V3). Ces
// valeurs sont celles documentées par Heltec pour la V3 ; elles sont à
// confirmer sur le clone. C'est précisément ce que vérifient les croquis
// 02-oled et 03-radio. Si l'un des deux échoue, c'est ici — et seulement
// ici — qu'il faut corriger.

// --- Écran OLED SSD1306 128 x 64, en I2C ---
#define PIN_OLED_SDA 17
#define PIN_OLED_SCL 18
#define PIN_OLED_RST 21

// --- Alimentation des périphériques de la carte (dont l'écran) ---
// ACTIF À L'ÉTAT BAS : digitalWrite(PIN_VEXT, LOW) met sous tension.
//
// Le guide GPIO de Heltec annonce GPIO 33 à 38 comme réservés au SPI Flash /
// SubSPI. C'est vrai du chip ESP32-S3 en configuration octale ; la V3 utilise
// une flash quad, ce qui libère 36 et 37 pour la carte elle-même. D'où cette
// affectation, qui contredit la lecture rapide du guide sans la contredire
// vraiment. Le croquis 02-oled tranche.
#define PIN_VEXT 36

// --- LED utilisateur ---
#define PIN_LED 35

// --- Radio LoRa SX1262, en SPI ---
#define PIN_LORA_NSS 8
#define PIN_LORA_SCK 9
#define PIN_LORA_MOSI 10
#define PIN_LORA_MISO 11
#define PIN_LORA_RST 12
#define PIN_LORA_BUSY 13
#define PIN_LORA_DIO1 14

// --- Mesure de la tension de batterie ---
#define PIN_BAT_ADC 1
#define PIN_BAT_CTRL 37

// --- Ajouts du projet, hors carte ---
//
// Heltec documente les GPIO utilisables pour du matériel externe sur la V3 :
//   GPIO 1, 2, 4, 5, 6, 7, 19, 20, 47, 48
// dont ADC1 = GPIO 1 à 7, et ADC2 = GPIO 19 et 20. ADC2 est réquisitionné dès
// que la radio Wi-Fi s'active : on reste donc sur ADC1. GPIO 1 sert déjà à la
// mesure de batterie, d'où 6 et 7.
//
// À éviter absolument sur cette carte : les broches de strapping (échec de
// démarrage), GPIO 21 (reset de l'OLED), GPIO 43 et 44 (USB série), GPIO 39
// à 42 (JTAG).
//
// Sortie analogique de la sonde d'humidité.
#define PIN_SOIL_SIG 7

// Alimentation de la sonde, pilotée par un GPIO pour ne l'allumer que pendant
// la mesure (croquis 06). Une sonde capacitive tire ~5 mA, très en dessous des
// 40 mA qu'un GPIO d'ESP32 peut fournir : pas besoin de transistor au POC.
#define PIN_SOIL_PWR 6

// Fréquence radio. La carte est vendue 863–928 MHz : il faut imposer 868 MHz,
// le défaut du module pouvant être hors bande européenne.
#define LORA_FREQ_MHZ 868.1

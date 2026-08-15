// 04b — Diagnostic : la sonde est-elle vraiment reliée à l'ADC ?
//
// À utiliser quand 04-sonde renvoie des valeurs proches de zéro, très bruitées,
// avec des sauts sporadiques. Ce motif a deux causes possibles, qu'on ne
// distingue pas à l'œil :
//
//   a) la broche flotte — AOUT ne fait pas contact, ou la sonde n'est pas
//      alimentée, et l'ADC lit du bruit ;
//   b) la sonde est bien reliée mais son oscillateur ne démarre pas, ce qui
//      arrive quand une sonde prévue pour 5 V est alimentée en 3,3 V.
//
// Le test : on lit la broche dans trois configurations. Les résistances
// internes de l'ESP32 valent environ 45 kΩ. Une sortie de sonde alimentée est
// une source de basse impédance : elle impose sa tension malgré elles. Une
// broche qui flotte, au contraire, suit docilement.
//
//   broche flottante  -> pull-up envoie vers 4095, pull-down vers 0
//   sonde reliée      -> les trois lectures restent proches
//
// Câblage identique à 04-sonde. Aucun démontage nécessaire.

#include <Arduino.h>

#include "board.h"

static const int ECHANTILLONS = 64;

// Lectures jetees apres chaque changement de mode. La capacite parasite de la
// broche et de l'echantillonneur met quelques millisecondes a se vider : sans
// ce rejet, la premiere lecture porte encore la trace du mode precedent et
// gonfle l'etendue de plusieurs centaines de points, ce qui suffit a faire
// conclure a tort a un contact intermittent.
static const int REJET = 8;

// Moyenne, minimum et maximum sur ECHANTILLONS lectures.
static void mesure(const char *nom, int mode, int *moy, int *mini, int *maxi) {
  pinMode(PIN_SOIL_SIG, mode);
  delay(50);

  for (int i = 0; i < REJET; i++) {
    analogRead(PIN_SOIL_SIG);
    delay(5);
  }

  long somme = 0;
  *mini = 4095;
  *maxi = 0;

  for (int i = 0; i < ECHANTILLONS; i++) {
    int v = analogRead(PIN_SOIL_SIG);
    somme += v;
    if (v < *mini) *mini = v;
    if (v > *maxi) *maxi = v;
    delay(5);
  }

  *moy = somme / ECHANTILLONS;
  Serial.printf("%-12s moy=%4d  min=%4d  max=%4d  etendue=%4d\n", nom, *moy,
                *mini, *maxi, *maxi - *mini);
}

void setup() {
  Serial.begin(115200);
  delay(2000);

  Serial.println();
  Serial.println("=== 04b-sonde-diag ===");
  Serial.printf("broche testee : GPIO %d\n", PIN_SOIL_SIG);
  Serial.println();

  analogReadResolution(12);
  analogSetPinAttenuation(PIN_SOIL_SIG, ADC_11db);

  int flottant, pullup, pulldown;
  int mn, mx;

  mesure("flottant", INPUT, &flottant, &mn, &mx);
  int etendue = mx - mn;

  mesure("pull-up", INPUT_PULLUP, &pullup, &mn, &mx);
  mesure("pull-down", INPUT_PULLDOWN, &pulldown, &mn, &mx);

  Serial.println();

  // Le test des tirages passe en premier, parce que c'est le seul qui mesure
  // une propriete physique plutot qu'un symptome : une broche libre suit la
  // resistance interne d'un bout a l'autre de la plage, une source de basse
  // impedance lui resiste. Les autres verdicts se lisent ensuite.
  int amplitude = pullup - pulldown;

  if (amplitude > 2000) {
    Serial.println("VERDICT : la broche FLOTTE.");
    Serial.println();
    Serial.println("Rien n'est relie a GPIO 7, ou la sonde n'est pas alimentee.");
    Serial.println("A verifier, dans cet ordre :");
    Serial.println("  - le fil AOUT est-il bien enfonce, des deux cotes ?");
    Serial.println("  - VCC et GND de la sonde sont-ils sur les bonnes lignes");
    Serial.println("    de la breadboard ? Les rails d'alimentation sont");
    Serial.println("    souvent coupes en deux au milieu de la planche.");
    Serial.println("  - la breadboard elle-meme : change de rangee.");
  } else if (etendue > 800) {
    Serial.println("VERDICT : contact INTERMITTENT.");
    Serial.println();
    Serial.println("Sonde immobile, et pourtant la lecture saute d'un bout a");
    Serial.println("l'autre de la plage. Un fil ne tient pas. Les valeurs");
    Serial.println("hautes sont les vraies : c'est quand le contact se fait.");
    Serial.println();
    Serial.println("A reprendre, dans cet ordre de probabilite :");
    Serial.println("  - le connecteur PH2.0 entre la sonde et sa rallonge ;");
    Serial.println("  - les points de la breadboard : change de rangee, les");
    Serial.println("    lamelles fatiguent et ne serrent plus les fils fins ;");
    Serial.println("  - les deux extremites du fil AOUT.");
    Serial.println();
    Serial.println("Remue chaque fil pendant le suivi ci-dessous : celui qui");
    Serial.println("fait decrocher la valeur est le coupable.");
  } else if (flottant < 200) {
    Serial.println("VERDICT : la broche est TENUE A LA MASSE.");
    Serial.println();
    Serial.println("Le tirage interne n'arrive pas a la soulever : quelque");
    Serial.println("chose de basse impedance l'y maintient. Deux causes, et");
    Serial.println("elles sont electriquement indiscernables d'ici :");
    Serial.println();
    Serial.println("  1. AOUT est en fait relie a GND. Une erreur d'une rangee");
    Serial.println("     sur la breadboard suffit. C'est le cas le plus");
    Serial.println("     frequent, surtout apres avoir refait le cablage.");
    Serial.println("  2. La sonde est alimentee mais sa sortie reste au repos");
    Serial.println("     - oscillateur qui ne demarre pas, ce qui arrive quand");
    Serial.println("     un module capacitif est alimente en 3,3 V alors qu'il");
    Serial.println("     lui faut davantage.");
    Serial.println();
    Serial.println("POUR TRANCHER : debranche le fil AOUT du cote de la SONDE");
    Serial.println("seulement, en le laissant sur GPIO 7, et relance.");
    Serial.println("  -> verdict FLOTTE : le chemin est sain, la sonde est en");
    Serial.println("     cause. Mesure alors sa tension d'alimentation.");
    Serial.println("  -> verdict inchange : le court-circuit est dans le");
    Serial.println("     cablage, pas dans la sonde. Reprends les rangees.");
  } else {
    Serial.println("VERDICT : la sonde repond.");
    Serial.println();
    Serial.println("La lecture flottante est deja dans une plage credible.");
    Serial.println("Si 04-sonde donne autre chose, le probleme est");
    Serial.println("intermittent : un fil bouge. Reprends chaque contact.");
  }

  Serial.println();
  Serial.println("Rappel des ordres de grandeur attendus, sonde alimentee :");
  Serial.println("  en l'air        ~2500 a 3000");
  Serial.println("  dans l'eau      nettement plus bas");
  Serial.println("  doigts dessus   la valeur doit bouger visiblement");
}

void loop() {
  // Le diagnostic tient dans setup(). On boucle sur une lecture simple pour
  // pouvoir remuer les fils et voir la valeur reagir en direct.
  Serial.printf("suivi  raw=%4d\n", analogRead(PIN_SOIL_SIG));
  delay(500);
}

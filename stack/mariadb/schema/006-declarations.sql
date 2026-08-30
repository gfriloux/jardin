-- =====================================================================
--  Jardin — les déclarations du terrain
--
--  Ce fichier est la SEULE source des objets déclarés à la main : les
--  cartes, les zones, et les points de mesure. Tout le reste de la base
--  se reconstruit depuis l'archive NDJSON par simple réimport ; ce qu'on
--  déclare, lui, n'existe nulle part ailleurs.
--
--  Le mettre dans docker-entrypoint-initdb.d garantit qu'une base
--  recréée de zéro repart avec le même référentiel. Sans ça, `just
--  db-reset` effacerait des déclarations qu'aucune archive ne pourrait
--  rejouer — et les mesures redeviendraient non attribuables, alors même
--  que l'archive serait intacte.
--
--  Tout y est IDEMPOTENT : le fichier s'applique aussi bien à une base
--  neuve qu'à une base déjà peuplée, et se rejoue sans effet de bord.
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- Les cartes.
--
-- L'importeur crée d'office un nœud inconnu plutôt que de rejeter la
-- trame — perdre une mesure parce qu'une déclaration manque serait le
-- mauvais arbitrage. Ce fichier vient donc compléter une ligne qui
-- existe peut-être déjà, d'où le ON DUPLICATE KEY.
-- ---------------------------------------------------------------------
INSERT INTO node (uid, label, hardware, commissioned_on, notes) VALUES
  ('NODE-001',
   'Nœud du jardin',
   'Heemol SX1262 LoRa V3 — ESP32-S3 + SX1262, clone Heltec WiFi LoRa 32 V3',
   '2026-08-30',
   'Première mise en service le 30 août 2026, campagne de portée de O4.')
ON DUPLICATE KEY UPDATE
  label           = VALUES(label),
  hardware        = VALUES(hardware),
  commissioned_on = VALUES(commissioned_on),
  notes           = VALUES(notes);

-- ---------------------------------------------------------------------
-- Les zones.
--
-- Une zone est une décision du jardinier, pas un calcul : c'est ce qu'on
-- arrosera d'un seul geste. Sa géométrie n'est donc pas critique — la
-- mesure pointe la zone, jamais ses coordonnées, et affiner le polygone
-- plus tard n'altère aucune ligne d'historique.
--
-- PROVISOIRE : rectangle de 5 m × 3 m en repère local métrique, posé à
-- l'origine. À remplacer par le tracé réel relevé sur le fond de plan
-- cadastral (tools/plan-parcelle.py), quand ce sera le sujet.
-- ---------------------------------------------------------------------
INSERT INTO zone (uid, label, boundary, notes) VALUES
  ('FRAISIERS',
   'Les fraisiers',
   ST_GeomFromText('POLYGON((0 0, 5 0, 5 3, 0 3, 0 0))'),
   'Géométrie provisoire : rectangle 5 m × 3 m, à relever sur le plan.')
ON DUPLICATE KEY UPDATE
  label    = VALUES(label),
  boundary = VALUES(boundary),
  notes    = VALUES(notes);

-- ---------------------------------------------------------------------
-- Les points de mesure : ce qui est branché où, et comment ça s'appelle.
--
-- On ne déclare pas quel exemplaire de sonde y est branché — voir
-- ADR-017. Le jour où celle-ci meurt, on en met une neuve et RIEN ne
-- change ici : c'est la même voie, au même endroit, qui mesure la même
-- chose. Aucune ligne de SQL à écrire pour un remplacement.
--
-- `valid_from` doit précéder la première mesure à rattacher, sinon la
-- vue laisse la mesure orpheline sans rien signaler : v_measurement
-- joint sur `received_at >= valid_from`. La première trame archivée date
-- du 30 août 2026 à 11:29 UTC, d'où minuit ce jour-là.
--
-- La table n'a pas de clé unique — une voie se redéclare légitimement
-- dans le temps, c'est tout l'intérêt des dates. L'idempotence passe
-- donc par un NOT EXISTS sur la déclaration courante.
--
-- `depth_cm` reste NULL tant que rien n'est enterré : la campagne de
-- portée a promené la sonde à la main. Ce sera le sujet de O7.
-- ---------------------------------------------------------------------
INSERT INTO measurement_point (node_id, channel, label, zone_id, valid_from, notes)
SELECT n.id, 'soil-01', 'Fraisiers — humidité', z.id, '2026-08-30 00:00:00',
       'Branchement direct sur GPIO 7, sans multiplexeur — montage de O1.'
FROM node n, zone z
WHERE n.uid = 'NODE-001'
  AND z.uid = 'FRAISIERS'
  AND NOT EXISTS (
    SELECT 1 FROM measurement_point mp
    WHERE mp.node_id = n.id AND mp.channel = 'soil-01'
      AND mp.valid_to IS NULL
  );

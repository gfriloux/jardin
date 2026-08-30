-- =====================================================================
--  Jardin — les déclarations du terrain
--
--  Ce fichier est la SEULE source des objets déclarés à la main : les
--  cartes, les sondes, les zones, et les liaisons datées entre elles.
--  Tout le reste de la base se reconstruit depuis l'archive NDJSON par
--  simple réimport ; ce qu'on déclare, lui, n'existe nulle part ailleurs.
--
--  Le mettre ici, dans docker-entrypoint-initdb.d, garantit qu'une base
--  recréée de zéro repart avec le même référentiel. Sans ça, `just
--  db-reset` effacerait des déclarations qu'aucune archive ne pourrait
--  rejouer — et les mesures redeviendraient non attribuables, alors même
--  que l'archive serait intacte.
--
--  Tout y est IDEMPOTENT : le fichier s'applique aussi bien à une base
--  neuve qu'à une base déjà peuplée, et se rejoue sans effet de bord.
--  C'est ce qui permet de l'appliquer à chaud après l'avoir modifié.
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
-- Les sondes, en tant qu'objets physiques.
--
-- `uid` est l'étiquette écrite au marqueur indélébile SUR la sonde. Ce
-- n'est pas une convention de nommage interne : c'est ce qu'on lit en la
-- sortant de terre. Les trois du lot A sont interchangeables — O3 a
-- mesuré 7,8 points de divergence maximale, soit moins que le bruit de
-- la procédure qui les distinguerait — mais elles restent trois objets
-- distincts, qu'on peut déplacer indépendamment.
--
-- Seule SOIL-A1 est déclarée pour l'instant : c'est la seule branchée.
-- Les deux autres viendront avec O2, quand le multiplexeur les mettra
-- en service.
-- ---------------------------------------------------------------------
INSERT INTO sensor (uid, measurement_type, model, acquired_on, notes) VALUES
  ('SOIL-A1',
   'soil_moisture',
   'DollaTek — sonde capacitive, résistante à la corrosion',
   '2026-08-15',
   'Lot A, trois sondes achetées ensemble. Capacitive et non résistive.')
ON DUPLICATE KEY UPDATE
  measurement_type = VALUES(measurement_type),
  model            = VALUES(model),
  acquired_on      = VALUES(acquired_on),
  notes            = VALUES(notes);

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
-- LIAISON sonde <-> voie du nœud.
--
-- `valid_from` doit précéder la première mesure à rattacher, sinon la
-- vue laisse la mesure orpheline sans rien signaler : v_measurement
-- joint sur `received_at >= valid_from`. La première trame archivée date
-- du 30 août 2026 à 11:29 UTC, d'où minuit ce jour-là.
--
-- Ces tables n'ont pas de clé unique — les liaisons se répètent
-- légitimement dans le temps, c'est tout leur intérêt. L'idempotence
-- passe donc par un NOT EXISTS sur le branchement courant.
-- ---------------------------------------------------------------------
INSERT INTO sensor_attachment (sensor_id, node_id, channel, valid_from, notes)
SELECT s.id, n.id, 'soil-01', '2026-08-30 00:00:00',
       'Branchement direct sur GPIO 7, sans multiplexeur — montage de O1.'
FROM sensor s, node n
WHERE s.uid = 'SOIL-A1'
  AND n.uid = 'NODE-001'
  AND NOT EXISTS (
    SELECT 1 FROM sensor_attachment a
    WHERE a.sensor_id = s.id AND a.node_id = n.id
      AND a.channel = 'soil-01' AND a.valid_to IS NULL
  );

-- ---------------------------------------------------------------------
-- IMPLANTATION de la sonde dans le terrain.
--
-- Séparée de la liaison, parce qu'une sonde se déplace dans le jardin
-- sans changer de nœud, et change de nœud sans se déplacer.
--
-- `depth_cm` est laissée NULL tant que la sonde n'est pas réellement en
-- terre : la campagne de portée l'a promenée à la main. Ce sera le sujet
-- de O7.
-- ---------------------------------------------------------------------
INSERT INTO sensor_placement (sensor_id, zone_id, valid_from, notes)
SELECT s.id, z.id, '2026-08-30 00:00:00',
       'Implantation déclarative : la sonde n''est pas encore enterrée.'
FROM sensor s, zone z
WHERE s.uid = 'SOIL-A1'
  AND z.uid = 'FRAISIERS'
  AND NOT EXISTS (
    SELECT 1 FROM sensor_placement p
    WHERE p.sensor_id = s.id AND p.valid_to IS NULL
  );

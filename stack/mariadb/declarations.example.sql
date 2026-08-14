-- =====================================================================
--  Modèle de déclaration du matériel.
--
--  Ce fichier n'est PAS appliqué automatiquement : les déclarations sont
--  un acte volontaire, pas une migration. Copie-le, adapte-le, applique-le
--  avec `just db` quand le matériel est réellement en place.
--
--  Règle de survie : le `uid` d'une sonde doit être ÉCRIT SUR LA SONDE,
--  au marqueur indélébile, avant de la mettre en terre. Sans étiquetage
--  physique, le jour où deux sondes divergent, plus rien n'est
--  attribuable.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Les cartes LoRa. `uid` doit correspondre EXACTEMENT à ce que le nœud
-- émet dans sa trame.
-- ---------------------------------------------------------------------
INSERT INTO node (uid, label, hardware, commissioned_on) VALUES
  ('NODE-001', 'Allee fraisiers', 'Heltec WiFi LoRa 32 V3 (clone Heemol)', '2026-08-15');

-- ---------------------------------------------------------------------
-- Les sondes, une ligne par objet physique.
-- ---------------------------------------------------------------------
INSERT INTO sensor (uid, measurement_type, model, acquired_on) VALUES
  ('SOIL-A1', 'soil_moisture', 'Capacitive v1.2 (DollaTek)', '2026-08-15'),
  ('SOIL-A2', 'soil_moisture', 'Capacitive v1.2 (DollaTek)', '2026-08-15'),
  ('SOIL-A3', 'soil_moisture', 'Capacitive v1.2 (DollaTek)', '2026-08-15');

-- ---------------------------------------------------------------------
-- Les zones, en repère local et en mètres. Le polygone doit être fermé :
-- le dernier point répète le premier.
-- ---------------------------------------------------------------------
INSERT INTO zone (uid, label, boundary) VALUES
  ('FRAISIERS', 'Allee de fraisiers',
   ST_GeomFromText('POLYGON((0 0, 15 0, 15 0.5, 0 0.5, 0 0))'));

-- ---------------------------------------------------------------------
-- Le câblage. `channel` est la clé telle qu'elle apparaît dans la trame.
-- `valid_from` est le moment du branchement, pas celui de la saisie.
-- ---------------------------------------------------------------------
INSERT INTO sensor_attachment (sensor_id, node_id, channel, valid_from) VALUES
  ((SELECT id FROM sensor WHERE uid='SOIL-A1'),
   (SELECT id FROM node   WHERE uid='NODE-001'), 'soil-01', '2026-08-15 08:00:00'),
  ((SELECT id FROM sensor WHERE uid='SOIL-A2'),
   (SELECT id FROM node   WHERE uid='NODE-001'), 'soil-02', '2026-08-15 08:00:00'),
  ((SELECT id FROM sensor WHERE uid='SOIL-A3'),
   (SELECT id FROM node   WHERE uid='NODE-001'), 'soil-03', '2026-08-15 08:00:00');

-- ---------------------------------------------------------------------
-- L'implantation. `position` sert à la carte ; c'est `zone_id` qui fait
-- foi pour l'agrégation.
-- ---------------------------------------------------------------------
INSERT INTO sensor_placement (sensor_id, zone_id, position, depth_cm, valid_from) VALUES
  ((SELECT id FROM sensor WHERE uid='SOIL-A1'), (SELECT id FROM zone WHERE uid='FRAISIERS'),
   ST_GeomFromText('POINT(2 0.25)'),  10, '2026-08-15 08:00:00'),
  ((SELECT id FROM sensor WHERE uid='SOIL-A2'), (SELECT id FROM zone WHERE uid='FRAISIERS'),
   ST_GeomFromText('POINT(7 0.25)'),  10, '2026-08-15 08:00:00'),
  ((SELECT id FROM sensor WHERE uid='SOIL-A3'), (SELECT id FROM zone WHERE uid='FRAISIERS'),
   ST_GeomFromText('POINT(12 0.25)'), 20, '2026-08-15 08:00:00');

-- ---------------------------------------------------------------------
-- La calibration, une fois O3 fait. Jamais appliquée aux données
-- stockées : la corriger recalcule tout l'historique.
-- ---------------------------------------------------------------------
-- INSERT INTO calibration (sensor_id, method, params, valid_from) VALUES
--   ((SELECT id FROM sensor WHERE uid='SOIL-A1'),
--    'linear2pt', '{"dry": 2850, "wet": 1250}', '2026-08-15 08:00:00');

-- =====================================================================
--  DÉPLACER UNE SONDE — la manœuvre à connaître.
--
--  Ne JAMAIS modifier la ligne existante : on la clôt, et on en ouvre une
--  nouvelle. Sinon tout l'historique est réattribué rétroactivement, en
--  silence, à la nouvelle position.
-- =====================================================================
-- UPDATE sensor_attachment SET valid_to = '2026-09-01 09:00:00'
--  WHERE sensor_id = (SELECT id FROM sensor WHERE uid='SOIL-A3')
--    AND valid_to IS NULL;
--
-- INSERT INTO sensor_attachment (sensor_id, node_id, channel, valid_from) VALUES
--   ((SELECT id FROM sensor WHERE uid='SOIL-A3'),
--    (SELECT id FROM node   WHERE uid='NODE-002'), 'soil-01', '2026-09-01 09:00:00');
--
-- Idem pour sensor_placement. Vérifier ensuite avec :
--   SELECT * FROM v_current_wiring;

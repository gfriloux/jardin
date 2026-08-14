-- =====================================================================
--  Jardin — référentiel : ce qu'on déclare à la main
--
--  Trois objets physiques distincts, et c'est la distinction la plus
--  importante du schéma :
--
--    node    une carte LoRa. Elle a un identifiant qu'elle émet.
--    sensor  une sonde. Un objet qu'on tient dans la main, qu'on
--            étiquette, qu'on peut débrancher et rebrancher ailleurs.
--    channel la voie sur laquelle une sonde est branchée sur un nœud.
--            'soil-01' n'est PAS une sonde : c'est une prise.
--
--  NODE-001/soil-01 et NODE-002/soil-01 sont deux prises différentes,
--  et la même sonde peut passer de l'une à l'autre. D'où une table de
--  liaison datée plutôt qu'une clé étrangère directe.
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- Types de mesure. Table de référence pour éviter les fautes de frappe
-- silencieuses, qui fragmenteraient les données sans erreur visible.
-- ---------------------------------------------------------------------
CREATE TABLE measurement_type (
  code         VARCHAR(32)  NOT NULL PRIMARY KEY,
  default_unit VARCHAR(16)  NOT NULL,
  label        VARCHAR(128) NOT NULL
) ENGINE=InnoDB;

INSERT INTO measurement_type (code, default_unit, label) VALUES
  ('soil_moisture',    'raw',   'Humidité du sol, valeur brute d''ADC'),
  ('soil_temperature', 'degC',  'Température du sol'),
  ('temperature',      'degC',  'Température de l''air'),
  ('humidity',         'pct',   'Humidité de l''air'),
  ('illuminance',      'lx',    'Luminosité'),
  ('rainfall',         'mm',    'Pluviométrie'),
  ('water_level',      'cm',    'Niveau d''une cuve'),
  ('flow_rate',        'L/min', 'Débit'),
  ('pressure',         'hPa',   'Pression'),
  ('voltage',          'V',     'Tension');

-- ---------------------------------------------------------------------
-- Les cartes LoRa.
-- `uid` est la chaîne que le nœud émet lui-même dans sa trame.
-- ---------------------------------------------------------------------
CREATE TABLE node (
  id                INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  uid               VARCHAR(32)  NOT NULL,
  label             VARCHAR(128) NOT NULL,
  hardware          VARCHAR(128) NULL,
  commissioned_on   DATE NULL,
  decommissioned_on DATE NULL,
  notes             TEXT NULL,
  UNIQUE KEY uq_node_uid (uid)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Les sondes, en tant qu'objets physiques.
-- `uid` est l'étiquette collée dessus. Sans étiquetage physique, les
-- mesures ne sont attribuables à rien le jour où deux sondes divergent.
-- ---------------------------------------------------------------------
CREATE TABLE sensor (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  uid              VARCHAR(32)  NOT NULL,
  measurement_type VARCHAR(32)  NOT NULL,
  model            VARCHAR(128) NULL,
  acquired_on      DATE NULL,
  retired_on       DATE NULL,
  notes            TEXT NULL,
  UNIQUE KEY uq_sensor_uid (uid),
  CONSTRAINT fk_sensor_type
    FOREIGN KEY (measurement_type) REFERENCES measurement_type (code)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Les zones du terrain.
--
-- Une zone est une DÉCISION du jardinier — une planche, une rangée, un
-- pied d'arbre — pas un calcul. C'est ce qui correspond à l'action
-- réelle : une électrovanne arrose une zone, pas un point.
--
-- `boundary` est en repère local, en mètres. Pas de latitude/longitude :
-- pour un jardin, la courbure de la Terre n'intervient pas, et un repère
-- métrique local rend les distances directement lisibles.
-- ---------------------------------------------------------------------
CREATE TABLE zone (
  id       INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  uid      VARCHAR(32)  NOT NULL,
  label    VARCHAR(128) NOT NULL,
  boundary POLYGON      NOT NULL,
  notes    TEXT NULL,
  UNIQUE KEY uq_zone_uid (uid),
  SPATIAL INDEX idx_zone_boundary (boundary)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- LIAISON sonde <-> nœud, datée.
--
-- C'est la table qui répond à « déclarer les sondes, les cartes, et les
-- liaisons entre ». Elle est datée parce que ces liaisons bougent :
-- on déplace une sonde, on remplace un nœud grillé, on réaffecte une
-- voie de multiplexeur. Sans date, tout l'historique serait réattribué
-- rétroactivement au dernier branchement — silencieusement.
--
-- valid_to NULL = branchement courant.
-- ---------------------------------------------------------------------
CREATE TABLE sensor_attachment (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  sensor_id  INT UNSIGNED NOT NULL,
  node_id    INT UNSIGNED NOT NULL,
  channel    VARCHAR(32)  NOT NULL,
  valid_from DATETIME(3)  NOT NULL,
  valid_to   DATETIME(3)  NULL,
  notes      TEXT NULL,
  KEY idx_attachment_lookup (node_id, channel, valid_from),
  KEY idx_attachment_sensor (sensor_id, valid_from),
  CONSTRAINT fk_attachment_sensor
    FOREIGN KEY (sensor_id) REFERENCES sensor (id),
  CONSTRAINT fk_attachment_node
    FOREIGN KEY (node_id) REFERENCES node (id),
  CONSTRAINT ck_attachment_period
    CHECK (valid_to IS NULL OR valid_to > valid_from)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- IMPLANTATION d'une sonde, datée elle aussi.
--
-- Séparée de la liaison : une sonde peut être déplacée dans le jardin
-- sans changer de nœud, et inversement.
--
-- `zone_id` est obligatoire, `position` non : l'appartenance à une zone
-- est la décision qui compte, la position exacte ne sert qu'à la carte.
-- ---------------------------------------------------------------------
CREATE TABLE sensor_placement (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  sensor_id  INT UNSIGNED NOT NULL,
  zone_id    INT UNSIGNED NOT NULL,
  position   POINT NULL,
  depth_cm   SMALLINT UNSIGNED NULL,
  valid_from DATETIME(3) NOT NULL,
  valid_to   DATETIME(3) NULL,
  notes      TEXT NULL,
  KEY idx_placement_sensor (sensor_id, valid_from),
  CONSTRAINT fk_placement_sensor
    FOREIGN KEY (sensor_id) REFERENCES sensor (id),
  CONSTRAINT fk_placement_zone
    FOREIGN KEY (zone_id) REFERENCES zone (id),
  CONSTRAINT ck_placement_period
    CHECK (valid_to IS NULL OR valid_to > valid_from)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Calibration, datée. Jamais appliquée aux données stockées : elle est
-- calculée à la lecture, pour rester rejouable sur tout l'historique.
-- Voir ADR-002.
-- ---------------------------------------------------------------------
CREATE TABLE calibration (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  sensor_id  INT UNSIGNED NOT NULL,
  method     VARCHAR(32)  NOT NULL,
  params     JSON         NOT NULL,
  valid_from DATETIME(3)  NOT NULL,
  valid_to   DATETIME(3)  NULL,
  notes      TEXT NULL,
  KEY idx_calibration_sensor (sensor_id, valid_from),
  CONSTRAINT fk_calibration_sensor
    FOREIGN KEY (sensor_id) REFERENCES sensor (id),
  CONSTRAINT ck_calibration_period
    CHECK (valid_to IS NULL OR valid_to > valid_from)
) ENGINE=InnoDB;

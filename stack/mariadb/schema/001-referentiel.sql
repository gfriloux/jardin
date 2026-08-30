-- =====================================================================
--  Jardin — référentiel : ce qu'on déclare à la main
--
--  Deux objets déclarés, et c'est la distinction qui structure tout :
--
--    node              une carte LoRa. Elle émet son propre identifiant.
--    measurement_point une VOIE de mesure : « ce qui est branché sur
--                      NODE-001/soil-01, comment ça s'appelle à l'écran,
--                      et dans quelle zone ça se trouve ».
--
--  Ce qu'on ne déclare PAS : la sonde en tant qu'objet physique. Voir
--  ADR-017. Les sondes capacitives sont interchangeables — O3 l'a mesuré
--  — et les suivre individuellement demanderait de les étiqueter au
--  marqueur pour une information que personne n'irait lire. On change un
--  pneu sans le baptiser.
--
--  Ce qu'on garde en revanche : les DATES. Elles ne suivent pas du
--  matériel, elles suivent le CÂBLAGE. Le jour où une voie change de
--  zone, sans date la nouvelle déclaration réattribuerait tout
--  l'historique passé à la nouvelle zone, silencieusement.
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
-- Comment déduire le type d'une mesure à partir du nom de sa voie.
--
-- La trame ne transporte pas de type : le nœud émet `"soil-01": 1834`,
-- sans dire ce que c'est. Trois façons de résoudre :
--
--   - passer par du matériel déclaré. Correct, mais alors rien ne rentre
--     tant que la déclaration n'est pas faite, et on perdrait des mesures ;
--   - coder la convention dans l'importeur. Il faudrait recompiler pour
--     ajouter un type ;
--   - cette table. Déclarative, visible, modifiable à chaud.
--
-- Le préfixe le plus long l'emporte, ce qui permet des exceptions.
--
-- C'est ici, et NULLE PART AILLEURS, qu'on dit quel type de mesure
-- correspond à quelle voie. `measurement_point` ne le redit pas : deux
-- sources de vérité finiraient par diverger sans que rien ne le signale.
-- ---------------------------------------------------------------------
CREATE TABLE channel_convention (
  prefix           VARCHAR(32) NOT NULL PRIMARY KEY,
  measurement_type VARCHAR(32) NOT NULL,
  unit             VARCHAR(16) NOT NULL,
  CONSTRAINT fk_convention_type
    FOREIGN KEY (measurement_type) REFERENCES measurement_type (code)
) ENGINE=InnoDB;

INSERT INTO channel_convention (prefix, measurement_type, unit) VALUES
  ('soil-',    'soil_moisture',    'raw'),
  ('soiltemp-','soil_temperature', 'degC'),
  ('battery',  'voltage',          'V'),
  ('temp-',    'temperature',      'degC'),
  ('hum-',     'humidity',         'pct'),
  ('lux-',     'illuminance',      'lx'),
  ('rain-',    'rainfall',         'mm'),
  ('level-',   'water_level',      'cm'),
  ('flow-',    'flow_rate',        'L/min');

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
-- LE POINT DE MESURE — une voie d'un nœud, datée.
--
-- C'est la seule table de câblage, et elle répond à trois questions à la
-- fois : qu'est-ce qui est branché sur cette voie, comment ça s'appelle
-- à l'écran, et où ça se trouve.
--
-- Ce qu'elle ne dit PAS : quel exemplaire de sonde y est branché. Si une
-- sonde meurt, on la remplace et rien ne change ici — c'est la même voie
-- qui mesure la même chose au même endroit. Voir ADR-017.
--
-- Le TYPE de mesure n'y figure pas non plus : il se déduit du nom de la
-- voie via `channel_convention`, plus haut dans ce fichier, où `soil-`
-- donne `soil_moisture`. Le redéclarer ici créerait deux sources de
-- vérité capables de diverger sans que rien ne le signale.
--
-- `label` est le nom lu dans Grafana. C'est le seul endroit où l'on
-- nomme quelque chose, et ce nom décrit un emplacement, pas un objet.
--
-- `zone_id` est obligatoire, `position` non : l'appartenance à une zone
-- est la décision qui compte, la position exacte ne sert qu'à la carte.
--
-- valid_to NULL = câblage courant.
-- ---------------------------------------------------------------------
CREATE TABLE measurement_point (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  node_id    INT UNSIGNED NOT NULL,
  channel    VARCHAR(32)  NOT NULL,
  label      VARCHAR(128) NOT NULL,
  zone_id    INT UNSIGNED NOT NULL,
  position   POINT        NULL,
  depth_cm   SMALLINT UNSIGNED NULL,
  valid_from DATETIME(3)  NOT NULL,
  valid_to   DATETIME(3)  NULL,
  notes      TEXT NULL,
  KEY idx_point_lookup (node_id, channel, valid_from),
  KEY idx_point_zone (zone_id),
  CONSTRAINT fk_point_node
    FOREIGN KEY (node_id) REFERENCES node (id),
  CONSTRAINT fk_point_zone
    FOREIGN KEY (zone_id) REFERENCES zone (id),
  CONSTRAINT ck_point_period
    CHECK (valid_to IS NULL OR valid_to > valid_from)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Calibration, datée. Jamais appliquée aux données stockées : elle est
-- calculée à la lecture, pour rester rejouable sur tout l'historique.
-- Voir ADR-002.
--
-- Elle porte sur le POINT et non sur la sonde : depuis l'ADR-015 on ne
-- calibre plus finement un système qui prend une décision binaire, et
-- depuis l'ADR-017 la sonde n'est plus un objet suivi. Ce qui se calibre
-- est donc « cette voie, à cet endroit », ce qui inclut le sol autant
-- que l'électronique — et c'est bien ce qu'on veut.
-- ---------------------------------------------------------------------
CREATE TABLE calibration (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  point_id   INT UNSIGNED NOT NULL,
  method     VARCHAR(32)  NOT NULL,
  params     JSON         NOT NULL,
  valid_from DATETIME(3)  NOT NULL,
  valid_to   DATETIME(3)  NULL,
  notes      TEXT NULL,
  KEY idx_calibration_point (point_id, valid_from),
  CONSTRAINT fk_calibration_point
    FOREIGN KEY (point_id) REFERENCES measurement_point (id),
  CONSTRAINT ck_calibration_period
    CHECK (valid_to IS NULL OR valid_to > valid_from)
) ENGINE=InnoDB;

-- =====================================================================
--  Jardin — ce dont l'importeur a besoin
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- Avancement de l'import, un repère par fichier d'archive.
--
-- L'unicité de (source_file, source_line) dans `frame` suffirait à garantir
-- l'idempotence, mais obligerait à retenter chaque ligne à chaque passage.
-- Ce repère permet de reprendre où on s'est arrêté. Les fichiers d'archive
-- ne sont jamais réécrits, seulement complétés : le numéro de ligne est donc
-- un repère stable.
-- ---------------------------------------------------------------------
CREATE TABLE import_state (
  source_file  VARCHAR(255) NOT NULL PRIMARY KEY,
  last_line    INT UNSIGNED NOT NULL DEFAULT 0,
  updated_at   DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                            ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Comment déduire le type d'une mesure à partir du nom de sa voie.
--
-- La trame ne transporte pas de type : le nœud émet `"soil-01": 1834`, sans
-- dire ce que c'est. Trois façons de résoudre :
--
--   - passer par la sonde déclarée. Correct, mais alors rien ne rentre tant
--     que le matériel n'est pas déclaré, et on perdrait des mesures ;
--   - coder la convention dans l'importeur. Il faudrait recompiler pour
--     ajouter un type ;
--   - cette table. Déclarative, visible, modifiable à chaud.
--
-- Le préfixe le plus long l'emporte, ce qui permet des exceptions.
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

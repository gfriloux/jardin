-- =====================================================================
--  Jardin — les faits : ce que les nœuds émettent
--
--  Deux niveaux, parce qu'une trame LoRa porte plusieurs mesures :
--    frame        une trame reçue. Porte le lien radio (RSSI, SNR) et
--                 l'horodatage, qui sont des propriétés de la RÉCEPTION.
--    measurement  une valeur dans cette trame.
--
--  Rien ici ne référence une sonde : la trame ne connaît que des voies
--  (`channel`). L'attribution à une sonde physique se fait à la lecture,
--  par jointure temporelle sur sensor_attachment. C'est ce qui permet de
--  débrancher une sonde sans réécrire l'historique.
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- Une trame reçue.
--
-- `received_at` est en UTC, posé par le collecteur : le nœud n'a pas
-- d'horloge fiable après un deep sleep, il n'émet qu'un compteur `seq`.
--
-- `source_file` + `source_line` pointent la ligne de l'archive NDJSON
-- dont vient cette trame. L'unicité sur ce couple rend le réimport
-- idempotent : rejouer toute l'archive ne crée pas de doublon. C'est ce
-- qui fait de cette base un index jetable et reconstructible.
-- ---------------------------------------------------------------------
CREATE TABLE frame (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  node_id     INT UNSIGNED NOT NULL,
  seq         INT UNSIGNED NULL,
  received_at DATETIME(3)  NOT NULL,
  rssi_dbm    SMALLINT     NULL,
  snr_db      DECIMAL(4,1) NULL,
  source_file VARCHAR(255) NOT NULL,
  source_line INT UNSIGNED NOT NULL,
  UNIQUE KEY uq_frame_source (source_file, source_line),
  KEY idx_frame_node_time (node_id, received_at),
  KEY idx_frame_time (received_at),
  CONSTRAINT fk_frame_node FOREIGN KEY (node_id) REFERENCES node (id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Une valeur. `unit` vaut 'raw' pour l'humidité du sol : on ne stocke
-- jamais de pourcentage, voir ADR-002.
-- ---------------------------------------------------------------------
CREATE TABLE measurement (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  frame_id         BIGINT UNSIGNED NOT NULL,
  channel          VARCHAR(32) NOT NULL,
  measurement_type VARCHAR(32) NOT NULL,
  value            DOUBLE      NOT NULL,
  unit             VARCHAR(16) NOT NULL,
  UNIQUE KEY uq_measurement_frame_channel (frame_id, channel),
  KEY idx_measurement_type (measurement_type),
  CONSTRAINT fk_measurement_frame
    FOREIGN KEY (frame_id) REFERENCES frame (id) ON DELETE CASCADE,
  CONSTRAINT fk_measurement_type
    FOREIGN KEY (measurement_type) REFERENCES measurement_type (code)
) ENGINE=InnoDB;

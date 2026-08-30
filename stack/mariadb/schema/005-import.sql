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

-- `channel_convention`, qui dit comment déduire le type d'une mesure du
-- nom de sa voie, vivait ici. Elle est passée dans 001-referentiel.sql :
-- c'est une table de référence, elle pointe `measurement_type` qui s'y
-- trouve déjà, et les vues de 004 en ont besoin — or elles sont créées
-- avant ce fichier.

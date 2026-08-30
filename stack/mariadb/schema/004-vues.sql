-- =====================================================================
--  Jardin — vues de lecture
--
--  Toute l'intelligence du schéma est ici : les tables de faits ne
--  connaissent que des voies, ce sont les vues qui rattachent chaque
--  mesure au point, à la zone et au nom qui étaient en vigueur AU MOMENT
--  de la mesure.
--
--  Conséquence : recâbler une voie n'altère pas une seule ligne
--  d'historique, et l'historique reste correctement attribué.
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- La vue de base. C'est elle qu'on interroge, jamais `measurement`.
--
-- La jointure est en LEFT : une mesure arrivée sur une voie non encore
-- déclarée reste visible, simplement sans nom ni zone. Perdre une mesure
-- parce qu'une déclaration manque serait le mauvais arbitrage — c'est le
-- même choix que fait l'importeur avec les nœuds inconnus.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_measurement AS
SELECT
  f.received_at,
  n.uid              AS node_uid,
  m.channel,
  mp.id              AS point_id,
  mp.label           AS point_label,
  z.uid              AS zone_uid,
  z.label            AS zone_label,
  mp.depth_cm,
  m.measurement_type,
  m.value,
  m.unit,
  f.seq,
  f.rssi_dbm,
  f.snr_db
FROM measurement m
JOIN frame f ON f.id = m.frame_id
JOIN node  n ON n.id = f.node_id
LEFT JOIN measurement_point mp
       ON mp.node_id = f.node_id
      AND mp.channel = m.channel
      AND f.received_at >= mp.valid_from
      AND (mp.valid_to IS NULL OR f.received_at < mp.valid_to)
LEFT JOIN zone z ON z.id = mp.zone_id;

-- ---------------------------------------------------------------------
-- L'humidité du sol, avec sa valeur calibrée calculée à la volée.
--
-- La calibration n'est jamais écrite dans les données : la corriger
-- recalcule tout l'historique sans migration. Voir ADR-002.
--
-- method = 'linear2pt' : interpolation entre deux points, params
--   {"dry": <ADC sol sec>, "wet": <ADC sol sature>}
-- La valeur d'ADC DESCEND quand l'humidite monte, d'ou (dry - value).
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_soil_moisture AS
SELECT
  vm.received_at,
  vm.node_uid,
  vm.channel,
  vm.point_label,
  vm.zone_uid,
  vm.zone_label,
  vm.depth_cm,
  vm.value AS raw,
  CASE
    WHEN c.method = 'linear2pt'
     AND CAST(JSON_VALUE(c.params, '$.dry') AS DOUBLE)
       > CAST(JSON_VALUE(c.params, '$.wet') AS DOUBLE)
    THEN GREATEST(0, LEAST(100,
           100.0 * (CAST(JSON_VALUE(c.params, '$.dry') AS DOUBLE) - vm.value)
                 / (CAST(JSON_VALUE(c.params, '$.dry') AS DOUBLE)
                  - CAST(JSON_VALUE(c.params, '$.wet') AS DOUBLE))))
  END AS moisture_pct,
  vm.rssi_dbm,
  vm.snr_db
FROM v_measurement vm
LEFT JOIN calibration c
       ON c.point_id = vm.point_id
      AND vm.received_at >= c.valid_from
      AND (c.valid_to IS NULL OR vm.received_at < c.valid_to)
WHERE vm.measurement_type = 'soil_moisture';

-- ---------------------------------------------------------------------
-- Le câblage courant : ce qui est branché où, en ce moment.
-- C'est la vue à consulter avant d'aller débrancher quoi que ce soit.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_current_wiring AS
SELECT
  n.uid        AS node_uid,
  mp.channel,
  mp.label     AS point_label,
  cc.measurement_type,
  z.uid        AS zone_uid,
  mp.depth_cm,
  ST_X(mp.position) AS pos_x_m,
  ST_Y(mp.position) AS pos_y_m,
  mp.valid_from AS declared_since
FROM measurement_point mp
JOIN node n ON n.id = mp.node_id
JOIN zone z ON z.id = mp.zone_id
-- Le type vient de la convention de nommage des voies, pas d'une
-- déclaration : le préfixe le plus long l'emporte.
LEFT JOIN channel_convention cc
       ON mp.channel LIKE CONCAT(cc.prefix, '%')
      AND CHAR_LENGTH(cc.prefix) = (
            SELECT MAX(CHAR_LENGTH(c2.prefix))
              FROM channel_convention c2
             WHERE mp.channel LIKE CONCAT(c2.prefix, '%'))
WHERE mp.valid_to IS NULL
ORDER BY n.uid, mp.channel;

-- ---------------------------------------------------------------------
-- Contrôle de cohérence géométrique.
--
-- L'appartenance à une zone est une décision, pas un calcul — mais si
-- la position tombe hors de la zone déclarée, c'est probablement une
-- erreur de saisie. Cette vue les liste, elle n'interdit rien.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_placement_anomalies AS
SELECT
  n.uid  AS node_uid,
  mp.channel,
  mp.label AS point_label,
  z.uid  AS zone_uid,
  ST_X(mp.position) AS pos_x_m,
  ST_Y(mp.position) AS pos_y_m,
  'position hors de la zone declaree' AS anomalie
FROM measurement_point mp
JOIN node n ON n.id = mp.node_id
JOIN zone z ON z.id = mp.zone_id
WHERE mp.position IS NOT NULL
  AND mp.valid_to IS NULL
  AND NOT ST_Contains(z.boundary, mp.position);

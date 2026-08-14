-- =====================================================================
--  Jardin — vues de lecture
--
--  Toute l'intelligence du schéma est ici : les tables de faits ne
--  connaissent que des voies, ce sont les vues qui rattachent chaque
--  mesure à la sonde, l'implantation et la zone qui étaient en vigueur
--  AU MOMENT de la mesure.
--
--  Conséquence : déplacer une sonde n'altère pas une seule ligne
--  d'historique, et l'historique reste correctement attribué.
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- La vue de base. C'est elle qu'on interroge, jamais `measurement`.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_measurement AS
SELECT
  f.received_at,
  n.uid              AS node_uid,
  m.channel,
  s.id               AS sensor_id,
  s.uid              AS sensor_uid,
  z.uid              AS zone_uid,
  z.label            AS zone_label,
  p.depth_cm,
  m.measurement_type,
  m.value,
  m.unit,
  f.seq,
  f.rssi_dbm,
  f.snr_db
FROM measurement m
JOIN frame f ON f.id = m.frame_id
JOIN node  n ON n.id = f.node_id
LEFT JOIN sensor_attachment a
       ON a.node_id = f.node_id
      AND a.channel = m.channel
      AND f.received_at >= a.valid_from
      AND (a.valid_to IS NULL OR f.received_at < a.valid_to)
LEFT JOIN sensor s ON s.id = a.sensor_id
LEFT JOIN sensor_placement p
       ON p.sensor_id = s.id
      AND f.received_at >= p.valid_from
      AND (p.valid_to IS NULL OR f.received_at < p.valid_to)
LEFT JOIN zone z ON z.id = p.zone_id;

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
  vm.sensor_uid,
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
       ON c.sensor_id = vm.sensor_id
      AND vm.received_at >= c.valid_from
      AND (c.valid_to IS NULL OR vm.received_at < c.valid_to)
WHERE vm.measurement_type = 'soil_moisture';

-- ---------------------------------------------------------------------
-- Le câblage courant : quelle sonde est branchée où, en ce moment.
-- C'est la vue à consulter avant d'aller débrancher quoi que ce soit.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_current_wiring AS
SELECT
  n.uid       AS node_uid,
  a.channel,
  s.uid       AS sensor_uid,
  s.model,
  z.uid       AS zone_uid,
  p.depth_cm,
  ST_X(p.position) AS pos_x_m,
  ST_Y(p.position) AS pos_y_m,
  a.valid_from AS attached_since
FROM sensor_attachment a
JOIN node   n ON n.id = a.node_id
JOIN sensor s ON s.id = a.sensor_id
LEFT JOIN sensor_placement p
       ON p.sensor_id = s.id AND p.valid_to IS NULL
LEFT JOIN zone z ON z.id = p.zone_id
WHERE a.valid_to IS NULL
ORDER BY n.uid, a.channel;

-- ---------------------------------------------------------------------
-- Contrôle de cohérence géométrique.
--
-- L'appartenance à une zone est une décision, pas un calcul — mais si
-- la position tombe hors de la zone déclarée, c'est probablement une
-- erreur de saisie. Cette vue les liste, elle n'interdit rien.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_placement_anomalies AS
SELECT
  s.uid AS sensor_uid,
  z.uid AS zone_uid,
  ST_X(p.position) AS pos_x_m,
  ST_Y(p.position) AS pos_y_m,
  'position hors de la zone declaree' AS anomalie
FROM sensor_placement p
JOIN sensor s ON s.id = p.sensor_id
JOIN zone   z ON z.id = p.zone_id
WHERE p.position IS NOT NULL
  AND p.valid_to IS NULL
  AND NOT ST_Contains(z.boundary, p.position);

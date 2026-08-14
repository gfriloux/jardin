-- =====================================================================
--  Jardin — intégrité des périodes
--
--  SQL ne sait pas exprimer déclarativement « ces intervalles ne se
--  chevauchent pas ». Or un chevauchement ne produirait aucune erreur :
--  la jointure temporelle rendrait simplement deux lignes au lieu d'une,
--  et les mesures seraient dupliquées silencieusement.
--
--  D'où ces contrôles. Ils protègent contre la saisie manuelle, qui est
--  exactement le mode d'alimentation de ces tables.
-- =====================================================================

DELIMITER $$

CREATE PROCEDURE assert_attachment_free(
  IN p_id      INT UNSIGNED,
  IN p_sensor  INT UNSIGNED,
  IN p_node    INT UNSIGNED,
  IN p_channel VARCHAR(32),
  IN p_from    DATETIME(3),
  IN p_to      DATETIME(3))
BEGIN
  DECLARE v_count INT;

  -- Deux sondes sur la même voie du même nœud, en même temps.
  SELECT COUNT(*) INTO v_count
    FROM sensor_attachment a
   WHERE a.node_id = p_node
     AND a.channel = p_channel
     AND (p_id IS NULL OR a.id <> p_id)
     AND a.valid_from < COALESCE(p_to, '9999-12-31 00:00:00')
     AND COALESCE(a.valid_to, '9999-12-31 00:00:00') > p_from;

  IF v_count > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Chevauchement : cette voie est deja occupee sur cette periode';
  END IF;

  -- La même sonde branchée à deux endroits en même temps.
  SELECT COUNT(*) INTO v_count
    FROM sensor_attachment a
   WHERE a.sensor_id = p_sensor
     AND (p_id IS NULL OR a.id <> p_id)
     AND a.valid_from < COALESCE(p_to, '9999-12-31 00:00:00')
     AND COALESCE(a.valid_to, '9999-12-31 00:00:00') > p_from;

  IF v_count > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Chevauchement : cette sonde est deja branchee ailleurs sur cette periode';
  END IF;
END$$

CREATE PROCEDURE assert_placement_free(
  IN p_id     INT UNSIGNED,
  IN p_sensor INT UNSIGNED,
  IN p_from   DATETIME(3),
  IN p_to     DATETIME(3))
BEGIN
  DECLARE v_count INT;

  SELECT COUNT(*) INTO v_count
    FROM sensor_placement p
   WHERE p.sensor_id = p_sensor
     AND (p_id IS NULL OR p.id <> p_id)
     AND p.valid_from < COALESCE(p_to, '9999-12-31 00:00:00')
     AND COALESCE(p.valid_to, '9999-12-31 00:00:00') > p_from;

  IF v_count > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Chevauchement : cette sonde a deja une implantation sur cette periode';
  END IF;
END$$

CREATE TRIGGER trg_attachment_bi BEFORE INSERT ON sensor_attachment
FOR EACH ROW
  CALL assert_attachment_free(NULL, NEW.sensor_id, NEW.node_id,
                              NEW.channel, NEW.valid_from, NEW.valid_to)$$

CREATE TRIGGER trg_attachment_bu BEFORE UPDATE ON sensor_attachment
FOR EACH ROW
  CALL assert_attachment_free(NEW.id, NEW.sensor_id, NEW.node_id,
                              NEW.channel, NEW.valid_from, NEW.valid_to)$$

CREATE TRIGGER trg_placement_bi BEFORE INSERT ON sensor_placement
FOR EACH ROW
  CALL assert_placement_free(NULL, NEW.sensor_id,
                             NEW.valid_from, NEW.valid_to)$$

CREATE TRIGGER trg_placement_bu BEFORE UPDATE ON sensor_placement
FOR EACH ROW
  CALL assert_placement_free(NEW.id, NEW.sensor_id,
                             NEW.valid_from, NEW.valid_to)$$

DELIMITER ;

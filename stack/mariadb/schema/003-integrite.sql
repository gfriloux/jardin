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
--
--  Depuis l'ADR-017 il n'y a plus qu'une règle à tenir, là où il en
--  fallait deux : une voie ne peut pas être déclarée deux fois sur la
--  même période. L'autre — « la même sonde branchée à deux endroits en
--  même temps » — a disparu avec l'objet qu'elle protégeait.
-- =====================================================================

DELIMITER $$

CREATE PROCEDURE assert_point_free(
  IN p_id      INT UNSIGNED,
  IN p_node    INT UNSIGNED,
  IN p_channel VARCHAR(32),
  IN p_from    DATETIME(3),
  IN p_to      DATETIME(3))
BEGIN
  DECLARE v_count INT;

  -- Deux déclarations pour la même voie du même nœud, en même temps.
  SELECT COUNT(*) INTO v_count
    FROM measurement_point mp
   WHERE mp.node_id = p_node
     AND mp.channel = p_channel
     AND (p_id IS NULL OR mp.id <> p_id)
     AND mp.valid_from < COALESCE(p_to, '9999-12-31 00:00:00')
     AND COALESCE(mp.valid_to, '9999-12-31 00:00:00') > p_from;

  IF v_count > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Chevauchement : cette voie est deja declaree sur cette periode';
  END IF;
END$$

CREATE TRIGGER trg_point_bi BEFORE INSERT ON measurement_point
FOR EACH ROW
  CALL assert_point_free(NULL, NEW.node_id, NEW.channel,
                         NEW.valid_from, NEW.valid_to)$$

CREATE TRIGGER trg_point_bu BEFORE UPDATE ON measurement_point
FOR EACH ROW
  CALL assert_point_free(NEW.id, NEW.node_id, NEW.channel,
                         NEW.valid_from, NEW.valid_to)$$

DELIMITER ;

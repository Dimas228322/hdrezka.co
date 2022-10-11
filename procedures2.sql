USE hdrezka;


-- ---------------------------------------------------------
-- ----------------- ADDING A NEW USER ---------------------
-- ---------------------------------------------------------


DROP PROCEDURE IF EXISTS sp_add_user;
DELIMITER //
CREATE PROCEDURE sp_add_user(username VARCHAR(50),
							 email VARCHAR(100),
							 phone_number BIGINT,
							 password_hash VARCHAR(100),
							 OUT u_in_status VARCHAR(200))
BEGIN
	DECLARE _rollback BOOL DEFAULT 0;
	DECLARE code VARCHAR(100);
	DECLARE error_string VARCHAR(100);
	DECLARE last_user_id INT;

	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
		BEGIN
			SET _rollback = 1;
			GET STACKED DIAGNOSTICS CONDITION 1
				code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
			SET u_in_status := concat('Aborted. Error code: ', code, '. Text: ', error_string);
		END;

	START TRANSACTION;
	INSERT INTO users
		(username, email, phone_number, password_hash)
	VALUES
		(username, email, phone_number, password_hash);

	SELECT last_insert_id() INTO @last_user_id;

	INSERT INTO user_profiles
		(user_id)
	VALUES
		(@last_user_id);

	IF _rollback THEN
		ROLLBACK;
	ELSE
		SET u_in_status := 'OK';
		COMMIT;
	END IF;

END //
DELIMITER ;

-- ----------------------------------- CALL PROCEDURE
CALL sp_add_user('mintyneon',
				 'minty@neon.com',
				 '3337711',
				 '28Jtpmzy',
				 @u_in_status);
SELECT @insert_status;



-- ---------------------------------------------------------
-- ----------------- ADDING A NEW TITLE --------------------
-- ---------------------------------------------------------
-- Simply adds an empty row into title_info & titles don't have to be unique


DROP PROCEDURE IF EXISTS sp_add_title;
DELIMITER //
CREATE PROCEDURE sp_add_title(title VARCHAR(100),
							 OUT t_in_status VARCHAR(200))
BEGIN
	DECLARE _rollback BOOL DEFAULT 0;
	DECLARE code VARCHAR(100);
	DECLARE error_string VARCHAR(100);
	DECLARE last_title_id INT;

	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
		BEGIN
			SET _rollback = 1;
			GET STACKED DIAGNOSTICS CONDITION 1
				code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
			SET t_in_status := concat('Aborted. Error code: ', code, '. Text: ', error_string);
		END;

	START TRANSACTION;
	INSERT INTO titles
		(title)
	VALUES
		(title);

	SELECT last_insert_id() INTO @last_title_id;

	INSERT INTO title_info
		(title_id)
	VALUES
		(@last_title_id);

	IF _rollback THEN
		ROLLBACK;
	ELSE
		SET t_in_status := 'OK';
		COMMIT;
	END IF;

END //
DELIMITER ;

-- ----------------------------------- CALL PROCEDURE
CALL sp_add_title('Oh my Venus', @t_in_status);
SELECT @t_in_status;

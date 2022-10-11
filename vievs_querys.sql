USE hdrezka;

-- ----------------------------------- Filmography
DROP PROCEDURE IF EXISTS filmography;
DELIMITER //
CREATE PROCEDURE filmography(IN for_person_id INT)
BEGIN

	SELECT name, title, role, release_date
	  FROM titles_and_cast
	 WHERE cr_id = for_person_id
	 ORDER BY role, release_date DESC;
END//

DELIMITER ;

CALL filmography(3);


-- ----------------------------------- Top 5 titles on keyword
DROP PROCEDURE IF EXISTS top_on_keyword;
DELIMITER //
CREATE PROCEDURE top_on_keyword(IN for_keyword VARCHAR(100))
BEGIN

	SELECT tp.title, tp.rating
	  FROM t_profiles tp
			   JOIN titles_and_keywords tak ON tp.t_id = tak.t_id
	 WHERE tak.keyword = for_keyword
	 ORDER BY
		 tp.rating DESC
	 LIMIT 5;

END //
DELIMITER ;

CALL top_on_keyword('vampire');


-- ----------------------------------- Combination of genre and title type query
DROP PROCEDURE IF EXISTS genre_and_type_combo;
DELIMITER //
CREATE PROCEDURE genre_and_type_combo(IN for_type VARCHAR(100),
									  IN for_genre VARCHAR(100))
BEGIN
	SELECT tp.title, tp.rating
	  FROM t_profiles tp
			   JOIN titles_and_genres tag ON tp.t_id = tag.t_id
	 WHERE tp.title_type = for_type
	   AND tag.relevancy > 0
	   AND tag.genre = for_genre
	 ORDER BY
		 tp.rating DESC, tag.relevancy DESC;
END //
DELIMITER ;

CALL genre_and_type_combo('TV Series', 'Drama');


-- ----------------------------------- All titles somehow related to Korea
DROP PROCEDURE IF EXISTS country_related;
DELIMITER //
CREATE PROCEDURE country_related(IN for_country VARCHAR(100))
BEGIN

	SELECT tp.title, tp.rating
	  FROM t_profiles tp
			   JOIN titles_and_countries tac ON tp.t_id = tac.t_id
	 WHERE tac.country = for_country

	 UNION

	SELECT tp.title, tp.rating
	  FROM t_profiles tp
			   JOIN titles_and_cast tac ON tp.t_id = tac.t_id
			   JOIN cr_profiles crp ON crp.cr_id = tac.cr_id
	 WHERE crp.country = for_country
	 GROUP BY
		 tp.title;

END //
DELIMITER ;

CALL country_related('Korea');


-- ----------------------------------- Some good titles for kids
DROP PROCEDURE IF EXISTS titles_for_kids;
DELIMITER //
CREATE PROCEDURE titles_for_kids(IN how_many INT)
BEGIN

	SELECT title,
		   title_type,
		   rars
	  FROM t_profiles
	 WHERE (rars = '0+' OR rars = '6+') AND rars != 'NR' AND rating >= 6
	 ORDER BY
		 rand()
	 LIMIT how_many;

END //
DELIMITER ;

CALL titles_for_kids(10);

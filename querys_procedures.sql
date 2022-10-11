USE hdrezka;

-- ---------------------------------------------------------
-- ---------------- Titles recommendations -----------------
-- ---------------- for a specific user --------------------


DROP PROCEDURE IF EXISTS offer_titles;
DELIMITER //
CREATE PROCEDURE offer_titles(IN for_user_id INT)
BEGIN

	-- Titles on the lists the user follows
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN user_list_items uli ON uli.title_id = t.id
			   JOIN user_lists ul ON uli.list_id = ul.id
			   JOIN follow_list fl ON fl.list_id = ul.id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE fl.user_id = for_user_id

	 UNION

-- Titles on the lists of users the user follows
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN user_list_items uli ON uli.title_id = t.id
			   JOIN user_lists ul ON ul.id = uli.list_id
			   JOIN follow_user fu ON fu.target_id = ul.user_id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE fu.follower_id = for_user_id

	 UNION

-- Titles that were highly rated by the users the user follows
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN rating r ON r.title_id = t.id
			   JOIN follow_user fu ON fu.target_id = r.user_id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE fu.follower_id = for_user_id
	   AND r.rating > 5

	 UNION

-- Titles that received positive reviews from the users the user follows
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN reviews r ON r.title_id = t.id
			   JOIN follow_user fu ON fu.target_id = r.user_id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE fu.follower_id = for_user_id
	   AND r.is_positive = 1

	 UNION

-- Most relevant titles of the genre the user follows
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN votes_on_genre vog ON vog.title_id = t.id
			   JOIN follow_genre fg ON fg.genre_id = vog.genre_id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE fg.user_id = for_user_id
	   AND g_relevancy(vog.title_id, vog.genre_id) > 0

	 UNION

-- Most relevant titles with the keywords the user follows
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN votes_on_keywords vok ON vok.title_id = t.id
			   JOIN follow_keyword fk ON fk.keyword_id = vok.keyword_id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE fk.user_id = for_user_id
	   AND k_relevancy(vok.title_id, vok.keyword_id) > 0

	 UNION

-- Titles on the user's watchlist that he/she hasn't seen yet
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN watchlist w ON t.id = w.title_id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE w.user_id = for_user_id AND is_seen = 0

	 ORDER BY
		 rand()
	 LIMIT 10;

END //
DELIMITER ;



-- ---------------------------------------------------------
-- ------------ Similar titles on a title page -------------
-- ------------ for any user ------------------------------


DROP PROCEDURE IF EXISTS similar_titles;
DELIMITER //
CREATE PROCEDURE similar_titles(IN for_title_id INT)
BEGIN

	-- Titles of the same genre
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN votes_on_genre vog ON t.id = vog.title_id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE t.id <> for_title_id
	   AND vog.genre_id IN (SELECT genre_id
							  FROM votes_on_genre
							 WHERE title_id = for_title_id
						   )
	   AND g_relevancy(vog.title_id, vog.genre_id) > 0

	 UNION

-- Titles with the same keywords
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN votes_on_keywords vok ON t.id = vok.title_id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE t.id <> for_title_id
	   AND keyword_id IN (SELECT keyword_id
							FROM votes_on_keywords
						   WHERE title_id = for_title_id
						 )
	   AND k_relevancy(vok.title_id, vok.keyword_id) > 0

	 UNION

-- Titles of the same type produced in the same country
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN title_info ti ON ti.title_id = t.id
			   JOIN title_country tc ON tc.title_id = t.id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE t.id <> for_title_id
	   AND ti.title_type_id IN (SELECT title_type_id
								  FROM title_info
								 WHERE title_id = for_title_id
							   )
	   AND tc.country_id IN (SELECT country_id
							   FROM title_country
							  WHERE title_id = for_title_id
							)

	 UNION

-- Titles of the same type directed by the same person
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN title_info ti ON ti.title_id = t.id
			   JOIN cast_and_crew cac ON cac.title_id = t.id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE t.id <> for_title_id
	   AND ti.title_type_id IN (SELECT title_type_id
								  FROM title_info
								 WHERE title_id = for_title_id
							   )
	   AND cac.role_id = 3
	   AND cac.creator_id IN (SELECT creator_id
								FROM cast_and_crew
							   WHERE title_id = for_title_id
							 )

	 UNION

-- Titles of the same type produced by the same companies
	SELECT t.title, rtg.avg_r
	  FROM titles t
			   JOIN title_info ti ON ti.title_id = t.id
			   JOIN title_company tc ON t.id = tc.title_id
			   JOIN (SELECT round(avg(rating)) AS avg_r,
							title_id
					   FROM rating
					  GROUP BY title_id
					) rtg ON rtg.title_id = t.id
	 WHERE t.id <> for_title_id
	   AND ti.title_type_id IN (SELECT title_type_id
								  FROM title_info
								 WHERE title_id = for_title_id
							   )
	   AND tc.company_id IN (SELECT company_id
							   FROM title_company
							  WHERE title_id = for_title_id
							)

	 ORDER BY
		 rand()
	 LIMIT 5;

END //
DELIMITER ;




CALL offer_titles(15);

CALL similar_titles(1);
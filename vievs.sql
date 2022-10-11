USE hdrezka;

-- ---------------------------------------------------------
-- ----------------------- BASIC VIEWS ---------------------
-- ---------------------------------------------------------

-- ----------------------------------- COUNTRIES GENERAL INFO view
CREATE OR REPLACE VIEW countries_info AS
	SELECT c.id as c_id,
		   c.country,
		   tc.c1 AS all_titles,
		   up.c2 AS all_users,
		   cr.c3 AS all_creators
	  FROM countries c
			   LEFT JOIN (SELECT count(title_id) AS c1,
								 country_id
							FROM title_country
						   GROUP BY country_id
						 ) AS tc ON c.id = tc.country_id
			   LEFT JOIN (SELECT count(user_id) AS c2,
								 country_id
							FROM user_profiles
						   GROUP BY country_id
						 ) AS up ON c.id = up.country_id
			   LEFT JOIN (SELECT count(id) AS c3,
								 country_id
							FROM creators
						   GROUP BY country_id
						 ) AS cr ON c.id = cr.country_id
	 GROUP BY
		 c.country
	 ORDER BY
		 c.country;
-- DROP VIEW IF EXISTS countries_info;

-- ----------------------------------- TITLES & COUNTRIES view

CREATE OR REPLACE VIEW titles_and_countries AS
	SELECT t.id AS t_id,
		   t.title,
		   c.id AS c_id,
		   c.country
	  FROM titles t
			   JOIN title_country tc ON t.id = tc.title_id
			   JOIN countries c ON tc.country_id = c.id
	 ORDER BY
		 t.id;


-- ----------------------------------- TITLES & PRODUCTION COMPANIES view
CREATE OR REPLACE VIEW titles_and_companies AS
	SELECT t.id AS t_id,
		   t.title,
		   c.id AS comp_id,
		   c.company
	  FROM titles t
			   JOIN title_company tc ON t.id = tc.title_id
			   JOIN companies c ON tc.company_id = c.id
	 ORDER BY
		 t.id;
-- DROP VIEW IF EXISTS titles_and_companies;


-- ----------------------------------- TITLES & CREATORS view
CREATE OR REPLACE VIEW titles_and_cast AS
	SELECT t.id AS t_id,
		   t.title,
		   r.id AS r_id,
		   r.role,
		   cr.id AS cr_id,
		   concat_ws(' ', cr.first_name, cr.last_name) AS name,
		   ti.release_date
	  FROM creators cr
			   INNER JOIN cast_and_crew cac ON cr.id = cac.creator_id
			   INNER JOIN titles t ON cac.title_id = t.id
			   INNER JOIN roles r ON cac.role_id = r.id
			   INNER JOIN title_info ti ON t.id = ti.title_id
	 ORDER BY
		 t.id;
-- DROP VIEW IF EXISTS titles_and_cast;


-- ---------------------------------------------------------
-- ----------------------- VIEWS WITH VOTES ----------------
-- ---------------------------------------------------------


-- ----------------------------------- GENRES GENERAL INFO view
CREATE OR REPLACE VIEW genres_info AS
	SELECT g.id AS g_id,
		   g.genre,
		   fg.c AS followers,
		   vog.c AS all_titles,
		   vog_r.c AS relevant_titles
	  FROM genres g
			   LEFT JOIN (SELECT count(user_id) AS c,
								 genre_id
							FROM follow_genre
						   GROUP BY genre_id
						 ) AS fg ON g.id = fg.genre_id
			   LEFT JOIN (SELECT count(title_id) AS c, -- All titles
								 genre_id
							FROM votes_on_genre
						   GROUP BY genre_id
						 ) AS vog ON g.id = vog.genre_id
			   LEFT JOIN (SELECT count(title_id) AS c,
								 genre_id
							FROM votes_on_genre
						   WHERE g_relevancy(title_id, genre_id) > 0
						   GROUP BY genre_id
						 ) AS vog_r ON g.id = vog_r.genre_id
	 ORDER BY
		 g.genre;
-- DROP VIEW IF EXISTS genres_info;


-- ----------------------------------- TITLES & THEIR GENRES view
CREATE OR REPLACE VIEW titles_and_genres AS
	SELECT t.id AS t_id,
		   t.title,
		   g.id AS g_id,
		   g.genre,
		   g_relevancy(t.id, g.id) AS relevancy
	  FROM titles t
			   LEFT JOIN votes_on_genre vog ON t.id = vog.title_id
			   LEFT JOIN genres g ON vog.genre_id = g.id
	 GROUP BY
		 t.id, g.genre
	 ORDER BY
		 t.id, relevancy DESC;
-- DROP VIEW IF EXISTS titles_and_genres;


-- ----------------------------------- KEYWORDS GENERAL INFO view
CREATE OR REPLACE VIEW keywords_info AS
	SELECT ak.id AS k_id,
		   ak.keyword,
		   fk.c AS followers,
		   vok.c AS all_titles,
		   vok_r.c AS relevant_titles
	  FROM all_keywords ak
			   LEFT JOIN (SELECT count(user_id) AS c,
								 keyword_id
							FROM follow_keyword
						   GROUP BY keyword_id
						 ) AS fk ON ak.id = fk.keyword_id
			   LEFT JOIN (SELECT count(title_id) AS c, -- All titles
								 keyword_id
							FROM votes_on_keywords
						   GROUP BY keyword_id
						 ) AS vok ON ak.id = vok.keyword_id
			   LEFT JOIN (SELECT count(title_id) AS c, -- Relevant titles
								 keyword_id
							FROM votes_on_keywords
						   WHERE k_relevancy(title_id, keyword_id) > 0
						   GROUP BY keyword_id
						 ) AS vok_r ON ak.id = vok_r.keyword_id
	 ORDER BY
		 ak.id;
-- DROP VIEW IF EXISTS keywords_info;


-- ----------------------------------- TITLES & KEYWORDS view
CREATE OR REPLACE VIEW titles_and_keywords AS
	SELECT t.id AS t_id,
		   t.title,
		   ak.id AS k_id,
		   ak.keyword,
		   k_relevancy(t.id, ak.id) AS relevancy
	  FROM titles t
			   LEFT JOIN votes_on_keywords vok ON t.id = vok.title_id
			   LEFT JOIN all_keywords ak ON vok.keyword_id = ak.id
	 GROUP BY
		 t.id, ak.keyword
	 ORDER BY
		 t.id, relevancy DESC;
-- DROP VIEW IF EXISTS titles_and_genres;


-- ----------------------------------- REVIEWS INFO view
CREATE OR REPLACE VIEW reviews_info AS
	SELECT r.title_id AS t_id,
		   t.title,
		   r.id AS rev_id,
		   r.body,
		   CASE (r.is_positive)
			   WHEN 1 THEN 'positive'
			   WHEN 0 THEN 'negative'
			   END AS mood,
		   review_rate(r.id) AS voted,
		   u.username
	  FROM reviews r
			   JOIN titles t ON r.title_id = t.id
			   JOIN users u ON r.user_id = u.id
	 ORDER BY
		 r.id;
-- DROP VIEW IF EXISTS reviews_info;


-- ---------------------------------------------------------
-- ----------------------- PROFILE VIEWS -------------------
-- ---------------------------------------------------------


-- ----------------------------------- TITLES PROFILES view
CREATE OR REPLACE VIEW t_profiles AS
	SELECT t.id AS t_id,
		   t.title,
		   tt.title_type,
		   r.avgr AS rating,
		   r.count AS r_votes,
		   seen.c AS was_seen,
		   to_w.c AS on_watchlist,
		   uli.c AS on_user_lists,
		   r2.c AS reviewed,
		   ti.release_date,
		   ti.rars,
		   t.original_title,
		   ti.poster,
		   ti.tagline,
		   ti.synopsis
	  FROM titles AS t
			   INNER JOIN title_info ti ON t.id = ti.title_id
			   INNER JOIN title_types tt ON tt.id = ti.title_type_id
			   LEFT JOIN (SELECT title_id,
								 round(avg(rating)) AS avgr,
								 count(rating) AS count
							FROM rating
						   GROUP BY title_id
						 ) AS r ON r.title_id = t.id
			   LEFT JOIN (SELECT count(is_seen) AS c,
								 title_id
							FROM watchlist
						   WHERE is_seen = 1
						   GROUP BY title_id
						 ) seen ON seen.title_id = t.id
			   LEFT JOIN (SELECT count(is_seen) AS c,
								 title_id
							FROM watchlist
						   WHERE is_seen = 0
						   GROUP BY title_id
						 ) to_w ON to_w.title_id = t.id
			   LEFT JOIN (SELECT count(list_id) AS c,
								 title_id
							FROM user_list_items
						   GROUP BY title_id
						 ) uli ON t.id = uli.title_id
			   LEFT JOIN (SELECT count(id) AS c,
								 title_id
							FROM reviews
						   GROUP BY title_id
						 ) r2 ON t.id = r2.title_id
	 ORDER BY
		 t.id;
-- DROP VIEW IF EXISTS t_profiles;


-- ----------------------------------- USERS PROFILES view
CREATE OR REPLACE VIEW u_profiles AS
	SELECT u.id AS u_id,
		   concat_ws(' ', up.first_name, up.last_name) AS name,
		   u.username,
		   u.phone_number,
		   u.email,
		   up.date_of_birth,
		   TIMESTAMPDIFF(YEAR, up.date_of_birth, NOW()) AS age,
		   CASE (up.gender)
			   WHEN 'm' THEN 'male'
			   WHEN 'f' THEN 'female'
			   WHEN 'nb' THEN 'non-binary'
			   WHEN 'ud' THEN 'undefined'
			   END AS gender,
		   CASE (up.is_private)
			   WHEN 1 THEN 'private'
			   WHEN 0 THEN 'public'
			   END AS account,
		   fu_t.c AS followers,
		   fu_f.c AS following,
		   to_w.c AS to_watch,
		   seen.c AS titles_seen,
		   ul.lists,
		   r.c AS reviews,
		   r2.c AS rated_titles,
		   r2.avg_rating,
		   c.country,
		   up.avatar,
		   up.about
	  FROM users u
			   LEFT JOIN user_profiles up ON u.id = up.user_id
			   LEFT JOIN countries c ON up.country_id = c.id
			   LEFT JOIN (SELECT count((id)) AS c, -- Number of followers
								 target_id
							FROM follow_user
						   GROUP BY target_id
						 ) fu_t ON u.id = fu_t.target_id
			   LEFT JOIN (SELECT count((id)) AS c, -- Number of users, he/she is following
								 follower_id
							FROM follow_user
						   GROUP BY follower_id
						 ) fu_f ON u.id = fu_f.follower_id
			   LEFT JOIN (SELECT user_id,
								 count(title_id) AS c
							FROM watchlist
						   WHERE is_seen = 0
						   GROUP BY user_id
						 ) to_w ON u.id = to_w.user_id
			   LEFT JOIN (SELECT user_id,
								 count(title_id) AS c
							FROM watchlist
						   WHERE is_seen = 1
						   GROUP BY user_id
						 ) seen ON u.id = seen.user_id
			   LEFT JOIN (SELECT count(list_name) AS lists,
								 user_id
							FROM user_lists
						   GROUP BY user_id
						 ) ul ON u.id = ul.user_id
			   LEFT JOIN (SELECT count(id) AS c,
								 user_id
							FROM reviews
						   GROUP BY user_id
						 ) r ON u.id = r.user_id
			   LEFT JOIN (SELECT count(id) AS c,
								 round(avg(rating)) AS avg_rating,
								 user_id
							FROM rating
						   GROUP BY user_id
						 ) r2 ON u.id = r2.user_id
	 ORDER BY
		 u.id;
-- DROP VIEW IF EXISTS u_profiles;


-- ----------------------------------- CREATORS PROFILES view
CREATE OR REPLACE VIEW cr_profiles AS
	SELECT cr.id AS cr_id,
		   concat_ws(' ', cr.first_name, cr.last_name) AS name,
		   TIMESTAMPDIFF(YEAR, cr.date_of_birth, NOW()) AS age,
		   CASE (cr.gender)
			   WHEN 'm' THEN 'male'
			   WHEN 'f' THEN 'female'
			   WHEN 'nb' THEN 'non-binary'
			   WHEN 'ud' THEN 'undefined'
			   END AS gender,
		   cac.c AS filmography,
		   cr_r.role,
		   cr_r.r_count,
		   cr.date_of_birth,
	       cn.id AS c_id,
		   cn.country
	  FROM creators cr
			   JOIN countries cn ON cr.country_id = cn.id
			   LEFT JOIN (SELECT creator_id,
								 title_id,
								 count(title_id) AS c
							FROM cast_and_crew
						   GROUP BY creator_id
						 ) cac ON cac.creator_id = cr.id
			   LEFT JOIN (SELECT creator_id,
								 role_id,
								 r.role AS role,
								 count(role_id) AS r_count
							FROM cast_and_crew
									 JOIN roles r ON cast_and_crew.role_id = r.id
						   GROUP BY creator_id, role_id
						   ORDER BY creator_id, r_count DESC
						 ) AS cr_r ON cr_r.creator_id = cr.id
	 ORDER BY
		 cr.id;
-- DROP VIEW IF EXISTS cr_profiles;
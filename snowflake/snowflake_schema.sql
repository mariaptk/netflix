-- Сreating tables
create or replace TABLE NETFLIX.PUBLIC.ADDED_INFO (
	SHOW_ID VARCHAR(16777216),
	DATE_ADDED DATE,
	YEAR_ADDED NUMBER(38,0),
	MONTH_ADDED NUMBER(38,0),
	primary key (SHOW_ID)
);

create or replace TABLE NETFLIX.PUBLIC.COUNTRIES (
	COUNTRY VARCHAR(16777216),
	COUNTRY_ID VARCHAR(16777216),
	primary key (COUNTRY_ID)
);

create or replace TABLE NETFLIX.PUBLIC.DIRECTORS (
	DIRECTOR VARCHAR(16777216),
	DIRECTOR_ID VARCHAR(16777216),
	primary key (DIRECTOR_ID)
);

create or replace TABLE NETFLIX.PUBLIC.FULLINFO (
	SHOW_ID VARCHAR(16777216),
	COUNTRY VARCHAR(16777216),
	DIRECTOR VARCHAR(16777216),
	GENRE VARCHAR(16777216)
);

create or replace TABLE NETFLIX.PUBLIC.GENRES (
	GENRE VARCHAR(16777216),
	GENRE_ID VARCHAR(16777216),
	primary key (GENRE_ID)
);

create or replace TABLE NETFLIX.PUBLIC.TITLE (
	SHOW_ID VARCHAR(16777216),
	TITLE VARCHAR(16777216),
	CAST VARCHAR(16777216),
	RELEASE_YEAR NUMBER(38,0),
	RATING VARCHAR(16777216),
	DURATION NUMBER(38,0),
	DESCRIPTION VARCHAR(16777216),
	TYPE_S VARCHAR(16777216),
	primary key (SHOW_ID)
);

--Creating VIEWS
create or replace TABLE NETFLIX.PUBLIC.TITLE_COUNTRY (
	SHOW_ID VARCHAR(16777216) NOT NULL,
	COUNTRY_ID VARCHAR(16777216) NOT NULL,
	primary key (SHOW_ID, COUNTRY_ID),
	foreign key (SHOW_ID) references NETFLIX.PUBLIC.TITLE(SHOW_ID),
	foreign key (COUNTRY_ID) references NETFLIX.PUBLIC.COUNTRIES(COUNTRY_ID)
);

create or replace TABLE NETFLIX.PUBLIC.TITLE_DIRECTOR (
	SHOW_ID VARCHAR(16777216) NOT NULL,
	DIRECTOR_ID VARCHAR(16777216) NOT NULL,
	primary key (SHOW_ID, DIRECTOR_ID),
	foreign key (SHOW_ID) references NETFLIX.PUBLIC.TITLE(SHOW_ID),
	foreign key (DIRECTOR_ID) references NETFLIX.PUBLIC.DIRECTORS(DIRECTOR_ID)
);

create or replace TABLE NETFLIX.PUBLIC.TITLE_GENRE (
	SHOW_ID VARCHAR(16777216) NOT NULL,
	GENRE_ID VARCHAR(16777216) NOT NULL,
	primary key (SHOW_ID, GENRE_ID),
	foreign key (SHOW_ID) references NETFLIX.PUBLIC.TITLE(SHOW_ID),
	foreign key (GENRE_ID) references NETFLIX.PUBLIC.GENRES(GENRE_ID)
);

create or replace view NETFLIX.PUBLIC.NETFLIX_CONTENT_CLASSIFICATION(
	SHOW_ID,
	TITLE,
	TYPE_S,
	RELEASE_YEAR,
	CONTENT_CATEGORY,
	YEARS_BETWEEN_RELEASE_AND_ADD,
	GENRE,
	COUNTRY
) as
SELECT
    DISTINCT t.show_id,
    t.title,
    t.type_s,
    t.release_year,
    CASE
        WHEN t.release_year = 2021 THEN 'Оригинальный контент'
        WHEN t.release_year < 2021 THEN 'Приобретенный контент'
        ELSE 'Аномалия (дата добавления раньше выпуска)'
    END AS content_category,
    2021 - t.release_year AS years_between_release_and_add,
    g.genre,
    c.country
FROM title t
JOIN added_info a ON t.show_id = a.show_id
LEFT JOIN title_genre tg ON t.show_id = tg.show_id
LEFT JOIN genres g ON tg.genre_id = g.genre_id
LEFT JOIN title_country tc ON t.show_id = tc.show_id
LEFT JOIN countries c ON tc.country_id = c.country_id
WHERE a.date_added IS NOT NULL
GROUP BY t.show_id, t.title, t.type_s, t.release_year, a.date_added, g.genre, c.country;

create or replace view NETFLIX.PUBLIC.NETFLIX_ORIGINAL_VS_ARCHIVE(
	SHOW_ID,
	TITLE,
	TYPE_S,
	RELEASE_YEAR,
	MONTH_ADDED,
	CONTENT_TYPE,
	YEAR_GAP
) as
SELECT
    t.show_id,
    t.title,
    t.type_s,
    t.release_year,
    a.month_added,
    CASE
        WHEN t.release_year = EXTRACT(YEAR FROM a.date_added) THEN 'Оригинальный'
        ELSE 'Архивный'
    END AS content_type,
    EXTRACT(YEAR FROM a.date_added) - t.release_year AS year_gap
FROM title t
JOIN added_info a ON t.show_id = a.show_id
WHERE a.date_added IS NOT NULL;

create or replace view NETFLIX.PUBLIC.V_CONTENT_FRESHNESS(
	CONTENT_TYPE,
	FRESHNESS_CATEGORY,
	COUNT,
	PERCENTAGE
) as
SELECT
    t.type_s AS content_type,
    CASE
        WHEN t.release_year = a.year_added THEN 'Добавлен в год выхода'
        WHEN t.release_year < a.year_added THEN 'Добавлен после выхода'
        ELSE 'Ошибка дат'  -- На случай аномалий (release_year > year_added)
    END AS freshness_category,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY t.type_s), 2) AS percentage
FROM
    TITLE t
JOIN
    ADDED_INFO a ON t.show_id = a.show_id
WHERE
    a.year_added = 2021  -- Фильтрация по году добавления
GROUP BY
    t.type_s, freshness_category
ORDER BY
    t.type_s, count DESC;

create or replace view NETFLIX.PUBLIC.V_DIRECTORS_20211(
	DIRECTOR,
	WORKS_COUNT
) as
WITH director_works AS (
    SELECT
        d.director,
        COUNT(DISTINCT t.show_id) AS works_count
    FROM
        TITLE_DIRECTOR td
    JOIN
        DIRECTORS d ON td.director_id = d.director_id
    JOIN
        TITLE t ON td.show_id = t.show_id
    JOIN
        ADDED_INFO a ON t.show_id = a.show_id
    WHERE
        a.year_added = 2021
    GROUP BY
        d.director
),
director_genres AS (
    SELECT
        d.director
    FROM
        TITLE_DIRECTOR td
    JOIN
        DIRECTORS d ON td.director_id = d.director_id
    JOIN
        TITLE_GENRE tg ON td.show_id = tg.show_id
    JOIN
        GENRES g ON tg.genre_id = g.genre_id
    JOIN
        ADDED_INFO a ON td.show_id = a.show_id
    GROUP BY
        d.director
)
SELECT
    dw.director,
    dw.works_count
FROM
    director_works dw
JOIN
    director_genres dg ON dw.director = dg.director
ORDER BY
    dw.works_count DESC;

create or replace view NETFLIX.PUBLIC.V_MONTHLY_TRENDS_2021(
	CONTENT_TYPE,
	MONTH_ADDED,
	COUNT
) as
SELECT
    t.type_s AS content_type,
    a.month_added,
    COUNT(*) AS count
FROM
    TITLE t
JOIN
    ADDED_INFO a ON t.show_id = a.show_id
WHERE
    a.year_added = 2021
GROUP BY
    t.type_s, a.month_added
ORDER BY
    a.month_added;

create or replace view NETFLIX.PUBLIC.V_TOP_COUNTRIES(
	COUNTRY,
	PRODUCTION_COUNT
) as
SELECT
    c.country,
    COUNT(DISTINCT tc.show_id) AS production_count
FROM
    COUNTRIES c
JOIN
    TITLE_COUNTRY tc ON c.country_id = tc.country_id
LEFT JOIN
    TITLE_GENRE tg ON tc.show_id = tg.show_id
LEFT JOIN
    GENRES g ON tg.genre_id = g.genre_id
GROUP BY
    c.country
ORDER BY
    production_count DESC
LIMIT 15;

create or replace view NETFLIX.PUBLIC.V_TOP_GENRES(
	GENRE,
	CONTENT_COUNT,
	PERCENTAGE
) as
SELECT
    g.genre,
    COUNT(DISTINCT tg.show_id) AS content_count,
    ROUND(COUNT(DISTINCT tg.show_id) * 100.0 /
          (SELECT COUNT(DISTINCT show_id) FROM TITLE_GENRE), 2) AS percentage
FROM
    GENRES g
JOIN
    TITLE_GENRE tg ON g.genre_id = tg.genre_id
GROUP BY
    g.genre
ORDER BY
    content_count DESC
LIMIT 10;


CREATE OR REPLACE VIEW netflix_original_vs_archive AS
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

Select * from netflix_original_vs_archive;

DROP VIEW netflix_yearly_addition_stats;
-- Статистика по годам добавления
CREATE OR REPLACE VIEW netflix_yearly_addition_stats AS
SELECT
    EXTRACT(YEAR FROM date_added) AS addition_year,
    type_s,
    COUNT(*) AS total_added,
    SUM(CASE WHEN release_year = EXTRACT(YEAR FROM date_added) THEN 1 ELSE 0 END) AS original_content,
    SUM(CASE WHEN release_year < EXTRACT(YEAR FROM date_added) THEN 1 ELSE 0 END) AS archive_content,
    ROUND(AVG(EXTRACT(YEAR FROM date_added) - release_year), 1) AS avg_years_difference,
    ROUND(original_content * 100.0 / total_added, 1) AS original_percentage,
    ROUND(archive_content * 100.0 / total_added, 1) AS archive_percentage
FROM title t
JOIN added_info a ON t.show_id = a.show_id
WHERE date_added IS NOT NULL
  AND EXTRACT(YEAR FROM date_added) BETWEEN 2016 AND 2021
GROUP BY addition_year, type_s
ORDER BY addition_year DESC, type_s;

select * from netflix_yearly_addition_stats;

-- Соотношение оригинального контента и приобретенного
CREATE OR REPLACE VIEW netflix_content_classification AS
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

select * from netflix_content_classification;

CREATE OR REPLACE VIEW V_DIRECTORS_20211 AS
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
    HAVING
        COUNT(DISTINCT t.show_id) >= 2  -- Режиссеры с 2+ работами
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

select *from V_DIRECTORS_20211;

-- динамика выпусков фильмов и сериалов по месяцам
CREATE OR REPLACE VIEW V_MONTHLY_TRENDS_2021 AS
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

select * from V_MONTHLY_TRENDS_2021;

-- сравнение фильмов оригинальных от нетфликс и те, которые были сняты другими компаниями
CREATE OR REPLACE VIEW V_CONTENT_FRESHNESS AS
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

select * from V_CONTENT_FRESHNESS;

-- топ популярных жарнов
CREATE OR REPLACE VIEW V_TOP_GENRES AS
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


select * from V_TOP_GENRES;



--топ стран по произовдству контента
CREATE OR REPLACE VIEW V_TOP_COUNTRIES AS
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

select * from V_TOP_COUNTRIES;

DROP VIEW V_DIRECTOR_GENRE_DIVERSITY;
CREATE OR REPLACE VIEW V_DIRECTOR_GENRE_DIVERSITY AS
SELECT
    d.director,
    COUNT(DISTINCT g.genre) AS unique_genres
FROM
    DIRECTORS d
JOIN
    TITLE_DIRECTOR td ON d.director_id = td.director_id
JOIN
    TITLE_GENRE tg ON td.show_id = tg.show_id
JOIN
    GENRES g ON tg.genre_id = g.genre_id
GROUP BY
    d.director
HAVING
    COUNT(DISTINCT g.genre) >= 3
ORDER BY
    unique_genres DESC;

select * from V_DIRECTOR_GENRE_DIVERSITY;



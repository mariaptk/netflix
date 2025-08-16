## Project Description

This project demonstrate core Data Analyst skills using Python (Pandas), Snowflake, and Power BI. It is based on the Netflix Movies and TV Shows dataset (as of late 2021), which includes over 8,000 records with attributes such as title, type, cast, country, genre, rating, release year, and the date content was added to the platform.

The goal is to design a clean and normalized data model, load it into Snowflake, and build analytical views for further visual exploration in Power BI.

## Project Structure
```text
netflix2_0/
│
├── data/                   # Data directories
│   ├── processed/          # Cleaned and transformed data
│   └── raw/                # Original raw data files
│
├── models/                 # Machine learning models (if applicable)
│
├── powerBI/                # Power BI assets
│   ├── netflix_model.pbix  # Main Power BI report file
│   └── netflix_model.pdf   # Exported PDF version
│
├── cleaning.ipynb      # Data cleaning notebook
│
├── snowflake/              # Snowflake database scripts
│   ├── data_load/          # Data loading scripts
│   ├── snowflake_schema.sql # Database schema definition
│   └── views.sql           # Analytical views definitions
│
├── LICENSE                 # Project license
├── README.md               # Project documentation
└── requirements.txt        # Python dependencies

## Data Model in Snowflake

- `title_df`: main table with title-level information (title, type, cast, release year, rating)
- `genres`: list of unique genres
- `country`: list of countries
- `directors`: list of directors
- `added_info`: date and month when a show/movie was added to the platform
- `title_genre`, `title_country`, `title_director`: many-to-many relationship tables

A view `full_title_info` was created to consolidate the necessary fields (title, type, genres, countries, director, release year, rating, and added date) into a single representation for analysis.

## Visualizations and Analysis (Power BI)

The processed view from Snowflake was used to build various visualizations in Power BI, including:

- Distribution of Movies vs. TV Shows
- Content release trends by year
- Monthly addition patterns
- Top content-producing countries
- Most common genres
- Most prolific directors
- Freshness of content (added in the same year vs. delayed addition)

Visual insights are exported as a report in `powerBI/netflix_model.pdf`.

## Key Insights

- The majority of Netflix content originates from the United States, India, Japan, and the United Kingdom.
- The most common genres are dramas, international movies, comedies, and action & adventure.
- A significant portion of content is added to the platform more than a year after its release.
- TV Shows represent approximately 36% of all titles in the catalog.
- Several directors have contributed three or more projects to Netflix.

## Technologies Used

- Python (Pandas, Matplotlib, Seaborn)
- Snowflake (schema modeling, SQL views, data loading)
- Power BI (interactive dashboards and reports)

## Project Objective

This project demonstrates the ability to:

- Clean and normalize complex datasets
- Model and manage data in a cloud-based DWH (Snowflake)
- Create reusable analytical views for reporting
- Derive insights using visual analytics



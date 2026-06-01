# Football SQL Power BI Analytics

## Project Overview

This project analyzes real football match data using MySQL, SQL analytics, and Power BI.

The data is loaded from Football-Data.co.uk and transformed into a clean star-schema model. The project demonstrates SQL skills including CTEs, window functions, views, stored procedures, triggers, and Power BI dashboarding.

## Tech Stack

- MySQL
- MySQL Workbench
- Python
- Pandas
- SQLAlchemy
- Power BI
- GitHub

## Data Source

Football match data is taken from Football-Data.co.uk.

Initial dataset includes Big 5 European leagues for the 2023/24 season:

- English Premier League
- La Liga
- Serie A
- Bundesliga
- Ligue 1

## Data Architecture

```text
CSV Source Files / URLs
        ↓
football_matches_raw
        ↓
dim_league
dim_season
dim_date
dim_team
        ↓
fact_matches_clean
        ↓
SQL Views
        ↓
Power BI Dashboard

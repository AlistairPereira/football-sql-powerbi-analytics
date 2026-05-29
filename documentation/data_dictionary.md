# Data Dictionary

This document explains the column mapping planned for the football analytics project.

## Data Source

Football-Data.co.uk EPL 2023/24 CSV.

## Column Mapping

The source CSV uses short football-data column names. During the Python data loading step, these columns will be renamed into cleaner database column names before loading into MySQL.

| Source CSV Column | Target MySQL Column | Meaning |
|---|---|---|
| Date | match_date | Date when the match was played |
| Time | match_time | Match kickoff time |
| HomeTeam | home_team | Team playing at home |
| AwayTeam | away_team | Team playing away |
| FTHG | home_goals | Full-time home team goals |
| FTAG | away_goals | Full-time away team goals |
| FTR | result | Full-time result. H = Home win, A = Away win, D = Draw |
| HTHG | half_time_home_goals | Half-time home team goals |
| HTAG | half_time_away_goals | Half-time away team goals |
| HTR | half_time_result | Half-time result. H = Home lead, A = Away lead, D = Draw |
| Referee | referee | Match referee |
| HS | home_shots | Total shots by home team |
| AS | away_shots | Total shots by away team |
| HST | home_shots_target | Home shots on target |
| AST | away_shots_target | Away shots on target |
| HC | home_corners | Home team corners |
| AC | away_corners | Away team corners |
| HY | home_yellow_cards | Home team yellow cards |
| AY | away_yellow_cards | Away team yellow cards |
| HR | home_red_cards | Home team red cards |
| AR | away_red_cards | Away team red cards |

## Additional Columns Added During Loading

| Column | Meaning |
|---|---|
| league_code | Short league code, for example E0 for English Premier League |
| league_name | Full league name |
| season | Football season, for example 2023/24 |
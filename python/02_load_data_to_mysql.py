import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

# Load values from .env file
load_dotenv()

MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")
MYSQL_HOST = os.getenv("MYSQL_HOST")
MYSQL_PORT = os.getenv("MYSQL_PORT")
MYSQL_DB = os.getenv("MYSQL_DB")

# MySQL connection
engine = create_engine(
    f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"
)

# Big 5 European leagues - 2023/24 season
files = [
    {
        "url": "https://www.football-data.co.uk/mmz4281/2324/E0.csv",
        "league_code": "E0",
        "league_name": "English Premier League",
        "season": "2023/24"
    },
    {
        "url": "https://www.football-data.co.uk/mmz4281/2324/SP1.csv",
        "league_code": "SP1",
        "league_name": "La Liga",
        "season": "2023/24"
    },
    {
        "url": "https://www.football-data.co.uk/mmz4281/2324/I1.csv",
        "league_code": "I1",
        "league_name": "Serie A",
        "season": "2023/24"
    },
    {
        "url": "https://www.football-data.co.uk/mmz4281/2324/D1.csv",
        "league_code": "D1",
        "league_name": "Bundesliga",
        "season": "2023/24"
    },
    {
        "url": "https://www.football-data.co.uk/mmz4281/2324/F1.csv",
        "league_code": "F1",
        "league_name": "Ligue 1",
        "season": "2023/24"
    }
]

# Rename CSV columns to clean MySQL column names
rename_map = {
    "Date": "match_date",
    "Time": "match_time",
    "HomeTeam": "home_team",
    "AwayTeam": "away_team",
    "FTHG": "home_goals",
    "FTAG": "away_goals",
    "FTR": "result",
    "HTHG": "half_time_home_goals",
    "HTAG": "half_time_away_goals",
    "HTR": "half_time_result",
    "Referee": "referee",
    "HS": "home_shots",
    "AS": "away_shots",
    "HST": "home_shots_target",
    "AST": "away_shots_target",
    "HC": "home_corners",
    "AC": "away_corners",
    "HY": "home_yellow_cards",
    "AY": "away_yellow_cards",
    "HR": "home_red_cards",
    "AR": "away_red_cards"
}

needed_cols = list(rename_map.keys())

number_cols = [
    "home_goals",
    "away_goals",
    "half_time_home_goals",
    "half_time_away_goals",
    "home_shots",
    "away_shots",
    "home_shots_target",
    "away_shots_target",
    "home_corners",
    "away_corners",
    "home_yellow_cards",
    "away_yellow_cards",
    "home_red_cards",
    "away_red_cards"
]

all_data = []

for file in files:
    print(f"\nReading data for {file['league_name']}...")

    df = pd.read_csv(file["url"])

    # Keep only columns that exist in this CSV
    available_cols = [col for col in needed_cols if col in df.columns]

    df = df[available_cols].copy()
    df = df.rename(columns=rename_map)

    # Add project columns
    df["league_code"] = file["league_code"]
    df["league_name"] = file["league_name"]
    df["season"] = file["season"]

    # Convert date
    df["match_date"] = pd.to_datetime(
        df["match_date"],
        dayfirst=True,
        errors="coerce"
    ).dt.date

    # Convert numeric columns
    for col in number_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    # Remove bad/empty rows
    df = df.dropna(subset=["match_date", "home_team", "away_team"])

    print(f"{file['league_name']} rows loaded: {len(df)}")

    all_data.append(df)

# Combine all leagues
final_df = pd.concat(all_data, ignore_index=True)

print("\nFinal combined data preview:")
print(final_df.head())

print("\nTotal rows to load:", len(final_df))

print("\nRows by league:")
print(final_df.groupby(["league_name", "season"]).size())

# Load into MySQL
final_df.to_sql(
    "football_matches_raw",
    con=engine,
    if_exists="replace",
    index=False
)

print("\nAll Big 5 league data loaded into MySQL table: football_matches_raw")
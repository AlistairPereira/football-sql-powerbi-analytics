import pandas as pd

url = "https://www.football-data.co.uk/mmz4281/2324/E0.csv"

df = pd.read_csv(url)

print("Shape:")
print(df.shape)

print("\nColumns:")
print(list(df.columns))

print("\nFirst 5 rows:")
print(df.head())

important_cols = [
    "Date",
    "Time",
    "HomeTeam",
    "AwayTeam",
    "FTHG",
    "FTAG",
    "FTR",
    "HTHG",
    "HTAG",
    "HTR",
    "Referee",
    "HS",
    "AS",
    "HST",
    "AST",
    "HC",
    "AC",
    "HY",
    "AY",
    "HR",
    "AR"
]

existing_cols = [col for col in important_cols if col in df.columns]

print("\nImportant columns available:")
print(existing_cols)

print("\nNull count in important columns:")
print(df[existing_cols].isnull().sum())

print("\nSample selected columns:")
print(df[existing_cols].head())

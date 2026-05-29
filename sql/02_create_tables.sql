# creating dimension tables

#----------------------create dim_league----------------------
 
 create table dim_league
 (
 league_id int auto_increment primary key,
 league_code varchar(10) not null unique,
 leagye_name varchar(100) not null
 );
 
 #----------------------create dim_season----------------------

 create table dim_season
 (
 season_id int auto_increment primary key,
 season varchar(20) not null unique
 );

#----------------------create fact_matchese----------------------

 CREATE TABLE fact_matches (
    match_id INT AUTO_INCREMENT PRIMARY KEY,
    league_id INT,
    season_id INT,
    match_date DATE,
    match_time TIME,
    home_team VARCHAR(100),
    away_team VARCHAR(100),
    home_goals INT,
    away_goals INT,
    result CHAR(1),
    half_time_home_goals INT,
    half_time_away_goals INT,
    half_time_result CHAR(1),
    referee VARCHAR(100),
    home_shots INT,
    away_shots INT,
    home_shots_target INT,
    away_shots_target INT,
    home_corners INT,
    away_corners INT,
    home_yellow_cards INT,
    away_yellow_cards INT,
    home_red_cards INT,
    away_red_cards INT,
    foreign key (league_id) references dim_league(league_id),
    foreign key (season_id) references dim_season(season_id)
);

#----------------------insert dim_league----------------------


insert into dim_league (league_code, league_name)
select distinct league_code, league_name
from football_matches_raw;

select * from dim_league;

insert into dim_season(season)
select distinct season
from football_matches_raw;

#----------------------insert dim_season----------------------


select * from dim_season;

insert into fact_matches (league_id,season_id,match_date,match_time,home_team,away_team,home_goals,away_goals,result,half_time_home_goals,
    half_time_away_goals,half_time_result,referee,home_shots,away_shots,home_shots_target,away_shots_target,home_corners,away_corners,
    home_yellow_cards,away_yellow_cards,home_red_cards,away_red_cards
)
select dl.league_id,ds.season_id,r.match_date,r.match_time,r.home_team,r.away_team,r.home_goals,r.away_goals,r.result,r.half_time_home_goals,
r.half_time_away_goals,r.half_time_result,r.referee,r.home_shots,r.away_shots,r.home_shots_target,r.away_shots_target,
r.home_corners,r.away_corners,r.home_yellow_cards,r.away_yellow_cards,r.home_red_cards,r.away_red_cards from football_matches_raw as r
join dim_league as dl on r.league_code = dl.league_code
join dim_season as ds on r.season = ds.season;

select * from fact_matches where league_id = 1;
select * from fact_matches where season_id = 1;
select * from dim_season;

select dl.league_id, dl.league_name, ds.season, count(*) as total_matches
 from fact_matches as fm
join dim_league as dl on fm.league_id = dl.league_id
join dim_season as ds on fm.season_id = ds.season_id
group by fm.league_id, fm.season_id;

#----------------------create dim_date----------------------


create table dim_date
(
date_id int auto_increment primary key,
full_date date not null unique,
year_num int,
month_num int,
month_name varchar(50),
day_num int,
day_name varchar(50)
);

#----------------------insert dim_date----------------------


insert into dim_date(full_date,year_num,month_num,month_name,day_num,day_name)
select distinct
match_date as full_date,
year(match_date) as year_num,
month(match_date) as month_num,
monthname(match_date) as month_name,
day(match_date) as day_num,
dayname(match_date) as day_name
 from football_matches_raw
 where match_date is not null;
 
 select * from dim_date;


 #----------------------create dim_date----------------------


 create table dim_team
 (
 team_id int auto_increment primary key,
 team_name varchar(100) not null,
 league_code varchar(20) not null,
 league_name varchar(100) not null,
--  composite unique constraint
 unique(team_name, league_code)   
 );

 #----------------------insert dim_date----------------------


 insert into dim_team(team_name, league_code,league_name)
select distinct home_team as team_name,
league_code, league_name
from football_matches_raw
where home_team is not null
union
select distinct away_team as team_name,
league_code, league_name
from football_matches_raw
where away_team is not null;

select * from dim_team;

#----------------------create fact_matches_clean----------------------


create table fact_matches_clean (
    match_id INT AUTO_INCREMENT PRIMARY KEY,league_id INT,season_id INT,date_id INT,home_team_id INT,away_team_id INT,
match_time TIME,home_goals INT,away_goals INT,result CHAR(1),half_time_home_goals INT,half_time_away_goals INT,half_time_result CHAR(1),
referee VARCHAR(100),home_shots INT,away_shots INT,home_shots_target INT,away_shots_target INT,home_corners INT,away_corners INT,
home_yellow_cards INT,away_yellow_cards INT,home_red_cards INT,away_red_cards INT,
foreign key(league_id) references dim_league(league_id),
foreign key(season_id) references dim_season(season_id),
foreign key(date_id) references dim_date(date_id),
foreign key(home_team_id) references dim_team(team_id),
foreign key(away_team_id) references dim_team(team_id)
);

#----------------------insert fcat_matches_clean----------------------

insert into fact_matches_clean (league_id,season_id,date_id,home_team_id,away_team_id,match_time,home_goals,away_goals,result,
    half_time_home_goals,half_time_away_goals,half_time_result,referee,home_shots,away_shots,home_shots_target,away_shots_target,
    home_corners,away_corners,home_yellow_cards,away_yellow_cards,home_red_cards,away_red_cards
)
select dl.league_id,ds.season_id,dd.date_id,hteam.team_id AS home_team_id,ateam.team_id AS away_team_id,
r.match_time,r.home_goals,r.away_goals,r.result,
r.half_time_home_goals,r.half_time_away_goals,r.half_time_result,
r.referee,
r.home_shots,r.away_shots,r.home_shots_target,r.away_shots_target,
r.home_corners,r.away_corners,
r.home_yellow_cards,r.away_yellow_cards,
r.home_red_cards,r.away_red_cards 
from football_matches_raw as r
join dim_league as dl on r.league_code = dl.league_code
join dim_season as ds on r.season = ds.season
join dim_date as dd on r.match_date = dd.full_date
join dim_team as hteam on r.home_team = hteam.team_name and r.league_code = hteam.league_code
join dim_team as ateam on r.away_team = ateam.team_name and r.league_code = ateam.league_code;



create view vw_league_points_table as
with team_match_rows as (
select dl.league_name,
ds.season, 
ht.team_name as team_name,
fm.home_goals as goals_for,
fm.away_goals as goals_against,
fm.result,

case when fm.result = "H" then 1 else 0 end as won,
case when fm.result = "A" then 1 else 0 end as lost,
case when fm.result = "D" then 1 else 0 end as drawn,
case when fm.result = "H" then 3
	when fm.result = "A" then 0
    else 1
    end as points
 from fact_matches_clean as fm
join dim_league as dl on fm.league_id = dl.league_id
join dim_season as ds on fm.season_id = ds.season_id
join dim_team as ht on fm.home_team_id = ht.team_id

union all

select dl.league_name,
ds.season, 
at.team_name as team_name,
fm.away_goals as goals_for,
fm.home_goals as goals_against,
fm.result,

case when fm.result = "A" then 1 else 0 end as won,
case when fm.result = "H" then 1 else 0 end as lost,
case when fm.result = "D" then 1 else 0 end as drawn,
case when fm.result = "A" then 3
	when fm.result = "H" then 0
    else 1
    end as points
 from fact_matches_clean as fm
join dim_league as dl on fm.league_id = dl.league_id
join dim_season as ds on fm.season_id = ds.season_id
join dim_team as at on fm.away_team_id = at.team_id),
team_summary as
(
select league_name,season,team_name, 
count(*) as played,
sum(won) as won,
sum(drawn) as drawn,
sum(lost) as lost,
sum(goals_for)  as goals_for,
sum(goals_against) as goals_against,
sum(goals_for) - sum(goals_against) as goal_difference,
sum(points) as points
 from team_match_rows
group by league_name, season, team_name
)
select *,
dense_rank() over (partition by league_name, season 
order by points desc, goal_difference desc, goals_for desc) as league_position
 from team_summary;
 
 select * from vw_league_points_table;

  #----------------------------------------view for weekly goals data----------------------------------------------------------------
 select * from dim_date;
 create view  vw_team_goals_by_month_week as 
 with season_start as 
 (
	 select fm.league_id,
			fm.season_id,
			min(dd.full_date) AS season_start_date
			from fact_matches_clean as fm
	 join dim_date as dd on fm.date_id = dd.date_id
	 group by fm.league_id, fm.season_id
	 ),
     team_match_rows as (
	 select dl.league_name, ds.season,
	 dd.full_date ,dd.year_num,dd.month_num, dd.month_name,
	floor(datediff(dd.full_date, ss.season_start_date) / 7) + 1 as season_week,
	 ht.team_name,
	 fm.home_goals as goals_for,
	 fm.away_goals as goals_against ,
	 fm.home_goals - fm.away_goals as goal_difference
	 from fact_matches_clean as fm
	 join dim_league as dl on fm.league_id = dl.league_id
	 join dim_season as ds on ds.season_id = fm.season_id
	 join dim_date as dd on fm.date_id = dd.date_id
	 join dim_team as ht on fm.home_team_id = ht.team_id
	 join season_start as ss on  fm.league_id = ss.league_id and fm.season_id = ss.season_id
     union all
     select dl.league_name, ds.season,
	 dd.full_date ,dd.year_num,dd.month_num, dd.month_name,
	floor(datediff(dd.full_date, ss.season_start_date) / 7) + 1 as season_week,
	 at.team_name,
	 fm.away_goals as goals_for,
	 fm.home_goals as goals_against ,
	fm.away_goals - fm.home_goals  as goal_difference
	 from fact_matches_clean as fm
	 join dim_league as dl on fm.league_id = dl.league_id
	 join dim_season as ds on ds.season_id = fm.season_id
	 join dim_date as dd on fm.date_id = dd.date_id
	 join dim_team as at on fm.away_team_id = at.team_id
	 join season_start as ss on  fm.league_id = ss.league_id and fm.season_id = ss.season_id
     )
     select league_name,
    season,
    team_name,
    year_num,
    month_num,
    month_name,
   season_week,
    count(*) as matches_played,
    sum(goals_for) as goals_scored,
    sum(goals_against) as goals_conceded,
    sum(goal_difference) as goal_difference from team_match_rows
     group by league_name, season, team_name, year_num, month_num, month_name, season_week;


#------------------------------------------------------------------------------
# view team form trend (W,D,L)
select * from fact_matches_clean;

create view vw_team_match_form as
with team_match_rows as (
select dl.league_name,ds.season,dd.full_date,
ht.team_name as team_name,
at.team_name as opponent_team_name,
fm.home_goals as goals_scored,
fm.away_goals as goals_conceded,
'Home' as venue,
case when fm.result = "H" then "W"
	when fm.result = "A" then "L"
    else "D"
    end as match_result,
    
case when fm.result = "H" then 3
	when fm.result = "A" then 0
    else 1
    end as points_earned
 from fact_matches_clean as fm
join dim_league as dl on fm.league_id = dl.league_id
join dim_season as ds on fm.season_id = ds.season_id
join dim_date as dd on fm.date_id = dd.date_id
join dim_team as ht on fm.home_team_id = ht.team_id
join dim_team as at on fm.away_team_id = at.team_id
union all
select dl.league_name,ds.season,dd.full_date,
at.team_name as team_name,
ht.team_name as opponent_team_name,
fm.away_goals as goals_scored,
fm.home_goals as goals_conceded,
'Away' as venue,
case when fm.result = "A" then "W"
	when fm.result = "H" then "L"
    else "D"
    end as match_result,
    
case when fm.result = "A" then 3
	when fm.result = "H" then 0
    else 1
    end as points_earned
 from fact_matches_clean as fm
join dim_league as dl on fm.league_id = dl.league_id
join dim_season as ds on fm.season_id = ds.season_id
join dim_date as dd on fm.date_id = dd.date_id
join dim_team as ht on fm.home_team_id = ht.team_id
join dim_team as at on fm.away_team_id = at.team_id
)
select league_name,
    season,
    full_date,
    team_name,
    opponent_team_name as opponent_team,
    venue,
    goals_scored,
    goals_conceded,
    goals_scored - goals_conceded AS goal_difference,
    match_result,
    points_earned,
    row_number() over (partition by league_name, season,team_name order by full_date) as match_number,
    lag(match_result) over (partition by league_name, season, team_name order by full_date) as previous_match_result,
    lag(points_earned) over (partition by league_name, season, team_name order by full_date) as previous_match_points
    from team_match_rows;

	select * from vw_team_match_form where team_name ="Man United";
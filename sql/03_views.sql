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
group by league_name, season, team_name)
select *,
dense_rank() over (partition by league_name, season 
order by points desc, goal_difference desc, goals_for desc) as league_position
 from team_summary;
 
 select * from vw_league_points_table;

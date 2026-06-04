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


    #---------------------------------------------------------------------------------------
-- vw_league_goal_summary

-- This is for league-level comparison.

-- answers:
-- Which league has most goals?
-- Which league has highest average goals per match?
-- Which league has more home wins / away wins / draws?

-- Expected columns:
-- league_name,season,total_matches,total_goals,avg_goals_per_match,home_goals,away_goals,home_wins,away_wins,draws
select * from dim_league;
select * from fact_matches_clean;


create view vw_league_goal_summary as
with season_start as
(
	select 
		fm.league_id, fm.season_id,
		min(dd.full_date) as season_start_date
	 from fact_matches_clean as fm
	join dim_date as dd on fm.date_id = dd.date_id
	group by fm.league_id, fm.season_id
)
	select dl.league_name, ds.season, 
		dd.full_date as match_date,
        dd.year_num,
        dd.month_num, dd.month_name,
        dd.day_num, dd.day_name,
        floor(datediff(dd.full_date, ss.season_start_date)/7)+1 as season_week,
		count(*) as total_matches,
		sum(fm.home_goals) as total_home_goals,
		sum(fm.away_goals) as total_away_goals,
		sum(fm.home_goals) + sum(fm.away_goals) as total_goals,
		count(case when fm.result = "H" then 1 end) as home_wins,
		count(case when fm.result = "A" then 1 end) as away_wins,
		count(case when fm.result = "D" then 1 end) as draws,
		round((sum(fm.home_goals) + sum(fm.away_goals))/count(*),2) as avg_goals_per_match
	 from fact_matches_clean as fm
	join dim_league as dl on fm.league_id = dl.league_id
	join dim_season as ds on fm.season_id = ds.season_id
    join season_start as ss on fm.league_id = ss.league_id and fm.season_id = ss.season_id
    join dim_date as dd on dd.date_id = fm.date_id
	join dim_team as ht on fm.home_team_id = ht.team_id
	join dim_team as at on fm.away_team_id = at.team_id
	group by dl.league_name, ds.season,season_week, dd.full_date,dd.year_num,
    dd.month_num,
    dd.month_name,dd.day_num, dd.day_name
    ;

select * from vw_league_goal_summary;

#vw_team_attacking_defensive_summary
-- Why this view 
-- answer:
-- Which teams are strongest in attack?,Which teams are strongest defensively?
-- Which teams are most efficient with shots?,Which teams have best goal difference?

-- Expected output columns
-- league_name,season,team_name,matches_played,goals_scored,goals_conceded,goal_difference
-- total_shots,shots_on_target,shot_accuracy_percentage,goal_conversion_percentage
-- Logic
-- For home team:
-- goals_scored = home_goals,goals_conceded = away_goals,total_shots = home_shots,shots_on_target = home_shots_target

-- For away team
-- goals_scored = away_goals,goals_conceded = home_goals,total_shots = away_shots,shots_on_target = away_shots_target

create view vw_team_attacking_defensive_summary_trend as
with season_start as
(
	select 
		fm.league_id, fm.season_id,
		min(dd.full_date) as season_start_date
	 from fact_matches_clean as fm
	join dim_date as dd on fm.date_id = dd.date_id
	group by fm.league_id, fm.season_id
),
team_match_rows as 
(
	select 
		dl.league_name,
		ds.season,
        dd.full_date as match_date,
        dd.year_num,
        dd.month_num, dd.month_name,
        dd.day_num, dd.day_name,
        floor(datediff(dd.full_date, ss.season_start_date)/7)+1 as season_week,
        ht.team_name ,
		fm.home_goals as goals_scored,
		fm.away_goals as goals_conceded,
		fm.home_goals-fm.away_goals as goal_difference,
		fm.home_shots as total_shots,
		fm.home_shots_target as shots_on_target
	  from fact_matches_clean as fm
	join dim_league as dl on fm.league_id = dl.league_id
	join dim_season as ds on fm.season_id = ds.season_id
	join dim_team as ht on fm.home_team_id = ht.team_id
    join dim_date as dd on fm.date_id = dd.date_id
    join season_start as ss on ss.league_id = fm.league_id and ss.season_id = fm.season_id
	union all
	select 
		dl.league_name,
		ds.season,
        dd.full_date as match_date,
        dd.year_num,
        dd.month_num, dd.month_name,
        dd.day_num, dd.day_name,
        floor(datediff(dd.full_date, ss.season_start_date)/7)+1 as season_week,
        at.team_name ,
		fm.away_goals as goals_scored,
		fm.home_goals as goals_conceded,
		fm.away_goals - fm.home_goals as goal_difference,
		fm.away_shots as total_shots,
		fm.away_shots_target as shots_on_target
	  from fact_matches_clean as fm
	join dim_league as dl on fm.league_id = dl.league_id
	join dim_season as ds on fm.season_id = ds.season_id
	join dim_team as at on fm.away_team_id = at.team_id
    join dim_date as dd on fm.date_id = dd.date_id
    join season_start as ss on ss.league_id = fm.league_id and ss.season_id = fm.season_id
)
	select 
		league_name, season, team_name, 
        match_date,
        year_num,
        month_num, month_name,
        day_num, day_name,
         season_week,
		sum(goals_scored) as goals_scored, 
		sum(goals_conceded) as goals_conceded,
		 sum(goal_difference) as goal_difference,
		sum(total_shots) as total_shots, 
		sum(shots_on_target) as shots_on_target,
		sum(shots_on_target)/nullif(sum(total_shots),0) *100 as shot_accuracy_percentage ,
		sum(goals_scored)/nullif(sum(shots_on_target),0) *100 goal_conversion_percentage
	from team_match_rows
	group by league_name, season, team_name, match_date,
        year_num,
        month_num, month_name,
        day_num, day_name,season_week;

select * from vw_team_attacking_defensive_summary_trend;

#--------------------------------------------------------------------

#--------Refree Summary---------------------------------------------
select * from fact_matches_clean;

create view vw_referee_card_summary as
select dl.league_name, ds.season, fm.referee,
count(*) as matches_officiated,
sum(fm.home_yellow_cards) as home_yellow_cards,
sum(fm.away_yellow_cards) as away_yellow_cards,
sum(fm.home_red_cards) as home_red_cards,
sum(fm.away_red_cards) as away_red_cards,
sum(fm.home_yellow_cards)+ sum(fm.away_yellow_cards) as yellow_cards,
sum(fm.home_red_cards) + sum(fm.away_red_cards)  as red_cards,
sum(fm.home_yellow_cards)+ sum(fm.away_yellow_cards) +sum(fm.home_red_cards) + sum(fm.away_red_cards) as total_cards,
round((sum(fm.home_yellow_cards)+ sum(fm.away_yellow_cards))/count(*),2) as avg_yellow_cards_per_match,
round((sum(fm.home_red_cards) + sum(fm.away_red_cards))/ count(*),2) as avg_red_cards_per_match,
round((sum(fm.home_yellow_cards)+ sum(fm.away_yellow_cards) +sum(fm.home_red_cards) + sum(fm.away_red_cards))/count(*),2) as avg_cards_per_match
 from fact_matches_clean as fm
join dim_league as dl on fm.league_id = dl.league_id
join dim_season as ds on fm.season_id = ds.season_id
group by fm.league_id, fm.season_id,fm.referee;

#------------------------------vw_referee_card_summary_week-----------------------------------------------------

create view vw_referee_card_summary_week as
with season_start as (
	select 
		fm.league_id,
		fm.season_id,
		min(dd.full_date) as season_start_date
	 from fact_matches_clean as fm
	join dim_date as dd on fm.date_id = dd.date_id
	group by fm.league_id , fm.season_id
    )
select dl.league_name, ds.season, fm.referee,
dd.full_date, dd.year_num, dd.month_num, dd.month_name, dd.day_num, dd.day_name,
floor(datediff(dd.full_date, ss.season_start_date)/7)+1 as season_week,
count(*) as matches_officiated,
sum(fm.home_yellow_cards) as home_yellow_cards,
sum(fm.away_yellow_cards) as away_yellow_cards,
sum(fm.home_red_cards) as home_red_cards,
sum(fm.away_red_cards) as away_red_cards,
sum(fm.home_yellow_cards)+ sum(fm.away_yellow_cards) as yellow_cards,
sum(fm.home_red_cards) + sum(fm.away_red_cards)  as red_cards,
sum(fm.home_yellow_cards)+ sum(fm.away_yellow_cards) +sum(fm.home_red_cards) + sum(fm.away_red_cards) as total_cards,
round((sum(fm.home_yellow_cards)+ sum(fm.away_yellow_cards))/count(*),2) as avg_yellow_cards_per_match,
round((sum(fm.home_red_cards) + sum(fm.away_red_cards))/ count(*),2) as avg_red_cards_per_match,
round((sum(fm.home_yellow_cards)+ sum(fm.away_yellow_cards) +sum(fm.home_red_cards) + sum(fm.away_red_cards))/count(*),2) as avg_cards_per_match
 from fact_matches_clean as fm
join dim_league as dl on fm.league_id = dl.league_id
join dim_season as ds on fm.season_id = ds.season_id
join season_start as ss on fm.season_id = ss.season_id and fm.league_id = ss.league_id
join dim_date as dd on fm.date_id = dd.date_id
group by fm.league_id, fm.season_id,fm.referee,dd.full_date, dd.year_num, dd.month_num, dd.month_name, dd.day_num, dd.day_name,
floor(datediff(dd.full_date, ss.season_start_date)/7)+1;

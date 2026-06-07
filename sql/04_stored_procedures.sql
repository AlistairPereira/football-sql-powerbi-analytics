use football_analytics;
#stored Procedures
-- Stored Procedure Task: Get Team Season Summary

drop procedure if exists sp_get_season_summary;

select * from vw_league_points_table;

delimiter //
create procedure sp_get_season_summary(in p_season varchar(10), in p_league_name varchar(100))
begin
select team_name, played, won, drawn, lost, goals_for as goals_scored,
goals_against as goals_conceded,
goal_difference, points,
league_position from vw_league_points_table
where league_name = p_league_name
and season = p_season
order by league_position;
end//
delimiter ;


call sp_get_season_summary("2023/24","Ligue 1");

#------------sp_get_team_performance_summary---------------------------
select * from vw_team_match_form;

drop procedure if exists sp_get_team_performance_summary;

delimiter //
create procedure sp_get_team_performance_summary(in team varchar(50), in p_season varchar(100),
in p_league_name varchar(100))
begin
select league_name, season,team_name,
sum(goals_scored) as goals_scored,
sum(goals_conceded) as goals_conceded,
sum(goal_difference) as goal_difference,
count(*) as matches_played,
count(case when match_result = "W" then 1 end) as wins,
count(case when match_result ="D" then 1 end) as drwas,
count(case when match_result ="L" then 1 end) as loss,
count(case when match_result = "W" then 1 end) /count(*) *100 as win_Percentage,
sum(points_earned)/count(*) as avg_poinst_per_match
 from vw_team_match_form
where league_name = p_league_name and season = p_season and team_name = team
group by league_name, season, team_name;
end//
delimiter ;

call sp_get_team_performance_summary("Arsenal", "2023/24", "English Premier League");

#--------------------------------sp_compare_two_teams--------------------------------
select * from vw_league_points_table;

drop procedure if exists sp_compare_two_teams;

delimiter //
create procedure sp_compare_two_teams(in p_league_name varchar(100), in p_season varchar(30),
in team_1 varchar(50), in team_2 varchar(50))
begin
select league_name, season, team_name, won, lost, drawn, points, league_position,
case
when points = (select max(points) from vw_league_points_table
where league_name = p_league_name and season = p_season and team_name in (team_1, team_2)) then "better perfroming team"
else " lower performing team"
end as team_status
 from vw_league_points_table
where league_name = p_league_name and season = p_season and team_name in (team_1, team_2);
end//
delimiter ;

call sp_compare_two_teams("English Premier League", "2023/24", "Arsenal", "Man United");

#--------------------------sp_get_top_teams_by_metric-----------------------------------------------
select * from vw_team_attacking_defensive_summary_trend;

delimiter //
create procedure sp_get_top_teams_by_metric(in p_league_name varchar(100), in p_season varchar(100), 
in p_metric varchar(50), in p_top_n int)
begin
select league_name,season, team_name, count(*) as matches_played,
    sum(goals_scored) as goals_scored,
    sum(goals_conceded) as goals_conceded,
    sum(goal_difference) as goal_difference,
    sum(total_shots) as total_shots,
    sum(shots_on_target) as shots_on_target,
    sum(shots_on_target)/nullif(sum(total_shots),0) *100 as shot_accuracy_percentage ,
	sum(goals_scored)/nullif(sum(shots_on_target),0) *100 goal_conversion_percentage,
    
    case p_metric
    when 'goals_scored' then sum(goals_scored)
    when 'goal_difference' then sum(goal_difference)
    when 'shots_on_target' then SUM(shots_on_target)
    when 'shot accuracy' then sum(shots_on_target)/nullif(sum(total_shots),0) *100
    when 'goal conversion' then sum(goals_scored)/nullif(sum(shots_on_target),0) *100
    end as selected_metric_value
    
    from vw_team_attacking_defensive_summary_trend
where league_name = p_league_name and season =p_season
group by league_name, season, team_name
order by selected_metric_value desc
limit p_top_n;
end//
delimiter ;

call sp_get_top_teams_by_metric('Bundesliga','2023/24','shots_on_target',10);
call sp_get_top_teams_by_metric('Bundesliga','2023/24','goals conversion',10);


#----------Get top N biggest wins by league, season, and match result type-------------

delimiter //
create procedure sp_get_top_biggest_wins( in p_league_name varchar(100), in p_season varchar(100), in p_top_n int)
begin
select league_name, season, full_date, home_team, away_team,
home_goals, away_goals,winner, loser, goal_margin, match_result_type
 from vw_biggest_win
where league_name = p_league_name and season = p_season and match_result_type != 'draw'
order by goal_margin desc, home_goals+away_goals desc
limit p_top_n;
end//
delimiter ;
drop procedure if exists sp_get_top_biggest_wins;

call sp_get_top_biggest_wins("Ligue 1", "2023/24", 5);
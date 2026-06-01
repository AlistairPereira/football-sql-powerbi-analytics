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
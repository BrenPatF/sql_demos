PROMPT Create EPL tables...
PROMPT Table epl_positions
DROP TABLE epl_positions
/
CREATE TABLE epl_positions (
        id              VARCHAR2(2) PRIMARY KEY,
        min_players     INTEGER,
        max_players     INTEGER
)
/
PROMPT External table player_matches_ext pointing to stats.txt
DROP TABLE player_matches_ext
/
CREATE TABLE player_matches_ext (
        yellow_cards        NUMBER,
        net_transfers       NUMBER,
        last_name           VARCHAR2(30),
        goals_conceded      NUMBER,
        saves               NUMBER,
        result              VARCHAR2(30),
        team_name           VARCHAR2(30),
        fl_index            NUMBER,
        first_name          VARCHAR2(30),
        own_goals           NUMBER,
        minutes_played      NUMBER,
        EA_Spots_PPI        NUMBER,
        week                NUMBER,
        bonus               NUMBER,
        clean_sheets        NUMBER,
        assists             NUMBER,
        match_date          VARCHAR2(30),
        penalties_saved     NUMBER,
        penalties_missed    NUMBER,
        value               NUMBER,
        points              NUMBER,
        position            VARCHAR2(30),
        red_cards           NUMBER,
        goals_scored        NUMBER
)
ORGANIZATION EXTERNAL (
	TYPE			oracle_loader
	DEFAULT DIRECTORY	input_dir
	ACCESS PARAMETERS
	(
        RECORDS DELIMITED BY NEWLINE SKIP 1
		FIELDS TERMINATED BY ','
		MISSING FIELD VALUES ARE NULL
	)
	LOCATION ('stats.txt')
)
/
PROMPT Table epl_players
DROP TABLE epl_players
/
CREATE TABLE epl_players (
        id                  INTEGER PRIMARY KEY,
        first_name          VARCHAR2(30),
        last_name           VARCHAR2(30),
        team_name           VARCHAR2(30),
        yellow_cards        NUMBER,
        net_transfers       NUMBER,
        goals_conceded      NUMBER,
        saves               NUMBER,
        fl_index            NUMBER,
        own_goals           NUMBER,
        minutes_played      NUMBER,
        EA_Spots_PPI        NUMBER,
        bonus               NUMBER,
        clean_sheets        NUMBER,
        assists             NUMBER,
        penalties_saved     NUMBER,
        penalties_missed    NUMBER,
        value               NUMBER,
        points              NUMBER,
        position            VARCHAR2(2),
        red_cards           NUMBER,
        goals_scored        NUMBER,
        appearances         INTEGER
)
/
PROMPT Insert EPL data...
PROMPT Insert EPL positions
DECLARE

  i     PLS_INTEGER := 0;
  PROCEDURE Ins_Position (
                        p_id	        VARCHAR2,
                        p_min_players   PLS_INTEGER,
                        p_max_players   PLS_INTEGER) IS
  BEGIN

    INSERT INTO epl_positions VALUES (p_id, p_min_players, p_max_players);

  END Ins_Position;

BEGIN

  DELETE epl_positions;
  Ins_Position ('GK', 1, 1);
  Ins_Position ('DF', 3, 5);
  Ins_Position ('MF', 2, 5);
  Ins_Position ('FW', 1, 3);
  Ins_Position ('AL', 11, 11);
END;
/
PROMPT Insert EPL PLAYERS
INSERT INTO epl_players (
        id,
        first_name,
        last_name,
        team_name,
        position,
        yellow_cards,
        net_transfers,
        goals_conceded,
        saves,
        fl_index,
        own_goals,
        minutes_played,
        EA_Spots_PPI,
        bonus,
        clean_sheets,
        assists,
        penalties_saved,
        penalties_missed,
        value,
        points,
        red_cards,
        goals_scored,
        appearances
)
SELECT  Row_Number() OVER (ORDER BY team_name, last_name, first_name),
        first_name,
        last_name,
        team_name,
        CASE position WHEN 'Goalkeeper' THEN 'GK' WHEN 'Defender' THEN 'DF' WHEN 'Midfielder' THEN 'MF' WHEN 'Forward' THEN 'FW' END,
        Sum (yellow_cards),
        Sum (net_transfers),
        Sum (goals_conceded),
        Sum (saves),
        Sum (fl_index),
        Sum (own_goals),
        Sum (minutes_played),
        Sum (EA_Spots_PPI),
        Sum (bonus),
        Sum (clean_sheets),
        Sum (assists),
        Sum (penalties_saved),
        Sum (penalties_missed),
        Max (value) KEEP (DENSE_RANK LAST ORDER BY week),
        Sum (points),
        Sum (red_cards),
        Sum (goals_scored),
        count(*)
  FROM player_matches_ext
 GROUP BY 
        first_name,
        last_name,
        team_name,
        CASE position WHEN 'Goalkeeper' THEN 'GK' WHEN 'Defender' THEN 'DF' WHEN 'Midfielder' THEN 'MF' WHEN 'Forward' THEN 'FW' END
/
SELECT Count(*) FROM epl_players WHERE points > 0
/
PROMPT Delete Gervino as Forward
DELETE  epl_players WHERE last_name = 'Gervinho' AND position = 'FW'
/
CREATE UNIQUE INDEX epl_players_u1 ON epl_players (first_name, last_name, team_name)
/
SELECT Count(*) FROM epl_players WHERE points > 0
/
